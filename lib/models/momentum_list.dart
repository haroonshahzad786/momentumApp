/// One bucket from `fetchAllMomentumLists`. The deployed endpoint returns
/// `{ name: string, items: string[] }` per list; there's no core association
/// or color metadata stored server-side.
class MomentumList {
  const MomentumList({required this.name, required this.items});

  final String name;
  final List<String> items;

  /// Active items only — archived ones are kept but not counted.
  int get count => items.where((e) => !isArchivedItem(e)).length;

  factory MomentumList.fromJson(Map<String, dynamic> json) => MomentumList(
        name: (json['name'] ?? '').toString(),
        items: (json['items'] as List? ?? const [])
            .map((e) => e.toString())
            .where((s) => s.isNotEmpty)
            .toList(),
      );
}

/// One of the 21 Momentum Lists defined by "Command Center w/ Momentum Lists
/// (Detailed Version)". [aliases] are other names the server may already hold
/// the list under (matched case-insensitively, ignoring a trailing "List").
class MomentumListSpec {
  const MomentumListSpec(this.name, this.blurb, [this.aliases = const []]);

  final String name;

  /// The doc's one-line "What it is".
  final String blurb;
  final List<String> aliases;
}

/// The 21 Momentum Lists, in the doc's order (#1–#21).
const List<MomentumListSpec> kMomentumListSpecs = [
  MomentumListSpec(
    'Back to the Future',
    'Your end-of-life legacy goals in each of the 5 Cores.',
    ['Back to the Future/Legacy Goals', 'Legacy Goals'],
  ),
  MomentumListSpec(
    'Mantra',
    'A short, emotionally charged statement of who you are becoming.',
  ),
  MomentumListSpec(
    'Gratitude',
    'What you are grateful for across the 5 Cores.',
    ['Grateful List'],
  ),
  MomentumListSpec(
    'Strengths',
    'Natural talents, learned skills and adaptive traits that lower friction.',
  ),
  MomentumListSpec(
    'Weaknesses',
    'Recurring blind spots, limiting beliefs and friction points.',
    ['Weaknesses/Growth Opportunities', 'Growth Opportunities'],
  ),
  MomentumListSpec('Passions', 'What energizes and excites you.'),
  MomentumListSpec('Dislikes', 'What drains your energy or creates resistance.'),
  MomentumListSpec(
    'Routines',
    'Your daily habits by time block, color-coded.',
    ['Routines Habits', 'Routine Habits', 'Routines Habit List'],
  ),
  MomentumListSpec(
    'Non-Routines',
    'Emotion-triggered habits by Core, with IF-THEN responses.',
    ['Non-Routines Habits', 'Non-Routine Habits', 'Non Routines'],
  ),
  MomentumListSpec(
    'Top People',
    'Who you spend time with and who could support your growth.',
    ['People', 'Social Support'],
  ),
  MomentumListSpec(
    'Top Environments',
    'The spaces that shape your habits, and where you thrive.',
    ['Environments', 'Environment'],
  ),
  MomentumListSpec(
    'Top Irrational Fears',
    'Fears that quietly limit action, with a reversal plan.',
    ['Irrational Fears', 'Top Fears', 'Fears'],
  ),
  MomentumListSpec(
    'Daily Bold Tracker',
    'One bold action a day that pushes past fear.',
    ['Bold Tracker'],
  ),
  MomentumListSpec(
    'Obstacles',
    'Internal, external and systemic blockers, with if-then plans.',
  ),
  MomentumListSpec(
    'Messes to Clean',
    'Physical, digital, emotional and mental clutter to clear.',
    ['Messes to Clean / Space Junk', 'Space Junk'],
  ),
  MomentumListSpec(
    'Captain\'s Log',
    'Your biggest win and biggest challenge, each day.',
    ['Captains Log', 'Captain\'s Log / Journal', 'Journal'],
  ),
  MomentumListSpec(
    'One-Time Actions',
    'Single setup tasks that remove friction for good.',
    ['One-Time Actions to Automate', 'One Time Actions'],
  ),
  MomentumListSpec(
    'Fav Tech Automations',
    'Apps and tools that help you stay consistent.',
    ['Tech Automations'],
  ),
  MomentumListSpec(
    'Career Goals',
    'Short-, mid- and long-term professional targets.',
  ),
  MomentumListSpec(
    'Lifestyle Factors',
    'The real-world conditions your habits must fit.',
    ['Lifestyle'],
  ),
  MomentumListSpec(
    'Trophy Room',
    'Every habit you have turned into autopilot, by Core.',
    ['Habits Formed', 'Trophy Room/Habits Formed', 'Formed Habits'],
  ),
];

String _normListName(String name) => name
    .replaceAll('’', '\'')
    .trim()
    .toLowerCase()
    .replaceFirst(RegExp(r'\s+list$'), '');

