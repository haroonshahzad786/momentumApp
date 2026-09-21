import 'package:flutter/material.dart';

import '../../services/admin_api_service.dart';
import '../../services/csv_download.dart';
import '../../theme/momentum_tokens.dart';
import 'admin_widgets.dart';

/// §5 Momentum lists — the honest subset of the design, backed by
/// `adminListMomentumLists` (#A5.1) and `adminGetListDetail` (#A5.4).
///
/// Real: one row per distinct list type across BOTH real stores (free-text
/// `momentum_lists` and the per-core `golden_habit` / `pain_point` lists), with
/// players-with-list, initiated (≥1 item) and average items; and a per-list
/// player table that deep-links into Client Detail.
///
/// NOT shown, on purpose (#A5.2/#A5.3/#A5.5 — see the on-screen note): "completed",
/// "completion rate", the "where players stop" funnel, the rate-over-time trend
/// and per-prompt answer rates. They all assume a fixed prompt set per list type,
/// which does not exist — lists are free-form item arrays — so those numbers
/// would be guessed, not measured. "Edit prompts" is likewise not offered: there
/// are no prompts to edit.
const _kCoreShort = {
  'mindset_core': 'mindset',
  'career_finance_core': 'career',
  'physical_health_core': 'physical',
  'emotional_mental_core': 'emotional',
  'relationships_core': 'relationships',
};
const _kCoreLabel = {
  'mindset': 'Mindset',
  'career': 'Career',
  'physical': 'Physical',
  'emotional': 'Emotional',
  'relationships': 'Relationships',
};

class AdminListsScreen extends StatefulWidget {
  const AdminListsScreen({super.key, required this.onOpenClient});

  /// Opens the player in Client Detail (the design's per-player "View").
  final void Function(String uid) onOpenClient;

  @override
  State<AdminListsScreen> createState() => _AdminListsScreenState();
}

class _AdminListsScreenState extends State<AdminListsScreen> {
  final _api = AdminApiService();
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;
  List<Map> _lists = const [];
  String _systemFilter = 'All lists';

