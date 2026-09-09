import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled2/widgets/momentum/chat_markdown.dart';

/// The inline-markdown runs Nova's replies are split into. Real samples are
/// taken from a live Co-Pilot transcript.
void main() {
  const base = TextStyle(fontSize: 12);

  /// (text, isBold, isItalic) for each run, so assertions read as the sentence.
  List<(String, bool, bool)> runs(String src) => chatMarkdownSpans(src, base)
      .cast<TextSpan>()
      .map((s) => (
            s.text ?? '',
            s.style?.fontWeight == FontWeight.w700,
            s.style?.fontStyle == FontStyle.italic,
          ))
      .toList();

  test('plain text is a single unstyled run', () {
    expect(runs('Do these principles resonate with you?'), [
      ('Do these principles resonate with you?', false, false),
    ]);
  });

  test('**bold** becomes a bold run without the asterisks', () {
    expect(runs('**2). The Law of Environment Design:**'), [
      ('2). The Law of Environment Design:', true, false),
    ]);
  });

  test('*italic* becomes an italic run', () {
    expect(runs('– *"Connect before you correct."* — Dr. Daniel Siegel'), [
      ('– ', false, false),
      ('"Connect before you correct."', false, true),
      (' — Dr. Daniel Siegel', false, false),
    ]);
  });

  test('bold wins over italic when both could match', () {
    expect(runs('a **b** c'), [
      ('a ', false, false),
      ('b', true, false),
      (' c', false, false),
    ]);
  });

  test('several emphases in one line each get their own run', () {
    expect(runs('**one** plain **two**'), [
      ('one', true, false),
      (' plain ', false, false),
      ('two', true, false),
    ]);
  });

  test('an unmatched asterisk is left exactly as the agent wrote it', () {
    expect(runs('5 * 3 = 15'), [('5 * 3 = 15', false, false)]);
    expect(runs('**not closed'), [('**not closed', false, false)]);
  });

  test('emphasis does not span a line break', () {
    // A stray '*' must not swallow the rest of the reply.
    expect(runs('first *line\nsecond line*'), [
      ('first *line\nsecond line*', false, false),
    ]);
  });

  test('underscores are left alone (ids, urls, the agent divider lines)', () {
    expect(runs('>______'), [('>______', false, false)]);
    expect(runs('gh_morning_momentum'), [('gh_morning_momentum', false, false)]);
  });

  test('empty text yields one empty run rather than no runs', () {
    expect(runs(''), [('', false, false)]);
  });
}