/// The doc list a server-side name belongs to, or null for a custom list.
MomentumListSpec? momentumListSpecFor(String name) {
  final n = _normListName(name);
  for (final s in kMomentumListSpecs) {
    if (_normListName(s.name) == n ||
        s.aliases.any((a) => _normListName(a) == n)) {
      return s;
    }
  }
  return null;
}

/// The 5 Core areas, as used in `#ListType::CoreArea::TagLabel` tags.
const List<String> kMomentumCores = [
  'Mindset',
  'Career',
  'Relationships',
  'Physical',
  'Emotional',
];

/// Lists the doc keeps per Core (1–3 entries each, grouped by Core area).
const Set<String> kPerCoreLists = {
  'Back to the Future',
  'Gratitude',
  'Strengths',
  'Weaknesses',
  'Passions',
  'Dislikes',
  'Top Irrational Fears',
  'Obstacles',
  'Messes to Clean',
  'Career Goals',
};

bool isPerCoreList(String listName) {
  final spec = momentumListSpecFor(listName);
  return spec != null && kPerCoreLists.contains(spec.name);
}

/// One stored item parsed from the doc's tag format
/// `#ListType::CoreArea::TagLabel`. Untagged items have a null [core].
class ListItemTag {
  const ListItemTag(this.core, this.label);
  final String? core;
  final String label;
}

final RegExp _tagRe = RegExp(r'^#([^:]+)::([^:]+)::(.*)$', dotAll: true);

/// Parses [raw]; the Core is normalised to one of [kMomentumCores] when it
/// matches (case-insensitive prefix, e.g. "Physical Health" → "Physical").
ListItemTag parseListItem(String raw) {
  raw = stripItemFlags(raw);
  final m = _tagRe.firstMatch(raw.trim());
  if (m == null) return ListItemTag(null, raw);
  final c = m.group(2)!.trim().toLowerCase();
  String? core;
  for (final k in kMomentumCores) {
    if (c.startsWith(k.toLowerCase())) core = k;
  }
  return ListItemTag(core, m.group(3)!.trim());
}

/// Encodes [label] for [listName] under [core] (no core → plain text).
String encodeListItem(String listName, String? core, String label) {
  if (core == null) return label;
  final type = (momentumListSpecFor(listName)?.name ?? listName).replaceAll(
    RegExp(r'\s+'),
    '',
  );
  return '#$type::$core::$label';
}

/// Canonical names — offered as suggestions when the user creates a list, and
/// shown as locked slots on the Command Center console until filled.
final List<String> kCanonicalMomentumLists = [
  for (final s in kMomentumListSpecs) s.name,
];

// ─── Structured lists (doc §10, §11, §13, §16) ───────────────────────────
// Stored in the same flat `items[]`, in the doc's tag format with a readable
// ` | `-separated label, so no backend change is needed:
//   Top People / Environments : #TopPeople::All::Name | <sub 0|1> | M4 C3 R5 P2 E4 | note
//   Daily Bold Tracker        : #DailyBoldTracker::<Core>::2026-10-12 | action | reflection
//   Captain's Log             : #CaptainsLog::All::2026-10-12 | win | challenge | reflection

enum ListKind { flat, perCore, twoPart, boldTable, log }

ListKind listKindFor(String listName) {
  switch (momentumListSpecFor(listName)?.name) {
    case 'Top People':
    case 'Top Environments':
      return ListKind.twoPart;
    case 'Daily Bold Tracker':
      return ListKind.boldTable;
    case "Captain's Log":
      return ListKind.log;
  }
  return isPerCoreList(listName) ? ListKind.perCore : ListKind.flat;
}

/// Sub-list titles for the two-part lists (doc: Time Spent vs Support, Current
/// vs Preferred).
const Map<String, List<String>> kSubListTitles = {
  'Top People': ['People You Spend the Most Time With', 'Support / Accountability People'],
  'Top Environments': ['Current Frequented Environments', 'Preferred / Supportive Environments'],
};

const List<String> _coreLetters = ['M', 'C', 'R', 'P', 'E'];

String _clean(String s) => s.replaceAll('|', '/').replaceAll('\n', ' ').trim();

List<String> _fields(String raw) {
  raw = stripItemFlags(raw);
  final m = _tagRe.firstMatch(raw.trim());
  final label = m == null ? raw : m.group(3)!;
  return label.split('|').map((e) => e.trim()).toList();
}

String _typeOf(String listName) => (momentumListSpecFor(listName)?.name ?? listName)
    .replaceAll(RegExp(r"[\s']+"), '');

class TwoPartEntry {
  const TwoPartEntry(this.sub, this.name, this.scores, this.note);
  final int sub; // 0 = first sub-list, 1 = second
  final String name;
  final List<int?> scores; // per Core (kMomentumCores order), 1–5
  final String note;
}

String encodeTwoPart(String listName, TwoPartEntry e) {
  final sc = [
    for (var i = 0; i < 5; i++)
      if (e.scores[i] != null) '${_coreLetters[i]}${e.scores[i]}',
  ].join(' ');
  return '#${_typeOf(listName)}::All::${_clean(e.name)} | ${e.sub} | $sc | ${_clean(e.note)}';
}