  Map? _open; // the list row whose detail is showing

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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _api.listMomentumLists();
      if (!mounted) return;
      final lists = ((r['lists'] as List?) ?? const []).cast<Map>().toList()
        ..sort((a, b) {
          final byPlayers = _n(b['usersWithList']).compareTo(_n(a['usersWithList']));
          return byPlayers != 0 ? byPlayers : '${a['name']}'.compareTo('${b['name']}');
        });
      setState(() {
        _lists = lists;
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

  int _n(Object? v) => v is num ? v.toInt() : 0;

  String _coreShort(Map l) => _kCoreShort['${l['coreId'] ?? ''}'] ?? '';

  List<Map> get _visible {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _lists.where((l) {
      final sys = '${l['system']}';
      if (_systemFilter == 'Momentum lists' && sys != 'momentum') return false;
      if (_systemFilter == 'Per-core lists' && sys != 'core') return false;
      if (q.isNotEmpty && !'${l['name']}'.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  void _exportCsv() {
    const columns = ['system', 'name', 'coreId', 'categoryId', 'usersWithList', 'initiated', 'avgItems'];
    _download('momentum_lists.csv', columns, _visible);
  }

  void _download(String file, List<String> columns, List<Map> rows) {
    final buffer = StringBuffer(columns.join(','))..write('\n');
    for (final r in rows) {
      buffer.write(columns.map((k) => _csvField(r[k])).join(','));
      buffer.write('\n');
    }
    try {
      downloadCsv(file, buffer.toString());
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

  @override
  Widget build(BuildContext context) {
    final open = _open;
    if (open != null) {
      return _ListDetailView(
        list: open,
        api: _api,
        onBack: () => setState(() => _open = null),
        onOpenClient: widget.onOpenClient,
        onExport: _download,
      );
    }
    if (_loading) return const Center(child: CircularProgressIndicator(color: MM.blue));
    if (_error != null) return AdminErrorView(message: _error!, onRetry: _load);

    final rows = _visible;
    final startedTotal = _lists.fold<int>(0, (a, l) => a + _n(l['initiated']));
    final playerSlots = _lists.fold<int>(0, (a, l) => a + _n(l['usersWithList']));
    final avgAll = playerSlots == 0
        ? 0.0
        : _lists.fold<double>(0, (a, l) => a + (l['avgItems'] as num? ?? 0) * _n(l['usersWithList'])) / playerSlots;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('MOMENTUM LISTS', style: MM.display(size: 16, color: MM.white)),
            const SizedBox(width: 12),
            Text('${_lists.length} list types · momentum_lists + per-core lists',
                style: MM.body(size: 11.5, color: Colors.white.withOpacity(0.5))),
            const Spacer(),
            AdminRefreshButton(onTap: _load),
          ]),
          const SizedBox(height: 16),
          Wrap(spacing: 14, runSpacing: 14, children: [
            _tile('LIST TYPES', '${_lists.length}', 'distinct names across both stores'),
            _tile('LISTS STARTED', '$startedTotal', 'player-lists with at least one item'),
            _tile('AVG ITEMS / LIST', avgAll.toStringAsFixed(1), 'weighted by players'),
          ]),
          const SizedBox(height: 14),
          AdminPanel(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.info_outline, size: 16, color: MM.yellow),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Completion rate, "where players stop" and per-prompt answer rates are not shown: lists are '
                    'free-form item arrays with no fixed prompt set per list type, so "completed" has no measurable '
                    'definition yet — showing those numbers would be guessing. They need a schema decision first '
                    '(e.g. a canonical prompt count per list name).',
                    style: MM.body(size: 12, color: Colors.white.withOpacity(0.6)),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
            SizedBox(
              width: 260,
              child: TextField(
                controller: _searchCtrl,
                style: MM.body(size: 12.5, color: MM.white),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 16, color: Colors.white38),
                  hintText: 'Search list name',
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
            _dropdown(_systemFilter, const ['All lists', 'Momentum lists', 'Per-core lists'],
                (v) => setState(() => _systemFilter = v!)),
            OutlinedButton.icon(
              onPressed: rows.isEmpty ? null : _exportCsv,
              icon: const Icon(Icons.download, size: 14),
              label: const Text('Export CSV'),
            ),
          ]),
          const SizedBox(height: 14),
          _table(rows),
        ],
      ),
    );
  }

  Widget _tile(String label, String value, String sub) => SizedBox(
        width: 260,
        child: AdminPanel(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: MM.displayX(size: 9, color: Colors.white.withOpacity(0.36))),
              const SizedBox(height: 8),
              Text(value, style: MM.display(size: 24, color: MM.white)),
              const SizedBox(height: 4),
              Text(sub, style: MM.body(size: 11, color: Colors.white.withOpacity(0.45))),
            ]),
          ),
        ),
      );

  Widget _table(List<Map> rows) {
    return AdminPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          color: MM.navy,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            _head('LIST TYPE', 4),
            _head('CORE', 2),
            _head('PLAYERS', 1),
            _head('INITIATED', 1),
            _head('AVG ITEMS', 1),
            _head('INITIATED SHARE', 3),
            const SizedBox(width: 24),
          ]),
        ),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: Text(_lists.isEmpty ? 'No lists exist yet.' : 'No lists match.',
                  style: MM.body(size: 12.5, color: Colors.white.withOpacity(0.5))),
            ),
          )
        else
          for (final l in rows) ...[
            _row(l),
            const Divider(height: 1, color: Colors.white12),
          ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text('${rows.length} of ${_lists.length} list types',
              style: MM.mono(size: 10.5, color: Colors.white.withOpacity(0.36))),
        ),
      ]),
    );
  }

  Widget _row(Map l) {
    final core = _coreShort(l);
    final players = _n(l['usersWithList']);
    final initiated = _n(l['initiated']);
    final share = players == 0 ? 0.0 : initiated / players;
    final isCore = '${l['system']}' == 'core';
    return InkWell(
      onTap: () => setState(() => _open = l),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(children: [
          Expanded(
            flex: 4,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${l['name']}', style: MM.body(size: 12.5, color: MM.white), overflow: TextOverflow.ellipsis),
              Text(isCore ? 'per-core · ${l['categoryId'] ?? ''}' : 'momentum list',
                  style: MM.mono(size: 10, color: Colors.white.withOpacity(0.36))),
            ]),
          ),
          Expanded(
            flex: 2,
            child: core.isEmpty
                ? Text('—', style: MM.body(size: 12, color: Colors.white.withOpacity(0.36)))
                : Row(children: [
                    Container(width: 7, height: 7, decoration: BoxDecoration(color: MM.coreColor[core], shape: BoxShape.circle)),
                    const SizedBox(width: 7),
                    Text(_kCoreLabel[core]!, style: MM.body(size: 12, color: Colors.white.withOpacity(0.75))),
                  ]),
          ),
          Expanded(flex: 1, child: Text('$players', style: MM.mono(size: 12))),
          Expanded(flex: 1, child: Text('$initiated', style: MM.mono(size: 12))),
          Expanded(flex: 1, child: Text('${l['avgItems'] ?? 0}', style: MM.mono(size: 12, color: Colors.white.withOpacity(0.7)))),
          Expanded(
            flex: 3,
            child: Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: share,
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation(share >= 0.999 ? MM.teal : MM.blue),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(width: 38, child: Text('${(share * 100).round()}%', style: MM.mono(size: 11.5))),
            ]),
          ),
          const SizedBox(width: 24, child: Icon(Icons.chevron_right, size: 16, color: Colors.white38)),
        ]),
      ),
    );
  }

  Widget _head(String label, int flex) => Expanded(
        flex: flex,
        child: Text(label, style: MM.displayX(size: 9, color: Colors.white.withOpacity(0.36))),
      );

  Widget _dropdown(String value, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: MM.pageBg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: MM.navy,
          isDense: true,
          style: MM.body(size: 12, color: Colors.white.withOpacity(0.8)),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Detail ─────────────────────────────────────────────────────────────

class _ListDetailView extends StatefulWidget {
  const _ListDetailView({
    required this.list,
    required this.api,
    required this.onBack,
    required this.onOpenClient,
    required this.onExport,
  });

  final Map list;
  final AdminApiService api;
  final VoidCallback onBack;
  final void Function(String uid) onOpenClient;
  final void Function(String file, List<String> columns, List<Map> rows) onExport;

  @override
  State<_ListDetailView> createState() => _ListDetailViewState();
}

class _ListDetailViewState extends State<_ListDetailView> {
  bool _loading = true;
  String? _error;
  Map _summary = const {};
  List<Map> _players = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final l = widget.list;
      final r = await widget.api.getListDetail(
        system: '${l['system']}',
        name: '${l['name']}',
        coreId: '${l['system']}' == 'core' ? '${l['coreId'] ?? ''}' : null,
        categoryId: '${l['system']}' == 'core' ? '${l['categoryId'] ?? ''}' : null,
      );
      if (!mounted) return;
      setState(() {
        _summary = (r['list'] as Map?) ?? const {};
        _players = ((r['players'] as List?) ?? const []).cast<Map>();
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

  String _updated(Object? iso) {
    final s = '${iso ?? ''}';
    return s.isEmpty ? '—' : adminShortWhen(s);
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.list;
    final core = _kCoreShort['${l['coreId'] ?? ''}'] ?? '';
    final isCore = '${l['system']}' == 'core';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: widget.onBack,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.chevron_left, size: 16, color: MM.blue),
            Text('All momentum lists', style: MM.body(size: 12, color: MM.blue)),
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: [
          if (core.isNotEmpty) ...[
            Container(width: 4, height: 34, decoration: BoxDecoration(color: MM.coreColor[core], borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${l['name']}', style: MM.display(size: 16, color: MM.white)),
              const SizedBox(height: 4),
              Text(
                [
                  isCore ? 'per-core list' : 'momentum list',
                  if (core.isNotEmpty) _kCoreLabel[core]!,
                  if (isCore && '${l['categoryId'] ?? ''}'.isNotEmpty) '${l['categoryId']}',
                ].join(' · '),
                style: MM.mono(size: 11, color: Colors.white.withOpacity(0.45)),
              ),
            ]),
          ),
          OutlinedButton.icon(
            onPressed: _players.isEmpty
                ? null
                : () => widget.onExport(
                      'list_${'${l['name']}'.replaceAll(RegExp(r'\W+'), '_')}.csv',
                      const ['uid', 'displayName', 'itemCount', 'updatedAt'],
                      _players,
                    ),
            icon: const Icon(Icons.download, size: 14),
            label: const Text('Export CSV'),
          ),
        ]),
        const SizedBox(height: 16),
        if (_loading)
          const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: MM.blue)))
        else if (_error != null)
          AdminErrorView(message: _error!, onRetry: _load)
        else ...[
          Wrap(spacing: 14, runSpacing: 14, children: [
            _stat('PLAYERS WITH LIST', '${_summary['usersWithList'] ?? 0}'),
            _stat('INITIATED', '${_summary['initiated'] ?? 0}'),
            _stat('AVG ITEMS', '${_summary['avgItems'] ?? 0}'),
          ]),
          const SizedBox(height: 14),
          AdminPanel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                color: MM.navy,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  _head('PLAYER', 4),
                  _head('ITEMS', 1),
                  _head('LAST UPDATED', 2),
                  const SizedBox(width: 60),
                ]),
              ),
              if (_players.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Center(child: Text('No players have this list.', style: MM.body(size: 12.5, color: Colors.white.withOpacity(0.5)))),
                )
              else
                for (final p in _players) ...[
                  InkWell(
                    onTap: () => widget.onOpenClient('${p['uid']}'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      child: Row(children: [
                        Expanded(
                          flex: 4,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${p['displayName']}', style: MM.body(size: 12.5, color: MM.white), overflow: TextOverflow.ellipsis),
                            Text('${p['uid']}', style: MM.mono(size: 10, color: Colors.white.withOpacity(0.36)), overflow: TextOverflow.ellipsis),
                          ]),
                        ),
                        Expanded(flex: 1, child: Text('${p['itemCount']}', style: MM.mono(size: 12))),
                        Expanded(flex: 2, child: Text(_updated(p['updatedAt']), style: MM.mono(size: 11, color: Colors.white.withOpacity(0.5)))),
                        SizedBox(
                          width: 60,
                          child: Text('View', textAlign: TextAlign.right, style: MM.body(size: 12, color: MM.blue)),
                        ),
                      ]),
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white12),
                ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  '${_players.length} player${_players.length == 1 ? '' : 's'} · per-prompt answer rates are not shown (lists have no fixed prompts)',
                  style: MM.mono(size: 10.5, color: Colors.white.withOpacity(0.36)),
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _stat(String label, String value) => SizedBox(
        width: 200,
        child: AdminPanel(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: MM.displayX(size: 9, color: Colors.white.withOpacity(0.36))),
              const SizedBox(height: 6),
              Text(value, style: MM.display(size: 20, color: MM.white)),
            ]),
          ),
        ),
      );

  Widget _head(String label, int flex) => Expanded(
        flex: flex,
        child: Text(label, style: MM.displayX(size: 9, color: Colors.white.withOpacity(0.36))),
      );
}
