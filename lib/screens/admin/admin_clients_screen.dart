import 'package:flutter/material.dart';

import '../../services/admin_api_service.dart';
import '../../theme/momentum_tokens.dart';
import 'admin_widgets.dart';

/// §2 Clients list — real, searchable/filterable table backed by
/// `adminListClients`. At today's real scale (a few dozen accounts) this
/// fetches one page of up to 100 and does search/level/status filtering
/// client-side rather than round-tripping the server per keystroke; revisit
/// with server-side filtering once the account count actually needs
/// pagination (the backend already supports search/level/cursor server-side
/// for when that day comes).
class AdminClientsScreen extends StatefulWidget {
  const AdminClientsScreen({super.key, required this.onOpenClient});
  final void Function(String uid) onOpenClient;

  @override
  State<AdminClientsScreen> createState() => _AdminClientsScreenState();
}

class _AdminClientsScreenState extends State<AdminClientsScreen> {
  final _api = AdminApiService();
  final _searchCtrl = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map> _all = const [];
  String _levelFilter = 'All levels';
  String _statusFilter = 'Any status';
  final Set<String> _selected = {};

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
      final resp = await _api.listClients(limit: 100);
      if (!mounted) return;
      setState(() {
        _all = ((resp['rows'] as List?) ?? const []).cast<Map>();
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

  List<Map> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _all.where((c) {
      if (q.isNotEmpty) {
        final hay = '${c['displayName']} ${c['email']} ${c['uid']}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      if (_levelFilter != 'All levels' && c['level'] != _levelFilter) return false;
      if (_statusFilter != 'Any status' && c['status'] != _statusFilter) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: MM.blue));
    if (_error != null) return AdminErrorView(message: _error!, onRetry: _load);

    final rows = _filtered;
    final levels = {'All levels', ..._all.map((c) => '${c['level']}')}.toList();
    final statuses = {'Any status', ..._all.map((c) => '${c['status']}')}.toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('CLIENTS', style: MM.display(size: 16, color: MM.white)),
            const SizedBox(width: 12),
            Text('${_all.length} accounts · users/{uid} in Firestore',
                style: MM.body(size: 11.5, color: Colors.white.withOpacity(0.5))),
            const Spacer(),
            AdminRefreshButton(onTap: _load),
          ]),
          const SizedBox(height: 16),
          AdminPanel(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Every account in the app. Search by name, email or uid. Click a row to open the full record.',
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
                    hintText: 'Name, email or uid',
                    hintStyle: MM.body(size: 12, color: Colors.white.withOpacity(0.36)),
                    filled: true,
                    fillColor: MM.pageBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide(color: Colors.white.withOpacity(0.18))),
                  ),
                ),
              ),
              _dropdown(_levelFilter, levels, (v) => setState(() => _levelFilter = v!)),
              _dropdown(_statusFilter, statuses, (v) => setState(() => _statusFilter = v!)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => adminShowSoon(context, 'Export CSV'),
                icon: const Icon(Icons.download, size: 14),
                label: const Text('Export CSV'),
              ),
              ElevatedButton.icon(
                onPressed: () => adminShowSoon(context, 'Add client'),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add client'),
                style: ElevatedButton.styleFrom(backgroundColor: MM.blue),
              ),
            ],
          ),
          if (_selected.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [
              Text('${_selected.length} selected', style: MM.body(size: 12, color: MM.white, weight: FontWeight.w600)),
              const SizedBox(width: 14),
              for (final label in ['Send nudge', 'Grant credits', 'Assign habit', 'Send password reset', 'Export selected'])
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: InkWell(onTap: () => adminShowSoon(context, label), child: Text(label, style: MM.body(size: 12, color: MM.blue))),
                ),
            ]),
          ],
          const SizedBox(height: 14),
          Expanded(
            child: AdminPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: MM.navy,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(children: [
                      const SizedBox(width: 24),
                      _head('CLIENT', 3),
                      _head('LEVEL · PLANET', 2),
                      _head('STREAK', 1),
                      _head('MP', 1),
                      _head('CREDITS', 1),
                      _head('STATUS', 1),
                      const SizedBox(width: 60),
                    ]),
                  ),
                  Expanded(
                    child: rows.isEmpty
                        ? Center(child: Text('No clients match.', style: MM.body(size: 12.5, color: Colors.white.withOpacity(0.5))))
                        : ListView.separated(
                            itemCount: rows.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
                            itemBuilder: (context, i) {
                              final c = rows[i];
                              final uid = '${c['uid']}';
                              final label = ((c['displayName'] ?? '') as String).isNotEmpty
                                  ? c['displayName']
                                  : ((c['email'] ?? '') as String).isNotEmpty
                                      ? c['email']
                                      : uid;
                              return InkWell(
                                onTap: () => widget.onOpenClient(uid),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: Row(children: [
                                    SizedBox(
                                      width: 24,
                                      child: Checkbox(
                                        value: _selected.contains(uid),
                                        onChanged: (v) => setState(() {
                                          if (v == true) {
                                            _selected.add(uid);
                                          } else {
                                            _selected.remove(uid);
                                          }
                                        }),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('$label', style: MM.body(size: 12.5, color: MM.white), overflow: TextOverflow.ellipsis),
                                          if (((c['email'] ?? '') as String).isNotEmpty && c['displayName'] != c['email'])
                                            Text('${c['email']}', style: MM.body(size: 10.5, color: Colors.white.withOpacity(0.4)), overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                    Expanded(flex: 2, child: Text('${c['level']} · ${c['planet']}', style: MM.body(size: 11.5, color: Colors.white.withOpacity(0.6)))),
                                    Expanded(flex: 1, child: Text('${c['streak']}', style: MM.mono(size: 12))),
                                    Expanded(flex: 1, child: Text('${c['momentumScore']}', style: MM.mono(size: 12))),
                                    Expanded(flex: 1, child: Text('${c['spaceCredits']}', style: MM.mono(size: 12, color: MM.yellow))),
                                    Expanded(flex: 1, child: AdminStatusChip(status: '${c['status'] ?? ''}')),
                                    const SizedBox(
                                      width: 60,
                                      child: Icon(Icons.chevron_right, size: 16, color: Colors.white38),
                                    ),
                                  ]),
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text('1–${rows.length} of ${_all.length} · users/{uid}', style: MM.mono(size: 10.5, color: Colors.white.withOpacity(0.36))),
                  ),
                ],
              ),
            ),
          ),
        ],
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
