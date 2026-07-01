import 'package:flutter/material.dart';

import '../../models/chat_message.dart';
import '../../services/chat_service.dart';
import '../../services/onboarding_service.dart';
import '../../theme/momentum_tokens.dart';
import '../../widgets/momentum/glass_panel.dart';
import '../../widgets/momentum/hhs_pyramid.dart';
import '../../widgets/momentum/mm_buttons.dart';
import '../../widgets/momentum/starfield.dart';

/// HHS Stage 1, driven by the live Voiceflow onboarding agent ("Nova").
///
/// Nova walks the player through the 5-step Habits Hierarchy in natural
/// language; after every turn we sync the agent's captured state
/// ([OnboardingService]) to advance the pyramid, fire per-section reward
/// overlays, and — once the Golden Habit is forged — show a confirm card and
/// complete the stage. All awards + persistence happen server-side and are
/// idempotent, so re-syncing is always safe.
class HhsChatView extends StatefulWidget {
  const HhsChatView({
    super.key,
    required this.userId,
    required this.onProgress,
    required this.onComplete,
    required this.onBack,
  });

  final String userId;

  /// Called with the number of completed sections (0–5) whenever it advances,
  /// so the parent can persist `stage1Progress`.
  final ValueChanged<int> onProgress;

  /// Called once the Golden Habit is forged and the player locks it in.
  final VoidCallback onComplete;

  final VoidCallback onBack;

  @override
  State<HhsChatView> createState() => _HhsChatViewState();
}

// Per-section reward shown when the agent awards that section's MP. The MP
// amounts mirror what the Voiceflow agent grants (+10/+15/+20/+25/+40); the
// overlay is purely celebratory — the points are already banked server-side.
class _SectionReward {
  const _SectionReward(this.label, this.mp, this.emoji, this.color);
  final String label;
  final int mp;
  final String emoji;
  final Color color;
}

const _sectionRewards = <_SectionReward>[
  _SectionReward('Truth Seeker', 10, '🔍', Color(0xFFEA0029)),
  _SectionReward('Core Confirmed', 15, '🧠', MM.blue),
  _SectionReward('Principle Decoder', 20, '📘', MM.violet),
  _SectionReward('Keystone Forger', 25, '🔑', MM.yellow),
  _SectionReward('Golden Habit Architect', 40, '✨', MM.teal),
];

class _HhsChatViewState extends State<HhsChatView> {
  final _chat = ChatService();
  final _onboarding = OnboardingService();
  final _input = TextEditingController();
  final _scroll = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _booting = true;
  bool _sending = false;
  String? _error;

