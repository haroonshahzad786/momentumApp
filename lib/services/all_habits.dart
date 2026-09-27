import '../models/core_list.dart';
import '../models/golden_habit.dart';
import 'checkin_service.dart' show DailyCheckin;
import 'formation.dart';
import 'onboarding_service.dart';

// ALL HABITS Quick View (PRD §11, #21). Habits live in two stores:
//   • Golden Habits (`golden_habits/*`) — structured, what HHS forges;
//   • per-core "Routines List" / "Non-Routine" line items — the schedule.
// Adding a habit from Routines writes both, HHS may write only one, so the
// view merges them and drops duplicates (same Core + same name).

/// PRD §11 colour key. Golden Habits are coloured automatically (🟠 forming,
/// 🟢 formed); every other line carries the colour the player tagged it with.
enum HabitColor {
  red('🔴', 'Bad habit', 'Eliminate or replace'),
  orange('🟠', 'Forming', 'Golden Habit being formed — score daily'),
  black('⚫', 'Neutral', 'Candidate for a future upgrade'),
  green('🟢', 'Healthy', 'Established — maintain and reinforce'),
  blue('🔵', 'MBM', 'Momentum-Boosting Method attached to a Golden Habit'),
  note('🌟', 'Note', 'Observation for future action');

  const HabitColor(this.emoji, this.label, this.meaning);
  final String emoji;
  final String label;
  final String meaning;

  static HabitColor? parse(String? id) {
    for (final c in values) {
      if (c.name == id) return c;
    }
    return null;
  }
}

/// Map key for one stored line — mirrors `itemKey` in functions-flutter/
/// coreLists.js, which stores the colours under it.
String itemKey(String item) {
  var k = item
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  if (k.length > 150) k = k.substring(0, 150);
  return k;
}

/// 🔴 / 🟠 / 🟢 tallies for the PRD §11 status counter.
({int red, int orange, int green}) statusCounts(Iterable<HabitColor?> colors) {
  var r = 0, o = 0, g = 0;
  for (final c in colors) {
    if (c == HabitColor.red) r++;
    if (c == HabitColor.orange) o++;
    if (c == HabitColor.green) g++;
  }
  return (red: r, orange: o, green: g);
}

/// Where a habit sits in the day. Routines land in a time block; non-routines
/// are triggered by situations, so they go in "Throughout Day" (PRD §11).
enum HabitSlot { morning, workday, evening, anytime, throughout }

const Map<HabitSlot, String> kHabitSlotLabel = {
  HabitSlot.morning: 'Morning',
  HabitSlot.workday: 'Afternoon',
  HabitSlot.evening: 'Evening',
  HabitSlot.anytime: 'Anytime',
  HabitSlot.throughout: 'Throughout Day',
};

/// PRD §11 By Core order: 🧠 → 💰 → 👥 → 💪 → 🧘.
const List<String> kCoreOrder = [
  'mindset',
  'career',
  'relationships',
  'physical',
  'emotional',
];

/// keyword → block id. Only short, unambiguous tokens map a block.
const Map<String, String> kBlockKeywords = {
  'morning': 'morning', 'dawn': 'morning', 'am': 'morning',
  'launch': 'morning', 'wake': 'morning', 'sunrise': 'morning',
  'afternoon': 'workday', 'midday': 'workday', 'noon': 'workday',
  'workday': 'workday', 'work': 'workday', 'day': 'workday',
  'evening': 'evening', 'night': 'evening', 'pm': 'evening',
  'bedtime': 'evening', 'reentry': 'evening', 're-entry': 'evening',
  'dusk': 'evening', 'sunset': 'evening',
};

/// A stored list line split into its parts.
typedef HabitLine = ({String name, String? blockId, String? cue});

