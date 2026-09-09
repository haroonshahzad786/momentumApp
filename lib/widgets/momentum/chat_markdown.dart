import 'package:flutter/material.dart';

/// Nova (the Voiceflow agent) writes its replies in light markdown — headings
/// and emphasis come back as `**The Law of Environment Design:**` and
/// `*"Connect before you correct."*`. Rendered as plain text those asterisks
/// show up literally, so this turns them into real bold / italic runs.
///
/// Deliberately NOT a markdown package: only the emphasis the agent actually
/// emits is handled, and anything unmatched is left exactly as the agent wrote
/// it rather than being silently swallowed.
///
/// Only `*` emphasis is supported — `_underscore_` is left alone on purpose,
/// since underscores turn up inside ids, urls and the agent's `>___` divider
/// lines, where treating them as emphasis would mangle the text.
class ChatMarkdownText extends StatelessWidget {
  const ChatMarkdownText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign,
  });

  final String text;

  /// Base style. Bold/italic runs inherit from it and override the weight.
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final spans = chatMarkdownSpans(text, style);
    // No emphasis found — a plain Text keeps the simplest path unchanged.
    if (spans.length == 1 && spans.first is TextSpan) {
      final only = spans.first as TextSpan;
      if (only.style == style) {
        return Text(only.text ?? '', style: style, textAlign: textAlign);
      }
    }
    return RichText(
      text: TextSpan(style: style, children: spans),
      textAlign: textAlign ?? TextAlign.start,
    );
  }
}

/// `**bold**` (checked first, so it wins over italic) and `*italic*`.
/// Emphasis may not span a line break — that keeps a lone `*` in one paragraph
/// from swallowing everything up to the next one.
final _emphasis = RegExp(r'\*\*([^*\n]+)\*\*|\*([^*\n]+)\*');

/// Splits [text] into styled runs. Exposed for callers that need the spans
/// directly (e.g. to append their own trailing span).
List<InlineSpan> chatMarkdownSpans(String text, TextStyle base) {
  final spans = <InlineSpan>[];
  var cursor = 0;

  for (final m in _emphasis.allMatches(text)) {
    if (m.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, m.start), style: base));
    }
    final bold = m.group(1);
    if (bold != null) {
      spans.add(TextSpan(
        text: bold,
        style: base.copyWith(fontWeight: FontWeight.w700),
      ));
    } else {
      spans.add(TextSpan(
        text: m.group(2),
        style: base.copyWith(fontStyle: FontStyle.italic),
      ));
    }
    cursor = m.end;
  }

  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: base));
  }
  if (spans.isEmpty) spans.add(TextSpan(text: text, style: base));
  return spans;
}