/// Null when [raw] isn't in the structured format (e.g. a legacy plain item).
TwoPartEntry? parseTwoPart(String raw) {
  if (isArchivedItem(raw)) return null;
  if (!_tagRe.hasMatch(raw.trim())) return null;
  final f = _fields(raw);
  if (f.length < 2 || (f[1] != '0' && f[1] != '1')) return null;
  final scores = List<int?>.filled(5, null);
  for (final m in RegExp(r'([MCRPE])([1-5])').allMatches(f.length > 2 ? f[2] : '')) {
    scores[_coreLetters.indexOf(m.group(1)!)] = int.parse(m.group(2)!);
  }
  return TwoPartEntry(int.parse(f[1]), f[0], scores, f.length > 3 ? f[3] : '');
}

class BoldEntry {
  const BoldEntry(this.date, this.core, this.action, this.reflection);
  final String date; // yyyy-mm-dd
  final String core;
  final String action;
  final String reflection;
}

String encodeBold(BoldEntry e) =>
    '#DailyBoldTracker::${e.core}::${e.date} | ${_clean(e.action)} | ${_clean(e.reflection)}';

BoldEntry? parseBold(String raw) {
  if (isArchivedItem(raw)) return null;
  final m = _tagRe.firstMatch(raw.trim());
  if (m == null) return null;
  final f = _fields(raw);
  if (f.length < 2) return null;
  return BoldEntry(f[0], parseListItem(raw).core ?? m.group(2)!.trim(), f[1], f.length > 2 ? f[2] : '');
}

class LogEntry {
  const LogEntry(this.date, this.win, this.challenge, this.reflection);
  final String date;
  final String win;
  final String challenge;
  final String reflection;
}

String encodeLog(LogEntry e) =>
    '#CaptainsLog::All::${e.date} | ${_clean(e.win)} | ${_clean(e.challenge)} | ${_clean(e.reflection)}';

LogEntry? parseLog(String raw) {
  if (isArchivedItem(raw)) return null;
  if (!_tagRe.hasMatch(raw.trim())) return null;
  final f = _fields(raw);
  if (f.length < 3) return null;
  return LogEntry(f[0], f[1], f[2], f.length > 3 ? f[3] : '');
}

/// Lists the Command Center doc tells the player to read together with a list
/// ("Cross-reference with…", "Pair with…", "Combine with…"). Doc-sourced only.
const Map<String, List<String>> kListSeeAlso = {
  'Strengths': ['Weaknesses', 'Non-Routines'],
  'Weaknesses': ['Strengths'],
  'Dislikes': ['Passions', 'Weaknesses', 'Routines'],
  'Routines': ['Non-Routines'],
  'Non-Routines': ['Routines', 'Strengths', 'Back to the Future'],
  'Top People': ['Top Environments'],
  'Top Environments': ['Top People'],
  'Daily Bold Tracker': [
    'Top Irrational Fears',
    'Weaknesses',
    'Obstacles',
    "Captain's Log",
  ],
  'Obstacles': ['Weaknesses', 'Top Irrational Fears'],
  "Captain's Log": ['Gratitude'],
  'Trophy Room': ['Routines', 'Non-Routines'],
};

List<String> seeAlsoFor(String listName) =>
    kListSeeAlso[momentumListSpecFor(listName)?.name] ?? const [];

// ─── Item flags (doc: archive instead of delete, source, done/pending) ───
// Trailing space-separated markers on the stored item string, e.g.
//   "Buy a blender ~src:manual ~done"   "Old goal ~arch"
// Plain items with no markers are unaffected.

final RegExp _flagRe = RegExp(r'(\s~(?:arch|done|src:[a-z]+))+\s*$');

class ItemFlags {
  const ItemFlags({this.archived = false, this.done = false, this.source});
  final bool archived;
  final bool done;

  /// 'manual' when the player added it by hand; null = not recorded (items
  /// written by Phase 1 / Nova carry no marker yet).
  final String? source;
}

String stripItemFlags(String raw) => raw.replaceFirst(_flagRe, '').trimRight();

ItemFlags itemFlags(String raw) {
  final m = _flagRe.firstMatch(raw);
  if (m == null) return const ItemFlags();
  final s = m.group(0)!;
  final src = RegExp(r'~src:([a-z]+)').firstMatch(s)?.group(1);
  return ItemFlags(
    archived: s.contains('~arch'),
    done: s.contains('~done'),
    source: src,
  );
}

bool isArchivedItem(String raw) => itemFlags(raw).archived;

/// [raw] (flags stripped) re-marked with [f].
String withItemFlags(String raw, ItemFlags f) {
  final base = stripItemFlags(raw);
  return [
    base,
    if (f.source != null) '~src:${f.source}',
    if (f.done) '~done',
    if (f.archived) '~arch',
  ].join(' ');
}
