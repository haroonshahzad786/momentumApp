import 'package:flutter/material.dart';

import '../../services/admin_api_service.dart';
import '../../theme/momentum_tokens.dart';
import 'admin_widgets.dart';

const _kCoreLabels = {
  'mindset': 'Mindset',
  'career': 'Career',
  'relationships': 'Relationships',
  'physical': 'Physical',
  'emotional': 'Emotional',
};

/// §10 Analytics — #A10.4 only. The design also shows an economy-anomaly
/// banner, a DAU/WAU chart, a retention cohort grid, and a Phase-1 funnel
/// (#A10.1-3) — none of that is built, because it needs a real event ledger
/// + BigQuery export that doesn't exist yet, not because it was skipped.
/// Each of those sections renders an honest "not built yet" panel instead of
/// a fabricated chart with invented numbers.
class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final _api = AdminApiService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

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
      final resp = await _api.getAnalytics();
      if (!mounted) return;
      setState(() => _data = resp);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: MM.blue));
    }
    if (_error != null) {
      return AdminErrorView(message: _error!, onRetry: _load);
    }
    final data = _data!;
    final habitsByCore = ((data['habitsByCore'] as List?) ?? const []).cast<Map>();
    final points = (data['points'] as Map?) ?? const {};
    final credits = (data['credits'] as Map?) ?? const {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('ANALYTICS', style: MM.display(size: 16, color: MM.white)),
            const SizedBox(width: 12),
            AdminRefreshButton(onTap: _load),
          ]),
          const SizedBox(height: 16),
          _needsSpecPanel('Economy anomaly banner', data['economyAnomaly'],
              'Needs #A7.3\'s config-version history correlated against a real event stream — not built.'),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _needsSpecCard('DAU / WAU', data['dauWau']),
            const SizedBox(width: 14),
            _needsSpecCard('Retention cohorts', data['retention']),
            const SizedBox(width: 14),
            _needsSpecCard('Phase-1 funnel', data['phase1Funnel']),
          ]),
          const SizedBox(height: 22),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _habitsByCorePanel(habitsByCore)),
            const SizedBox(width: 14),
            Expanded(child: _issuedVsSpentPanel(points, credits, '${data['spentCaveat'] ?? ''}')),
          ]),
        ],
      ),
    );
  }

  Widget _needsSpecPanel(String title, Object? section, String note) {
    final needsSpec = section is Map && section['needsSpec'] == true;
    if (!needsSpec) return const SizedBox.shrink();
    return AdminPanel(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.hourglass_empty, size: 16, color: Colors.white38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: MM.display(size: 12, color: Colors.white.withOpacity(0.7))),
              const SizedBox(height: 3),
              Text(note, style: MM.body(size: 11.5, color: Colors.white.withOpacity(0.45))),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _needsSpecCard(String title, Object? section) {
    return Expanded(
      child: AdminPanel(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(title, style: MM.displayX(size: 10, color: Colors.white.withOpacity(0.5))),
            const SizedBox(height: 8),
            Text('Not built yet', style: MM.display(size: 13, color: Colors.white38)),
            const SizedBox(height: 4),
            Text('Needs #A10.1\'s event ledger.', style: MM.body(size: 11, color: Colors.white.withOpacity(0.35))),
          ]),
        ),
      ),
    );
  }

  Widget _habitsByCorePanel(List<Map> rows) {
    final maxAssigned = rows.fold<int>(1, (m, r) => (r['assigned'] as num? ?? 0).toInt() > m ? (r['assigned'] as num).toInt() : m);
    return AdminPanel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('HABITS BY CORE', style: MM.displayX(size: 11, color: Colors.white.withOpacity(0.6))),
          const SizedBox(height: 4),
          Text('Real Golden Habits — assigned vs. formed', style: MM.body(size: 11, color: Colors.white.withOpacity(0.4))),
          const SizedBox(height: 16),
          for (final r in rows) ...[
            _coreBarRow(
              label: _kCoreLabels['${r['core']}'] ?? '${r['core']}',
              color: MM.coreColor['${r['core']}'] ?? MM.blue,
              assigned: (r['assigned'] as num? ?? 0).toInt(),
              formed: (r['formed'] as num? ?? 0).toInt(),
              maxAssigned: maxAssigned,
            ),
            const SizedBox(height: 12),
          ],
        ]),
      ),
    );
  }

  Widget _coreBarRow({
    required String label,
    required Color color,
    required int assigned,
    required int formed,
    required int maxAssigned,
  }) {
    final assignedFrac = maxAssigned == 0 ? 0.0 : assigned / maxAssigned;
    final formedFrac = assigned == 0 ? 0.0 : formed / assigned;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(label, style: MM.body(size: 12.5, color: MM.white))),
        Text('$formed / $assigned formed', style: MM.mono(size: 11, color: Colors.white.withOpacity(0.5))),
      ]),
      const SizedBox(height: 5),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(children: [
          Container(height: 8, color: color.withOpacity(0.15)),
          FractionallySizedBox(
            widthFactor: assignedFrac.clamp(0.0, 1.0),
            child: Container(
              height: 8,
              color: color.withOpacity(0.35),
            ),
          ),
          FractionallySizedBox(
            widthFactor: (assignedFrac * formedFrac).clamp(0.0, 1.0),
            child: Container(height: 8, color: color),
          ),
        ]),
      ),
    ]);
  }

  Widget _issuedVsSpentPanel(Map points, Map credits, String caveat) {
    return AdminPanel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('MP / CREDITS — ISSUED VS. SPENT', style: MM.displayX(size: 11, color: Colors.white.withOpacity(0.6))),
          const SizedBox(height: 16),
          _issuedSpentRow('Momentum Points', points, MM.blue),
          const SizedBox(height: 16),
          _issuedSpentRow('Space Credits', credits, MM.teal),
          if (caveat.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline, size: 13, color: MM.yellow),
              const SizedBox(width: 8),
              Expanded(child: Text(caveat, style: MM.body(size: 11, color: Colors.white.withOpacity(0.45)))),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _issuedSpentRow(String label, Map data, Color color) {
    final issued = (data['issued'] as num? ?? 0).toInt();
    final spent = (data['spent'] as num? ?? 0).toInt();
    final total = issued + spent;
    final issuedFrac = total == 0 ? 1.0 : issued / total;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(label, style: MM.body(size: 12.5, color: MM.white))),
        Text('+$issued', style: MM.mono(size: 11.5, color: color)),
        const SizedBox(width: 8),
        Text('−$spent', style: MM.mono(size: 11.5, color: MM.red)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Row(children: [
          Expanded(flex: (issuedFrac * 1000).round().clamp(1, 1000), child: Container(height: 8, color: color)),
          if (spent > 0)
            Expanded(
              flex: ((1 - issuedFrac) * 1000).round().clamp(1, 1000),
              child: Container(height: 8, color: MM.red),
            ),
        ]),
      ),
    ]);
  }
}
