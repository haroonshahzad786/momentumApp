import 'package:flutter/material.dart';

import '../../services/admin_api_service.dart';
import '../../theme/momentum_tokens.dart';
import 'admin_widgets.dart';

/// §1 Overview — 5 real stat tiles + recent admin actions, backed by
/// `adminGetOverview`. Content only; hosted inside [AdminShell].
class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  final _api = AdminApiService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _overview;

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
      final overview = await _api.getOverview();
      if (!mounted) return;
      setState(() {
        _overview = overview;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: MM.blue));
    if (_error != null) return AdminErrorView(message: _error!, onRetry: _load);

    final tiles = (_overview?['tiles'] as Map?) ?? const {};
    final recent = (_overview?['recentActions'] as List?) ?? const [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('OVERVIEW', style: MM.display(size: 16, color: MM.white)),
            const Spacer(),
            AdminRefreshButton(onTap: _load),
          ]),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _tile('Active clients', tiles['activeClients'], MM.teal),
              _tile('Checked in today', tiles['checkedInToday'], MM.teal),
              _tile('Avg score today', tiles['avgScoreToday'], MM.yellow),
              _tile('Credits spent (7d)', tiles['creditsSpent'], MM.red),
              _tile('Habits formed', tiles['habitsFormed'], MM.teal),
            ],
          ),
          const SizedBox(height: 28),
          Text('RECENT ADMIN ACTIONS', style: MM.displayX(size: 11, color: Colors.white.withOpacity(0.6))),
          const SizedBox(height: 10),
          AdminPanel(
            child: recent.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('No admin actions recorded yet.', style: MM.body(size: 12.5, color: Colors.white.withOpacity(0.5))),
                  )
                : Column(
                    children: recent.map<Widget>((r) {
                      final m = r as Map;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(children: [
                          Expanded(
                            flex: 3,
                            child: Text('${m['what'] ?? ''}', style: MM.body(size: 12.5, color: MM.white), overflow: TextOverflow.ellipsis),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text('${m['target'] ?? ''}', style: MM.body(size: 11.5, color: Colors.white.withOpacity(0.6)), overflow: TextOverflow.ellipsis),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('${m['who'] ?? ''}', style: MM.body(size: 11, color: Colors.white.withOpacity(0.6)), overflow: TextOverflow.ellipsis),
                          ),
                          Text(adminShortWhen('${m['when'] ?? ''}'), style: MM.mono(size: 10, color: Colors.white.withOpacity(0.36))),
                        ]),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tile(String label, dynamic tileData, Color accent) {
    final value = tileData is Map ? tileData['value'] : null;
    return AdminPanel(
      width: 176,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: MM.displayX(size: 9, color: Colors.white.withOpacity(0.55))),
            const SizedBox(height: 8),
            Text('${value ?? '—'}', style: MM.mono(size: 22, color: accent)),
          ],
        ),
      ),
    );
  }
}