  OnboardingSync _sync = OnboardingSync.empty;
  final List<_SectionReward> _rewardQueue = [];
  int _prevCompleted = 0;
  bool _firstSync = true;
  bool _showForge = false;
  bool _forgeAttempted = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() {
    _chat.dispose();
    _onboarding.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    try {
      // Load any existing transcript; seed the agent if this is a fresh start.
      final existing = await _chat.getLatestMessages(widget.userId);
      var msgs = existing.data;
      if (msgs.isEmpty) {
        final seeded = await _chat.launchConversation(widget.userId);
        msgs = seeded;
      }
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(msgs);
        _booting = false;
      });
      _scrollToEnd();
      await _syncOnboarding();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _booting = false;
      });
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    _input.clear();
    setState(() {
      _sending = true;
      _messages.add(ChatMessage(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        role: 'user',
        text: text,
        imageUrls: const [],
        createdAt: DateTime.now(),
      ));
    });
    _scrollToEnd();
    try {
      final reply = await _chat.sendMessage(widget.userId, text);
      if (!mounted) return;
      setState(() => _messages.addAll(reply));
      _scrollToEnd();
      await _syncOnboarding();
    } catch (_) {
      if (!mounted) return;
      // Non-fatal: leave the user's message; they can retry.
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Pulls the agent's progress and reacts to advancement / forge. When the
  /// completed-section count climbs, we celebrate each newly-finished section
  /// (the MP was already awarded by the agent). The first sync just seeds the
  /// baseline so resuming a conversation doesn't replay old overlays.
  Future<void> _syncOnboarding() async {
    var result = await _onboarding.sync(widget.userId);
    if (!mounted || !result.available) return;

    // The Voiceflow agent narrates the forged Golden Habit but doesn't always
    // persist it (and sometimes skips the +25 award, capping the MP-derived
    // count at 4). If it reached the forge stage with no habit doc yet, ask the
    // backend to reconstruct one from the transcript, then re-read so the
    // confirm card shows the real fields. Best-effort, attempted once.
    if (result.reachedForge && !result.forged && !_forgeAttempted) {
      _forgeAttempted = true;
      final wrote = await _onboarding.forgeFromTranscript(widget.userId);
      if (!mounted) return;
      if (wrote) {
        final after = await _onboarding.sync(widget.userId);
        if (!mounted) return;
        if (after.available) result = after;
      }
    }

    _applySync(result);
  }

  void _applySync(OnboardingSync result) {
    setState(() {
      if (_firstSync) {
        _prevCompleted = result.completedCount;
        _firstSync = false;
      } else if (result.completedCount > _prevCompleted) {
        for (var i = _prevCompleted;
            i < result.completedCount && i < _sectionRewards.length;
            i++) {
          _rewardQueue.add(_sectionRewards[i]);
        }
        _prevCompleted = result.completedCount;
      }
      _sync = result;
      // Complete when the agent reached the forge stage — whether or not the
      // habit doc was written and regardless of the (award-dependent) MP count,
      // so the flow can never dead-end. The rich habit card renders only when
      // forged fields are available; otherwise a generic confirmation shows.
      if (result.forged || result.reachedForge || result.completedCount >= 5) {
        _showForge = true;
      }
    });
    widget.onProgress(result.completedCount);
  }

  void _dismissReward() {
    setState(() {
      if (_rewardQueue.isNotEmpty) _rewardQueue.removeAt(0);
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final completed = List<int>.generate(_sync.completedCount, (i) => i + 1);
    final active = (_sync.completedCount + 1).clamp(1, 5);

    return Scaffold(
      backgroundColor: MM.pageBg,
      body: Stack(
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          SafeArea(
            child: Column(
              children: [
                _header(completed, active),
                Expanded(child: _body()),
                if (!_showForge) _inputBar(),
              ],
            ),
          ),
          if (_rewardQueue.isNotEmpty)
            _RewardOverlay(reward: _rewardQueue.first, onDismiss: _dismissReward),
          if (_showForge)
            _ForgeConfirmOverlay(
              fields: _sync.fields,
              onLockIn: widget.onComplete,
            ),
        ],
      ),
    );
  }

  Widget _header(List<int> completed, int active) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [MM.yellow.withOpacity(0.06), Colors.transparent],
        ),
        border: Border(
          bottom: BorderSide(color: MM.yellow.withOpacity(0.2)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: widget.onBack,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: MM.navy.withOpacity(0.55),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      size: 13, color: Colors.white),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('STAGE 1 · HHS',
                        style: MM.displayX(size: 9, color: MM.yellow)),
                    const SizedBox(height: 2),
                    Text('${_sync.completedCount}/5 · Forge your Golden Habit',
                        style: MM.display(size: 13, color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(width: 32),
            ],
          ),
          const SizedBox(height: 6),
          HHSPyramid(active: active, completed: completed, compact: true),
        ],
      ),
    );
  }

  Widget _body() {
    if (_booting) {
      return const Center(child: CircularProgressIndicator(color: MM.yellow));
    }
    if (_error != null && _messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Couldn't reach Nova",
                  style: MM.display(size: 15, color: Colors.white)),
              const SizedBox(height: 8),
              Text('Check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: MM.body(color: Colors.white.withOpacity(0.6), size: 12)),
              const SizedBox(height: 14),
              MMPrimaryButton(label: 'Retry', onPressed: _boot),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      itemCount: _messages.length + (_sending ? 1 : 0),
      itemBuilder: (context, i) {
        if (i >= _messages.length) return const _TypingBubble();
        return _ChatBubble(message: _messages[i]);
      },
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 4,
              enabled: !_sending,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: MM.body(color: Colors.white, size: 13),
              decoration: InputDecoration(
                hintText: 'Message Nova…',
                hintStyle: MM.body(color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: MM.navy.withOpacity(0.55),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: MM.blue.withOpacity(0.33)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: MM.blue.withOpacity(0.33)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: MM.blue),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _sending ? null : _send,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3A8DFF), Color(0xFF1F5FB8)],
                ),
                boxShadow: [
                  BoxShadow(color: MM.blue.withOpacity(0.4), blurRadius: 12),
                ],
              ),
              child: Icon(
                _sending ? Icons.hourglass_empty : Icons.arrow_upward,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chat bubble ─────────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isMe = message.role == 'user';
    final hasText = message.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82,
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (hasText)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF3A8DFF), Color(0xFF1F5FB8)],
                          )
                        : null,
                    color: isMe ? null : MM.navy.withOpacity(0.7),
                    border: Border.all(
                      color: isMe
                          ? const Color(0xFF4D9BFF).withOpacity(0.5)
                          : MM.violet.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isMe ? 14 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 14),
                    ),
                  ),
                  child: Text(message.text,
                      style:
                          MM.body(color: Colors.white, size: 13, height: 1.45)),
                ),
              for (final url in message.imageUrls)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      width: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: MM.navy.withOpacity(0.7),
            border: Border.all(color: MM.violet.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text('Nova is typing…',
              style: MM.body(color: Colors.white.withOpacity(0.6), size: 12)),
        ),
      ),
    );
  }
}

