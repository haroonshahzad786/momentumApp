import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/offline.dart';
import '../theme/momentum_tokens.dart';
import '../widgets/momentum/offline_banner.dart';
import '../widgets/animation_stage.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/compact_chat_panel.dart';
import '../widgets/momentum/starfield.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final ChatService _chat = ChatService();
  final List<ChatMessage> _messages = [];

  bool _waitingForReply = false;
  bool _loadingInitial = true;
  bool _offline = false;
  // Ordered image URLs from the most recent assistant turn — played in sequence
  // by AnimationStage (one response can carry several animation frames).
  List<String> _animationUrls = const [];

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
    if (_userId.isEmpty) {
      setState(() => _loadingInitial = false);
      return;
    }
    try {
      final existing = await _chat.getLatestMessages(_userId);
      if (existing.data.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _messages.addAll(existing.data);
          _animationUrls = _latestImageUrls(existing.data);
          _offline = existing.fromCache;
        });
      } else if (existing.fromCache) {
        // Offline with no saved transcript — show the offline state, don't try
        // to launch a new conversation (that needs the network too).
        if (mounted) setState(() => _offline = true);
      } else {
        final firstMessages = await _chat.launchConversation(_userId);
        if (firstMessages.isNotEmpty && mounted) {
          setState(() {
            _messages.addAll(firstMessages);
            _animationUrls = _latestImageUrls(firstMessages);
          });
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
        // Play every image from this reply, in order (not just the last one).
        final imgs = _collectImageUrls(replies);
        if (imgs.isNotEmpty) _animationUrls = imgs;
      });
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

  /// All image URLs in the most recent message that has any — the multi-frame
  /// sequence for one assistant turn (the parser attaches consecutive images to
  /// a single message).
  List<String> _latestImageUrls(List<ChatMessage> messages) {
    for (final m in messages.reversed) {
      if (m.imageUrls.isNotEmpty) return m.imageUrls;
    }
    return const [];
  }

  /// Every image across a freshly-arrived reply, in arrival order — handles the
  /// case where a turn spreads images over several messages.
  List<String> _collectImageUrls(List<ChatMessage> messages) {
    final urls = <String>[];
    for (final m in messages) {
      urls.addAll(m.imageUrls);
    }
    return urls;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MM.pageBg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Just the stars (Claude design) — no background photo.
          const Positioned.fill(
            child: StarfieldBackground(accent: MM.violet),
          ),
          SafeArea(
            child: Column(
              children: [
                const _TopBar(),
                if (_offline)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                    child: OfflineBanner(onRefresh: _bootstrap),
                  ),
                // Transcript ≈ 60% of the area between header and input bar.
                Expanded(
                  flex: 6,
                  child: _loadingInitial
                      ? const Center(
                          child:
                              CircularProgressIndicator(color: MM.violet),
                        )
                      : CompactChatPanel(messages: _messages),
                ),
                // Lower visual area (rocket / assistant image) ≈ 40%.
                Expanded(
                  flex: 4,
                  child: AnimationStage(
                    imageUrls: _animationUrls,
                    isThinking: _waitingForReply,
                  ),
                ),
                ChatInputBar(
                  enabled: !_waitingForReply && !_loadingInitial,
                  onSend: _onSend,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      child: Row(
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