/// Splits a stored line into {block, cue, name}. Accepts the recommended
/// `Block · Habit · cue` convention (delimiter `·` or `|`) and falls back to
/// scanning a plain line for an embedded time-of-day word.
HabitLine parseHabitLine(String raw) {
  final tokens = raw
      .split(RegExp(r'\s*[·|]\s*'))
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();
  String? blockId;
  String? cue;
  final nameParts = <String>[];
  for (final t in tokens) {
    final key = t.toLowerCase();
    if (blockId == null &&
        kBlockKeywords.containsKey(key) &&
        t.split(' ').length <= 2) {
      blockId = kBlockKeywords[key];
      continue;
    }
    if (cue == null &&
        RegExp(r'^(after|before|when|during|once)\b', caseSensitive: false)
            .hasMatch(t)) {
      cue = t;
      continue;
    }
    nameParts.add(t);
  }
  var name = nameParts.join(' · ');
  if (name.isEmpty) name = raw;
  // Fallback: a strong block word sitting inside the habit name.
  blockId ??= blockFromText(name);
  return (name: name, blockId: blockId, cue: cue);
}

/// The time block an unambiguous time word in [text] names, or null. Avoids
/// "work"/"day", which show up in plenty of habit names.
String? blockFromText(String text) {
  for (final w in text.toLowerCase().split(RegExp(r'[^a-z]+'))) {
    if (const {'morning', 'afternoon', 'evening', 'night'}.contains(w)) {
      return kBlockKeywords[w];
    }
  }
  return null;
}

HabitSlot _slotFor(bool isRoutine, String? blockId) {
  if (!isRoutine) return HabitSlot.throughout;
  return switch (blockId) {
    'morning' => HabitSlot.morning,
    'workday' => HabitSlot.workday,
    'evening' => HabitSlot.evening,
    _ => HabitSlot.anytime,
  };
}

/// One row of the All Habits view.
class AllHabit {
  const AllHabit({
    required this.name,
    required this.core,
    required this.isRoutine,
    required this.slot,
    required this.color,
    this.progress,
    this.habitId,
    this.flagged = false,
  });

  final String name;

  /// Short Core id ('physical', …).
  final String core;
  final bool isRoutine;
  final HabitSlot slot;

  /// Null for a line the player hasn't tagged yet.
  final HabitColor? color;

  /// Formation progress for a Golden Habit still forming (Day X/14).
  final FormationProgress? progress;

  /// Set when the row is (or matched) a Golden Habit.
  final String? habitId;
  final bool flagged;

  bool get isGolden => habitId != null;
}

String _key(String core, String name) =>
    '$core|${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim()}';

/// Golden Habits keyed by Core + name, for matching them to list lines.
Map<String, GoldenHabit> goldenIndex(List<GoldenHabit> golden) => {
      for (final g in golden)
        _key(GoldenHabitRef.shortCore(g.coreId), _goldenName(g)): g,
    };

String _goldenName(GoldenHabit g) => g.habitName.trim().isNotEmpty
    ? g.habitName.trim()
    : (g.displayText.trim().isNotEmpty ? g.displayText.trim() : 'Golden Habit');

HabitColor _goldenColor(GoldenHabit g) =>
    g.formed ? HabitColor.green : HabitColor.orange;

/// How one stored line shows in every view: a matching Golden Habit's
/// automatic colour + formation progress, else the player's tagged colour.
({HabitColor? color, FormationProgress? progress, GoldenHabit? golden})
    lineStatus(CoreList list, String raw, Map<String, GoldenHabit> goldenByKey,
        Map<String, List<int>> coreScores) {
  final core = GoldenHabitRef.shortCore(list.coreId);
  final g = goldenByKey[_key(core, parseHabitLine(raw).name)];
  if (g != null) {
    return (
      color: _goldenColor(g),
      progress: g.formed ? null : formationProgress(coreScores[core] ?? const []),
      golden: g,
    );
  }
  return (
    color: HabitColor.parse(list.colors[itemKey(raw)]),
    progress: null,
    golden: null,
  );
}