// ─── Reward overlay ──────────────────────────────────────────────────────
class _RewardOverlay extends StatelessWidget {
  const _RewardOverlay({required this.reward, required this.onDismiss});
  final _SectionReward reward;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onDismiss,
        child: Container(
          color: Colors.black.withOpacity(0.78),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(reward.emoji, style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 10),
                Text('ACHIEVEMENT UNLOCKED',
                    style: MM.displayX(size: 10, color: reward.color)),
                const SizedBox(height: 6),
                Text(reward.label,
                    textAlign: TextAlign.center,
                    style: MM.display(size: 22, color: Colors.white)),
                const SizedBox(height: 10),
                Text('+${reward.mp} MP',
                    style: MM.display(size: 26, color: MM.yellow, height: 1)),
                const SizedBox(height: 18),
                Text('Tap to continue',
                    style: MM.body(
                        color: Colors.white.withOpacity(0.5), size: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Forge confirm overlay ───────────────────────────────────────────────
class _ForgeConfirmOverlay extends StatelessWidget {
  const _ForgeConfirmOverlay({required this.fields, required this.onLockIn});
  final OnboardingFields? fields;
  final VoidCallback onLockIn;

  Widget _row(String label, String value, Color color) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(text: '$label  ', style: MM.displayX(size: 9, color: color)),
          TextSpan(
              text: value,
              style: MM.body(color: Colors.white.withOpacity(0.85), size: 12)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.82),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('✨', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 6),
                  Text('GOLDEN HABIT FORGED',
                      style: MM.displayX(size: 11, color: MM.yellow)),
                  const SizedBox(height: 12),
                  if (fields != null)
                    GlassPanel(
                      borderColor: MM.teal.withOpacity(0.5),
                      background: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            MM.teal.withOpacity(0.13),
                            Colors.transparent
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              fields!.habitName.isEmpty
                                  ? 'Your Golden Habit'
                                  : fields!.habitName,
                              style:
                                  MM.display(size: 17, color: Colors.white)),
                          if (fields!.coreLabel.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(fields!.coreLabel.toUpperCase(),
                                style: MM.displayX(
                                    size: 10,
                                    color: Colors.white.withOpacity(0.5))),
                          ],
                          const SizedBox(height: 12),
                          _row('WHEN', fields!.when, MM.blue),
                          _row('WHERE', fields!.where, MM.blue),
                          _row('WHAT', fields!.what, MM.blue),
                          _row('IF-THEN', fields!.ifThen, MM.yellow),
                          _row('WHY', fields!.why, MM.magenta),
                        ],
                      ),
                    )
                  else
                    Text(
                      'Your first Golden Habit is forged and saved to your '
                      'Momentum Lists.',
                      textAlign: TextAlign.center,
                      style: MM.body(
                          color: Colors.white.withOpacity(0.75),
                          size: 13,
                          height: 1.5),
                    ),
                  const SizedBox(height: 10),
                  if (fields != null)
                    Text('Saved to your Momentum Lists.',
                        style: MM.body(
                            color: Colors.white.withOpacity(0.55), size: 11)),
                  const SizedBox(height: 16),
                  MMPrimaryButton(
                    label: 'Lock it in 🔓 Unlock Command Center',
                    pulse: true,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    onPressed: onLockIn,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
