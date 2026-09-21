import 'package:flutter/material.dart';

import '../../services/admin_api_service.dart';
import '../../services/csv_download.dart';
import '../../theme/momentum_tokens.dart';
import 'admin_widgets.dart';

/// §9 Audit log — real, backed by `adminListAuditLog` (#A9.3). Matches the
/// design's filter bar (search, action, admin, date range, Export log) and
/// When/Who/Action/Target/Reason table.
///
/// Action / admin / date-range filters are applied SERVER-side (the endpoint
/// supports exactly those, backed by composite indexes); the free-text search
/// over target + reason is client-side over the rows already loaded, since the
/// endpoint has no text search. The log is append-only at the Firestore-rules
/// layer (#A9.2), so this screen is read-only by construction.
class AdminAuditScreen extends StatefulWidget {
  const AdminAuditScreen({super.key});

  @override
  State<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends State<AdminAuditScreen> {
  static const _pageSize = 50;
  static const _allActions = 'All actions';
  static const _allAdmins = 'All admins';
  static const _ranges = {
    'Last 7 days': Duration(days: 7),
    'Last 30 days': Duration(days: 30),
    'Last 90 days': Duration(days: 90),
    'All time': null,
  };

  final _api = AdminApiService();
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  List<Map> _rows = const [];
  String? _nextCursor;

  String _action = _allActions;
  String _admin = _allAdmins;
  String _range = 'Last 30 days';

  // Dropdown options accumulate across loads so picking a filter doesn't
  // collapse the very list you picked it from.
  final Set<String> _actionOptions = {};
  final Map<String, String> _adminOptions = {}; // uid -> label

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetch({String? cursor}) {
    final window = _ranges[_range];
    return _api.listAuditLog(
      action: _action == _allActions ? null : _action,
      adminUid: _admin == _allAdmins ? null : _admin,
      since: window == null ? null : DateTime.now().toUtc().subtract(window),
      limit: _pageSize,
      cursor: cursor,
    );
  }

  void _absorbOptions(List<Map> rows) {
    for (final r in rows) {
      final action = '${r['action'] ?? ''}';
      if (action.isNotEmpty) _actionOptions.add(action);
      final uid = '${r['adminUid'] ?? ''}';
      if (uid.isNotEmpty) _adminOptions.putIfAbsent(uid, () => _whoLabel(r));
    }
  }

  String _whoLabel(Map r) {
    final email = '${r['adminEmail'] ?? ''}';
    return email.isNotEmpty ? email : '${r['adminUid'] ?? 'system'}';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await _fetch();
      if (!mounted) return;
      final rows = ((resp['rows'] as List?) ?? const []).cast<Map>();
      _absorbOptions(rows);
      setState(() {
        _rows = rows;
        _nextCursor = resp['nextCursor'] as String?;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final resp = await _fetch(cursor: cursor);
      if (!mounted) return;
      final more = ((resp['rows'] as List?) ?? const []).cast<Map>();
      _absorbOptions(more);
      setState(() {
        _rows = [..._rows, ...more];
        _nextCursor = resp['nextCursor'] as String?;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load more: $e')));
    }
  }

  List<Map> get _visible {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _rows;
    return _rows.where((r) {
      return '${r['target'] ?? ''}'.toLowerCase().contains(q) ||
          '${r['reason'] ?? ''}'.toLowerCase().contains(q);
    }).toList();
  }

  /// Client-side CSV of what's currently loaded and visible (same approach as
  /// the Clients screen's "Export selected"). Web-only, like every CSV
  /// download in the panel.
  void _exportCsv() {
    const columns = ['when', 'adminEmail', 'adminUid', 'action', 'target', 'reason'];
    final buffer = StringBuffer(columns.join(','))..write('\n');
    for (final r in _visible) {
      buffer.write(columns.map((k) => _csvField(r[k])).join(','));
      buffer.write('\n');
    }
    try {
      downloadCsv('admin_audit_log.csv', buffer.toString());
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV export is only available on web.')),
      );
    }
  }

  String _csvField(Object? value) {
    final s = '${value ?? ''}';
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  /// Destructive/access-sensitive actions read louder than routine ones — the
  /// design's info / warn / danger tones, derived from the real action names
  /// (`admin_*`) rather than a hand-maintained list per action.
  Color _toneFor(String action) {
    final a = action.toLowerCase();
    if (a.contains('delete') || (a.contains('suspend') && !a.contains('unsuspend'))) return MM.red;
    if (a.contains('revoke') ||
        a.contains('reset') ||
        a.contains('force') ||
        a.contains('email') ||
        a.contains('claim') ||
        a.contains('flag') ||
        a.contains('config')) {
      return MM.yellow;
    }
    return Colors.white.withOpacity(0.6);
  }

  String _whenLabel(Object? iso) {
    final dt = DateTime.tryParse('${iso ?? ''}')?.toLocal();
    if (dt == null) return '—';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final rows = _visible;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('AUDIT LOG', style: MM.display(size: 16, color: MM.white)),
            const SizedBox(width: 12),
            Text('Every admin write, with reason',
                style: MM.body(size: 11.5, color: Colors.white.withOpacity(0.5))),
            const Spacer(),
            AdminRefreshButton(onTap: _load),
          ]),
          const SizedBox(height: 16),
          AdminPanel(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Append-only record of every admin action: who, what, when and the required reason. '
                'Nothing here can be edited or deleted, including by you.',
                style: MM.body(size: 12, color: Colors.white.withOpacity(0.6)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _searchCtrl,
                  style: MM.body(size: 12.5, color: MM.white),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 16, color: Colors.white38),
                    hintText: 'Search target or reason',
                    hintStyle: MM.body(size: 12, color: Colors.white.withOpacity(0.36)),
                    filled: true,
                    fillColor: MM.pageBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
                    ),
                  ),
                ),
              ),
              _dropdown<String>(
                _action,
                {for (final a in [_allActions, ..._actionOptions.toList()..sort()]) a: a},
                (v) {
                  setState(() => _action = v!);
                  _load();
                },
              ),
              _dropdown<String>(
                _admin,
                {_allAdmins: _allAdmins, ..._adminOptions},
                (v) {
                  setState(() => _admin = v!);
                  _load();
                },
              ),
              _dropdown<String>(
                _range,
                {for (final r in _ranges.keys) r: r},
                (v) {
                  setState(() => _range = v!);
                  _load();
                },
              ),
              OutlinedButton.icon(
                onPressed: rows.isEmpty ? null : _exportCsv,
                icon: const Icon(Icons.download, size: 14),
                label: const Text('Export log'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(child: _table(rows)),
        ],
      ),
    );
  }

  Widget _table(List<Map> rows) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: MM.blue));
    if (_error != null) return AdminErrorView(message: _error!, onRetry: _load);
    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: MM.navy,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              _head('WHEN', 2),
              _head('WHO', 3),
              _head('ACTION', 3),
              _head('TARGET', 3),
              _head('REASON', 4),
            ]),
          ),
          Expanded(
            child: rows.isEmpty
                ? Center(
                    child: Text(
                      _rows.isEmpty ? 'No audit entries in this range.' : 'No loaded entries match the search.',
                      style: MM.body(size: 12.5, color: Colors.white.withOpacity(0.5)),
                    ),
                  )
                : ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
                    itemBuilder: (context, i) {
                      final r = rows[i];
                      final action = '${r['action'] ?? ''}';
                      final who = '${r['adminEmail'] ?? ''}'.isNotEmpty
                          ? '${r['adminEmail']}'
                          : ('${r['adminUid'] ?? ''}'.isNotEmpty ? '${r['adminUid']}' : 'system');
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(
                            flex: 2,
                            child: Text(_whenLabel(r['when']), style: MM.mono(size: 11, color: Colors.white.withOpacity(0.5))),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(who, style: MM.body(size: 12, color: MM.white), overflow: TextOverflow.ellipsis),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(action, style: MM.mono(size: 11.5, color: _toneFor(action))),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text('${r['target'] ?? ''}',
                                style: MM.mono(size: 11, color: Colors.white.withOpacity(0.7)),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text('${r['reason'] ?? ''}',
                                style: MM.body(size: 12, color: Colors.white.withOpacity(0.6))),
                          ),
                        ]),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              Text(
                '${rows.length} shown · ${_rows.length} loaded · append-only, never edited',
                style: MM.mono(size: 10.5, color: Colors.white.withOpacity(0.36)),
              ),
              const Spacer(),
              if (_nextCursor != null)
                _loadingMore
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: MM.blue))
                    : InkWell(
                        onTap: _loadMore,
                        child: Text('Load more', style: MM.body(size: 12, color: MM.blue)),
                      ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _head(String label, int flex) => Expanded(
        flex: flex,
        child: Text(label, style: MM.displayX(size: 9, color: Colors.white.withOpacity(0.36))),
      );

  Widget _dropdown<T>(T value, Map<T, String> options, ValueChanged<T?> onChanged) {
    // A filter value that's no longer in the (re)built option list would trip
    // DropdownButton's assertion — fall back to the first option instead.
    final safe = options.containsKey(value) ? value : options.keys.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: MM.pageBg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: safe,
          dropdownColor: MM.navy,
          isDense: true,
          style: MM.body(size: 12, color: Colors.white.withOpacity(0.8)),
          items: options.entries
              .map((e) => DropdownMenuItem<T>(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