/// Merges Golden Habits with the Routines / Non-Routine list lines.
/// [coreScores] is short Core id → daily scores (newest first) — the Trophy
/// Room's source for a Golden Habit's formation progress.
List<AllHabit> mergeAllHabits({
  required List<GoldenHabit> golden,
  required List<CoreList> routineLists,
  required List<CoreList> nonRoutineLists,
  required Map<String, List<int>> coreScores,
}) {
  // List lines first, so a Golden Habit can borrow a line's time block when
  // its own `when` doesn't name one.
  final lines = <String, AllHabit>{};
  void addLines(List<CoreList> lists, bool isRoutine) {
    for (final l in lists) {
      final core = GoldenHabitRef.shortCore(l.coreId);
      for (final raw in l.items) {
        final p = parseHabitLine(raw);
        final k = _key(core, p.name);
        if (lines.containsKey(k)) continue;
        lines[k] = AllHabit(
          name: p.name,
          core: core,
          isRoutine: isRoutine,
          slot: _slotFor(isRoutine, p.blockId),
          color: HabitColor.parse(l.colors[itemKey(raw)]),
        );
      }
    }
  }

  addLines(routineLists, true);
  addLines(nonRoutineLists, false);

  final out = <AllHabit>[];
  for (final g in golden) {
    final name = _goldenName(g);
    final core = GoldenHabitRef.shortCore(g.coreId);
    final line = lines.remove(_key(core, name));
    // Type comes from the Golden Habit; if it never said, trust the list.
    final isRoutine = switch (g.habitType) {
      'routine' => true,
      'non_routine' => false,
      _ => line?.isRoutine ?? true,
    };
    final blockId = blockFromText(g.when) ??
        (line != null && line.isRoutine
            ? switch (line.slot) {
                HabitSlot.morning => 'morning',
                HabitSlot.workday => 'workday',
                HabitSlot.evening => 'evening',
                _ => null,
              }
            : null);
    final progress = formationProgress(coreScores[core] ?? const []);
    out.add(AllHabit(
      name: name,
      core: core,
      isRoutine: isRoutine,
      slot: _slotFor(isRoutine, blockId),
      color: _goldenColor(g),
      progress: g.formed ? null : progress,
      habitId: g.habitId,
      flagged: g.flagged,
    ));
  }
  out.addAll(lines.values);
  return out;
}

int _coreRank(String core) {
  final i = kCoreOrder.indexOf(core);
  return i < 0 ? kCoreOrder.length : i;
}

/// A titled group of rows.
typedef HabitSection = ({String id, String title, List<AllHabit> habits});

/// By Time: Morning → Afternoon → Evening → Anytime → Throughout Day, each
/// sorted by Core then name. Empty sections are left out.
List<HabitSection> groupByTime(List<AllHabit> habits) => [
      for (final slot in HabitSlot.values)
        if (habits.any((h) => h.slot == slot))
          (
            id: slot.name,
            title: kHabitSlotLabel[slot]!,
            habits: habits.where((h) => h.slot == slot).toList()
              ..sort((a, b) {
                final c = _coreRank(a.core).compareTo(_coreRank(b.core));
                return c != 0 ? c : a.name.compareTo(b.name);
              }),
          ),
    ];

/// By Core: 🧠 → 💰 → 👥 → 💪 → 🧘, each sorted by time slot (routines
/// first, non-routines last) then name. Empty Cores are left out.
List<HabitSection> groupByCore(List<AllHabit> habits, Map<String, String> coreTitle) {
  final cores = [
    ...kCoreOrder,
    ...{for (final h in habits) h.core}.where((c) => !kCoreOrder.contains(c)),
  ];
  return [
    for (final core in cores)
      if (habits.any((h) => h.core == core))
        (
          id: core,
          title: coreTitle[core] ?? core,
          habits: habits.where((h) => h.core == core).toList()
            ..sort((a, b) {
              final s = a.slot.index.compareTo(b.slot.index);
              return s != 0 ? s : a.name.compareTo(b.name);
            }),
        ),
  ];
}

/// Short Core id → daily scores, newest first (check-ins arrive newest first).
Map<String, List<int>> coreScoreSeries(List<DailyCheckin> checkins) {
  final byCore = <String, List<int>>{};
  for (final c in checkins) {
    c.scores.forEach((core, v) => byCore.putIfAbsent(core, () => []).add(v));
  }
  return byCore;
}
