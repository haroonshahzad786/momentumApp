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
