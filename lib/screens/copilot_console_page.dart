import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/offline.dart';
import '../theme/momentum_tokens.dart';
import '../widgets/momentum/chat_markdown.dart';
import '../widgets/momentum/offline_banner.dart';
import '../widgets/momentum/starfield.dart';

/// Co-Pilot, console layout (v2).
///
/// Differs from [AiChatPage] (the original, still on disk) in two ways the
/// client asked for:
///  1. The transcript lives *inside* the hanging cockpit monitor artwork
///     (`assets/images/mantra.png`), with the type bar directly beneath it.
///  2. Images no longer sit above the text. When a reply carries images the
///     console is hidden, the frames play full-bleed as an animation, and the
///     screen returns to the console when the sequence ends.
///
/// The backend contract is unchanged — same [ChatService]. As of the
/// NOVA_CLAUDE_MIGRATION plan, [ChatService] itself now routes through
/// [AiBackendConfig] to Claude-backed endpoints by default (the original
/// Voiceflow-backed trio stays deployed as the rollback path).
class CopilotConsolePage extends StatefulWidget {
  const CopilotConsolePage({
    super.key,
    this.previewMessages,
    this.previewAnimation,
  });

  /// TEMP preview seed — remove.
  final List<ChatMessage>? previewMessages;

  /// TEMP preview seed — remove.
  final List<String>? previewAnimation;

  @override
  State<CopilotConsolePage> createState() => _CopilotConsolePageState();
}

class _CopilotConsolePageState extends State<CopilotConsolePage> {
  final ChatService _chat = ChatService();
  final List<ChatMessage> _messages = [];

  bool _waitingForReply = false;
  bool _loadingInitial = true;
  bool _offline = false;

