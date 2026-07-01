/// One list under a core's category, flattened from `fetchAllCoreListItems`
/// (`/users/{uid}/core/{coreId}/{categoryId}/{listName}`).
///
/// The endpoint stores only a flat `items` array of strings — any Time-of-Day
/// or Anchor subtags from the HHS flow live inside the item text itself, not as
/// structured fields. `coreId` / `coreLabel` are the only grouping data stored.
class CoreList {
  const CoreList({
    required this.coreId,
    required this.coreLabel,
    required this.categoryId,
    required this.name,
    required this.items,
  });

  final String coreId;
  final String coreLabel;
  final String categoryId;
  final String name;
  final List<String> items;

  int get count => items.length;

  /// Flattens the nested `cores → categories → lists` payload from
  /// `fetchAllCoreListItems` into a flat list of [CoreList].
  static List<CoreList> flattenFromResponse(List<dynamic> cores) {
    final result = <CoreList>[];
    for (final core in cores.whereType<Map>()) {
      final coreId = (core['id'] ?? '').toString();
      final coreLabel = (core['label'] ?? coreId).toString();
      final categories = core['categories'];
      if (categories is! List) continue;
      for (final cat in categories.whereType<Map>()) {
        final categoryId = (cat['id'] ?? '').toString();
        final lists = cat['lists'];
        if (lists is! List) continue;
        for (final l in lists.whereType<Map>()) {
          result.add(CoreList(
            coreId: coreId,
            coreLabel: coreLabel,
            categoryId: categoryId,
            name: (l['name'] ?? '').toString(),
            items: (l['items'] as List? ?? const [])
                .map((e) => e.toString())
                .where((s) => s.isNotEmpty)
                .toList(),
          ));
        }
      }
    }
    return result;
  }
}
