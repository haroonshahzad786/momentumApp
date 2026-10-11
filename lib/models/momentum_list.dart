/// One bucket from `fetchAllMomentumLists`. The deployed endpoint returns
/// `{ name: string, items: string[] }` per list; there's no core association
/// or color metadata stored server-side.
class MomentumList {
  const MomentumList({required this.name, required this.items});

  final String name;
  final List<String> items;

  int get count => items.length;

  factory MomentumList.fromJson(Map<String, dynamic> json) => MomentumList(
        name: (json['name'] ?? '').toString(),
        items: (json['items'] as List? ?? const [])
            .map((e) => e.toString())
            .where((s) => s.isNotEmpty)
            .toList(),
      );
}

/// The 17 canonical Momentum Lists (Build Guide §Feature 4). Offered as
/// suggestions when the user creates a list, and shown as locked slots on the
/// Command Center console until Nova (or the player) fills them.
const List<String> kCanonicalMomentumLists = [
  'Strengths', 'Passions', 'Fears', 'Goals', 'Obstacles',
  'Values', 'Triggers', 'Rewards', 'Accountability', 'Environment',
  'Time Availability', 'Energy Patterns', 'Social Support', 'Resources',
  'Past Successes', 'Past Failures', 'Back to the Future',
];