  /// Frames for the sequence currently playing. Non-empty only while
  /// [_animating] is true — the console is hidden for that whole time.
  List<String> _animationUrls = const [];
  bool _animating = false;

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _chat.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (widget.previewMessages != null) {
      setState(() {
        _messages.addAll(widget.previewMessages!);
        _loadingInitial = false;
      });
      final anim = widget.previewAnimation;
      if (anim != null) {
        Future.delayed(const Duration(seconds: 4), () => _playIfAny(anim));
      }
      return;
    }
    if (_userId.isEmpty) {
      setState(() => _loadingInitial = false);
      return;
    }
    try {
      final existing = await _chat.getLatestMessages(_userId);
      if (existing.data.isNotEmpty) {
        if (!mounted) return;
        // Re-opening the page replays nothing — history is text only. The
        // animation is a reaction to a *live* turn, not to scrollback.
        setState(() {
          _messages.addAll(existing.data);
          _offline = existing.fromCache;
        });
      } else if (existing.fromCache) {
        // Offline with no saved transcript — show the offline state rather
        // than trying to launch a conversation, which also needs the network.
        if (mounted) setState(() => _offline = true);
      } else {
        final firstMessages = await _chat.launchConversation(_userId);
        if (firstMessages.isNotEmpty && mounted) {
          setState(() => _messages.addAll(firstMessages));
          _playIfAny(_collectImageUrls(firstMessages));
        }
      }
    } catch (e) {
      if (!mounted) return;
      // Never surface the raw exception to players.
      if (isNetworkError(e)) {
        setState(() => _offline = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e, action: 'load the chat'))),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingInitial = false);
    }
  }

  Future<void> _onSend(String text) async {
    if (_userId.isEmpty || _waitingForReply) return;
    final userMsg = ChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      role: 'user',
      text: text,
      imageUrls: const [],
      createdAt: DateTime.now(),
    );
    setState(() {
      _messages.add(userMsg);
      _waitingForReply = true;
    });
    try {
      final replies = await _chat.sendMessage(_userId, text);
      if (!mounted) return;
      setState(() {
        _messages.addAll(replies);
        _offline = false; // a successful send means we're back online
      });
      // The reply text is already in the transcript; it's waiting for the
      // player when the animation hands the screen back.
      _playIfAny(_collectImageUrls(replies));
    } catch (e) {
      if (!mounted) return;
      final offline = isNetworkError(e);
      setState(() => _offline = offline);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(offline
              ? "You're offline — your message wasn't sent. Reconnect and try again."
              : friendlyError(e, action: 'send your message')),
        ),
      );
    } finally {
      if (mounted) setState(() => _waitingForReply = false);
    }
  }

  /// Every image across a freshly-arrived reply, in arrival order — one turn
  /// can spread its frames over several message parts.
  List<String> _collectImageUrls(List<ChatMessage> messages) {
    final urls = <String>[];
    for (final m in messages) {
      urls.addAll(m.imageUrls);
    }
    return urls;
  }

  /// Hands the screen over to the animation. No images → the console stays put.
  void _playIfAny(List<String> urls) {
    if (urls.isEmpty || !mounted) return;
    FocusScope.of(context).unfocus(); // drop the keyboard before going full-bleed
    setState(() {
      _animationUrls = urls;
      _animating = true;
    });
  }

  void _endAnimation() {
    if (!mounted || !_animating) return;
    setState(() {
      _animating = false;
      _animationUrls = const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MM.pageBg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: StarfieldBackground(accent: MM.violet),
          ),
          // Console ⇄ animation are mutually exclusive: the text screen is
          // hidden for the whole sequence, then fades back in.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            child: _animating
                ? _AnimationSequence(
                    key: ValueKey(_animationUrls.join('|')),
                    imageUrls: _animationUrls,
                    messages: _messages,
                    onDone: _endAnimation,
                    // Playback pacing — how long each frame holds once it has
                    // actually arrived. Slow fetches don't eat into this.
                    frameDuration: const Duration(milliseconds: 5000),
                    transitionDuration: const Duration(milliseconds: 600),
                    // How long a stalled fetch is allowed to hold the screen
                    // before the walk moves on to the placeholder.
                    loadTimeout: const Duration(seconds: 12),
                  )
                : _buildConsole(),
          ),
        ],
      ),
    );
  }

  Widget _buildConsole() {
    return SafeArea(
      key: const ValueKey('console'),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              if (_offline)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                  child: OfflineBanner(onRefresh: _bootstrap),
                ),
              // The monitor hangs from the top of the screen — its cable has to
              // reach the top edge, so the title bar floats over the empty space
              // beside it rather than pushing the whole rig down.
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _MantraConsole(
                          messages: _messages,
                          loading: _loadingInitial,
                          thinking: _waitingForReply,
                        ),
                      ),
                    ),
                    const Positioned(top: 0, left: 0, child: _TopBar()),
                  ],
                ),
              ),
              _ConsoleInputBar(
                enabled: !_waitingForReply && !_loadingInitial,
                onSend: _onSend,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── The monitor ────────────────────────────────────────────────────────────

/// Where the black display sits inside `mantra.png`, as fractions of the
/// artwork. Measured off the source PNG (1174×2390): the dark glass spans
/// x 0.089→0.908, y 0.143→0.967.
///
/// The art draws two curved teal rules across the top of the glass — those
/// bracket the **status band**, which carries the status line and nothing else.
/// The rules bow, so the band is measured at its tightest: the upper rule sits
/// as low as y 0.187 at the edges, the lower one as high as y 0.279 at centre.
/// The transcript starts below the lower rule.
const double _screenLeft = 0.115;
const double _screenRight = 0.885;
const double _bandTop = 0.190;
const double _bandBottom = 0.276;
const double _screenTop = 0.295;
// Kept well clear of the glass's bottom edge (0.967) — the corner radius eats
// into the usable width long before the straight edge does, so the last bubble
// was clipping the bezel.
const double _screenBottom = 0.910;

/// mantra.png is 1174×2390.
const double _mantraAspect = 1174 / 2390;

/// The cockpit monitor with the transcript rendered on its glass.
class _MantraConsole extends StatelessWidget {
  const _MantraConsole({
    required this.messages,
    required this.loading,
    required this.thinking,
  });

  final List<ChatMessage> messages;
  final bool loading;
  final bool thinking;

  @override
  Widget build(BuildContext context) {
    return Align(
      // Top, not centre — any spare height belongs below the monitor, so the
      // cable stays pinned to the top of the screen.
      alignment: Alignment.topCenter,
      child: AspectRatio(
        aspectRatio: _mantraAspect,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final h = c.maxHeight;
            return Stack(
              children: [
                // BoxFit.fill (not contain) so the fractions above land on the
                // glass exactly — AspectRatio already gave us the right box.
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/mantra.png',
                    fit: BoxFit.fill,
                  ),
                ),
                // Status band — the strip between the two teal rules holds the
                // status line only; nothing else may be drawn there.
                Positioned(
                  left: w * _screenLeft,
                  top: h * _bandTop,
                  width: w * (_screenRight - _screenLeft),
                  height: h * (_bandBottom - _bandTop),
                  child: Center(child: _StatusStrip(online: !loading)),
                ),
                Positioned(
                  left: w * _screenLeft,
                  top: h * _screenTop,
                  width: w * (_screenRight - _screenLeft),
                  height: h * (_screenBottom - _screenTop),
                  child: _ScreenContent(
                    messages: messages,
                    loading: loading,
                    thinking: thinking,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Everything drawn on the glass: status strip, transcript, thinking line.
class _ScreenContent extends StatefulWidget {
  const _ScreenContent({
    required this.messages,
    required this.loading,
    required this.thinking,
  });

  final List<ChatMessage> messages;
  final bool loading;
  final bool thinking;

  @override
  State<_ScreenContent> createState() => _ScreenContentState();
}

class _ScreenContentState extends State<_ScreenContent> {
  final ScrollController _scroll = ScrollController();
  int _lastSeenCount = 0;

  static const Duration _scrollDelay = Duration(milliseconds: 250);
  static const Duration _scrollAnim = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _lastSeenCount = widget.messages.length;
    // Open on the LAST message, not the first. This state is rebuilt from
    // scratch every time the animation sequence hands the screen back (the
    // page's AnimatedSwitcher swaps the whole console out), so without this the
    // transcript came back sitting at the top of the history and the player had
    // to scroll down to find where they were.
    _pinToBottom();
  }

  @override
  void didUpdateWidget(covariant _ScreenContent old) {
    super.didUpdateWidget(old);
    // A new message, or the transcript arriving after the initial load.
    if (widget.messages.length > _lastSeenCount) {
      final firstFill = _lastSeenCount == 0;
      _lastSeenCount = widget.messages.length;
      if (firstFill) {
        _pinToBottom();
      } else {
        Future.delayed(_scrollDelay, _scrollToBottom);
      }
    }
  }

  /// Jump (no animation) to the newest message once the list has laid out.
  /// Used when the transcript first appears — animating there would look like
  /// the screen scrolling itself, and the player never saw the top anyway.
  void _pinToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
      // Text can reflow a frame later (wrapping, late layout), which leaves the
      // bottom further down than it was a moment ago — settle once more.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) return;
        final max = _scroll.position.maxScrollExtent;
        if (_scroll.offset < max) _scroll.jumpTo(max);
      });
    });
  }

  void _scrollToBottom() {
    if (!mounted || !_scroll.hasClients) return;
    _scroll
        .animateTo(
      _scroll.position.maxScrollExtent,
      duration: _scrollAnim,
      curve: Curves.easeOut,
    )
        .then((_) {
      // The reply can still be growing while we animate; land on the real end.
      if (!mounted || !_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      if (_scroll.offset < max) _scroll.jumpTo(max);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible =
        widget.messages.where((m) => m.text.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: widget.loading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: MM.teal,
                    ),
                  ),
                )
              : visible.isEmpty
                  ? Center(
                      child: Text(
                        'Say something to Nova.',
                        textAlign: TextAlign.center,
                        style: MM.body(
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: _scroll,
                      padding: const EdgeInsets.only(bottom: 4),
                      itemCount: visible.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) =>
                          _ScreenBubble(message: visible[i]),
                    ),
        ),
        if (widget.thinking) const _ThinkingLine(),
      ],
    );
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: online ? MM.teal : Colors.white24,
            boxShadow: online
                ? [BoxShadow(color: MM.teal.withValues(alpha: 0.8), blurRadius: 6)]
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          online ? 'NOVA · ONLINE' : 'NOVA · LINKING',
          style: MM.displayX(
            size: 9,
            color: MM.teal.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

/// Transcript line. Tuned for a black CRT rather than the light bubbles the
/// original panel used — white-on-glass reads, a white pill glares.
class _ScreenBubble extends StatelessWidget {
  const _ScreenBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final accent = isUser ? MM.violet : MM.teal;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: isUser ? 0.20 : 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                isUser ? 'YOU' : 'NOVA',
                style: MM.displayX(size: 8, color: accent),
              ),
              const SizedBox(height: 3),
              // Nova replies in light markdown — render its `**bold**` /
              // `*italic*` as emphasis instead of printing the asterisks.
              ChatMarkdownText(
                message.text,
                textAlign: isUser ? TextAlign.right : TextAlign.left,
                style: MM.body(
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.92),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThinkingLine extends StatelessWidget {
  const _ThinkingLine();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.6,
              color: MM.teal.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Nova is thinking…',
            style: MM.body(
              size: 11,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Input ──────────────────────────────────────────────────────────────────

/// Dark console pill under the monitor. Deliberately local to this page so the
/// original Co-Pilot keeps its own (light) `ChatInputBar` untouched.
class _ConsoleInputBar extends StatefulWidget {
  const _ConsoleInputBar({required this.onSend, this.enabled = true});

  final ValueChanged<String> onSend;
  final bool enabled;

  @override
  State<_ConsoleInputBar> createState() => _ConsoleInputBarState();
}

class _ConsoleInputBarState extends State<_ConsoleInputBar> {
  final _ctrl = TextEditingController();

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    widget.onSend(text);
    _ctrl.clear();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.enabled;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        14,
        12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 4),
        decoration: BoxDecoration(
          color: MM.navy2.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: MM.teal.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: MM.teal.withValues(alpha: 0.12),
              blurRadius: 14,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                enabled: on,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
                style: MM.body(size: 14, color: Colors.white),
                cursorColor: MM.teal,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Message Nova…',
                  hintStyle: MM.body(
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.40),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.send_rounded,
                color: on ? MM.teal : Colors.white24,
              ),
              onPressed: on ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Animation take-over ────────────────────────────────────────────────────

/// Full-bleed playback of one turn's frames. When the last frame has had its
/// turn [onDone] fires and the page swaps back to the console.
///
/// Pacing is **gated on the image actually arriving**: a frame's dwell clock
/// only starts once its bytes are in the cache, so on a slow connection the
/// sequence waits (behind the transmission loader) instead of silently burning
/// its frames on a blank screen. [loadTimeout] caps that wait so a stalled
/// download can't hang the sequence forever.
///
/// Two controls, doing different things: **CANCEL** ends playback and hands the
/// screen back to the console; **SHOW CHAT** slides the transcript up over the
/// animation so the reply can be read while the frames keep playing behind it.
class _AnimationSequence extends StatefulWidget {
  const _AnimationSequence({
    super.key,
    required this.imageUrls,
    required this.messages,
    required this.onDone,
    this.frameDuration = const Duration(milliseconds: 5000),
    this.transitionDuration = const Duration(milliseconds: 600),
    this.loadTimeout = const Duration(seconds: 12),
  });

  final List<String> imageUrls;

  /// Transcript shown by the SHOW CHAT control, over the running animation.
  final List<ChatMessage> messages;
  final VoidCallback onDone;
  final Duration frameDuration;
  final Duration transitionDuration;
  final Duration loadTimeout;

  @override
  State<_AnimationSequence> createState() => _AnimationSequenceState();
}

class _AnimationSequenceState extends State<_AnimationSequence> {
  int _index = 0;
  bool _finished = false;
  bool _waiting = true; // fetching the current frame
  bool _chatOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void didUpdateWidget(covariant _AnimationSequence old) {
    super.didUpdateWidget(old);
    if (!listEquals(old.imageUrls, widget.imageUrls)) {
      _index = 0;
      _finished = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _run());
    }
  }

  /// Walks the frames: fetch → show → dwell → next. Every await re-checks
  /// [_finished] so CANCEL takes effect immediately rather than at the end of
  /// the current dwell.
  Future<void> _run() async {
    for (var i = 0; i < widget.imageUrls.length; i++) {
      if (!mounted || _finished) return;
      setState(() {
        _index = i;
        _waiting = true;
      });

      await _load(widget.imageUrls[i]);
      if (!mounted || _finished) return;
      setState(() => _waiting = false);

      // Warm the next frame during this one's dwell so the cross-fade is clean.
      if (i + 1 < widget.imageUrls.length) _load(widget.imageUrls[i + 1]);

      await Future<void>.delayed(widget.frameDuration);
      if (!mounted || _finished) return;
    }
    _finish();
  }

  /// Resolves when the frame is cached, when it fails, or when [loadTimeout]
  /// runs out — never rejects, so one bad URL can't break the walk.
  Future<void> _load(String url) async {
    if (!mounted) return;
    try {
      await precacheImage(NetworkImage(url), context)
          .timeout(widget.loadTimeout);
    } catch (_) {
      // Broken or stalled — fall through to the rocket placeholder.
    }
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.imageUrls.isNotEmpty && _index < widget.imageUrls.length
        ? widget.imageUrls[_index]
        : null;

    return Stack(
      key: const ValueKey('animation'),
      fit: StackFit.expand,
      children: [
        Center(
          child: AnimatedSwitcher(
            duration: widget.transitionDuration,
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: (url == null || _waiting)
                ? const _TransmissionLoader(key: ValueKey('loader'))
                : Padding(
                    key: ValueKey(url),
                    padding: const EdgeInsets.all(16),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      // A dead URL shouldn't strand the player on a blank
                      // screen — show the fallback and let the walk carry on.
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/rocket.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
          ),
        ),
        if (widget.imageUrls.length > 1 && !_chatOpen)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: _FrameDots(
              count: widget.imageUrls.length,
              active: _index,
            ),
          ),
        // Transcript peek — the frames keep playing behind it.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _chatOpen
              ? _ChatPeek(
                  messages: widget.messages,
                  onClose: () => setState(() => _chatOpen = false),
                )
              : const SizedBox.shrink(),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _OverlayButton(
                    label: _chatOpen ? 'HIDE CHAT' : 'SHOW CHAT',
                    icon: _chatOpen
                        ? Icons.keyboard_arrow_down
                        : Icons.chat_bubble_outline,
                    onTap: () => setState(() => _chatOpen = !_chatOpen),
                  ),
                  const SizedBox(width: 8),
                  _OverlayButton(
                    label: 'CANCEL',
                    icon: Icons.close,
                    accent: MM.red,
                    onTap: _finish,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shown while a frame's bytes are still in flight. Deliberately more than a
/// spinner — on a slow link this is the whole screen for several seconds.
class _TransmissionLoader extends StatefulWidget {
  const _TransmissionLoader({super.key});

  @override
  State<_TransmissionLoader> createState() => _TransmissionLoaderState();
}

class _TransmissionLoaderState extends State<_TransmissionLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final t = _ctrl.value;
              return SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Two rings sweeping at different rates — reads as a dish
                    // locking on rather than a generic progress spinner.
                    Transform.rotate(
                      angle: t * 2 * 3.14159,
                      child: CustomPaint(
                        size: const Size(96, 96),
                        painter: _ArcPainter(
                          color: MM.violet.withValues(alpha: 0.9),
                          sweep: 1.4,
                          stroke: 3,
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: -t * 2 * 3.14159 * 0.6,
                      child: CustomPaint(
                        size: const Size(70, 70),
                        painter: _ArcPainter(
                          color: MM.teal.withValues(alpha: 0.8),
                          sweep: 2.2,
                          stroke: 2,
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: 0.55 + 0.45 * (1 - (t - 0.5).abs() * 2),
                      child: Image.asset(
                        'assets/images/rocket.png',
                        width: 30,
                        height: 30,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          Text(
            'RECEIVING TRANSMISSION',
            style: MM.displayX(
              size: 10,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hold tight — pulling the visual down from orbit.',
            style: MM.body(
              size: 12,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({
    required this.color,
    required this.sweep,
    required this.stroke,
  });

  final Color color;
  final double sweep; // radians
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Offset.zero & size,
      -1.57,
      sweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.color != color || old.sweep != sweep || old.stroke != stroke;
}

/// The transcript, pulled up over a running animation by SHOW CHAT.
class _ChatPeek extends StatelessWidget {
  const _ChatPeek({required this.messages, required this.onClose});

  final List<ChatMessage> messages;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final visible = messages.where((m) => m.text.trim().isNotEmpty).toList();
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 0.6,
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: MM.navy2.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: MM.teal.withValues(alpha: 0.30)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'TRANSCRIPT',
                      style: MM.displayX(
                        size: 9,
                        color: MM.teal.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onClose,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: visible.isEmpty
                    ? const SizedBox.shrink()
                    : ListView.separated(
                        reverse: true, // newest first — that's what they opened it for
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _ScreenBubble(
                          message: visible[visible.length - 1 - i],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.accent,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final c = accent ?? MM.teal;
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: c),
              const SizedBox(width: 6),
              Text(label, style: MM.displayX(size: 9, color: c)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrameDots extends StatelessWidget {
  const _FrameDots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final on = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: on ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: on ? 0.9 : 0.35),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ─── Chrome ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Dropped clear of the top edge — it floats over the artwork, so it needs
      // its own breathing room rather than sitting flush against the frame.
      padding: const EdgeInsets.fromLTRB(4, 16, 16, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CO-PILOT', style: MM.displayX(size: 11, color: MM.violet)),
              const SizedBox(height: 2),
              Text('Nova', style: MM.display(size: 20, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}
