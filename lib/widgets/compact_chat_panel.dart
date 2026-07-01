import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../theme/momentum_tokens.dart';

/// Top transcript panel with limited height. Auto-scrolls to the newest
/// message after a short delay so freshly-arrived assistant text isn't
/// instantly hidden by older content moving up.
class CompactChatPanel extends StatefulWidget {
  const CompactChatPanel({super.key, required this.messages});

  final List<ChatMessage> messages;

  @override
  State<CompactChatPanel> createState() => _CompactChatPanelState();
}

class _CompactChatPanelState extends State<CompactChatPanel> {
  final ScrollController _scroll = ScrollController();
  int _lastSeenCount = 0;

  static const Duration _scrollDelay = Duration(milliseconds: 1500);
  static const Duration _scrollAnim = Duration(milliseconds: 600);

  @override
  void didUpdateWidget(covariant CompactChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length > _lastSeenCount) {
      _lastSeenCount = widget.messages.length;
      Future.delayed(_scrollDelay, _scrollToBottom);
    }
  }

  void _scrollToBottom() {
    if (!mounted || !_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: _scrollAnim,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.messages
        .where((m) => m.text.trim().isNotEmpty)
        .toList();
    // Fills the height its parent (Expanded) allots — no fixed height.
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MM.navy.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: visible.isEmpty
          ? Center(
              child: Text(
                'Conversation will appear here.',
                style: MM.body(
                    color: Colors.white.withValues(alpha: 0.6), size: 12),
              ),
            )
          : ListView.separated(
              controller: _scroll,
              itemCount: visible.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _MessageBubble(message: visible[index]),
            ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isUser
                ? MM.blue
                : Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: isUser ? Colors.white : Colors.black87,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}
