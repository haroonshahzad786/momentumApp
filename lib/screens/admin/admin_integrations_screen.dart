import 'package:flutter/material.dart';

import '../../services/admin_api_service.dart';
import '../../theme/momentum_tokens.dart';
import 'admin_widgets.dart';

/// §6 Integrations — still an honest partial: the design's full connection
/// card (API key reveal/rotate) isn't built (#A6.1's admin-facing half, and
/// #A0.6-adjacent secret-reveal auditing for the key itself), and
/// "Disconnect" (#A6.4) is intentionally not wired — its semantics need a
/// client decision before anything guesses at a destructive action. What IS
/// real: #A6.2 (a genuine round-trip health check against the Claude API,
/// not a static "Connected" badge) and #A6.3 (model + prompt version
/// history, below).
class AdminIntegrationsScreen extends StatefulWidget {
  const AdminIntegrationsScreen({super.key});

  @override
  State<AdminIntegrationsScreen> createState() => _AdminIntegrationsScreenState();
}

class _AdminIntegrationsScreenState extends State<AdminIntegrationsScreen> {
  final _api = AdminApiService();
  bool _testing = false;
  Map<String, dynamic>? _result;

  bool _historyLoading = true;
  String? _historyError;
  Map<String, dynamic>? _historyResult;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _result = null;
    });
    try {
      final result = await _api.testAiConnection();
      if (!mounted) return;
      setState(() => _result = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _result = {'connected': false, 'error': '$e'});
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _historyLoading = true;
      _historyError = null;
    });
    try {
      final result = await _api.getNovaConfigHistory();
      if (!mounted) return;
      setState(() => _historyResult = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _historyError = '$e');
    } finally {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final connected = _result?['connected'] == true;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Align(
        alignment: Alignment.topLeft,
        child: AdminPanel(
          width: 620,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('INTEGRATIONS', style: MM.display(size: 14, color: MM.white)),
                const SizedBox(height: 10),
                Text(
                  'Claude API (Nova). API key reveal/rotate and "Disconnect" aren\'t built yet '
                  '(the latter needs a client decision on what it should actually do). '
                  '"Test connection" is a live round-trip against the Claude API, not a static badge.',
                  style: MM.body(size: 12.5, color: Colors.white.withOpacity(0.6)),
                ),
                const SizedBox(height: 18),
                Row(children: [
                  ElevatedButton(
                    onPressed: _testing ? null : _testConnection,
                    style: ElevatedButton.styleFrom(backgroundColor: MM.blue),
                    child: _testing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Test connection'),
                  ),
                  if (_result != null) ...[
                    const SizedBox(width: 14),
                    Icon(connected ? Icons.check_circle : Icons.error, size: 16, color: connected ? MM.teal : MM.red),
                    const SizedBox(width: 6),
                    Text(
                      connected ? 'Connected' : 'Not connected',
                      style: MM.body(size: 12.5, color: connected ? MM.teal : MM.red, weight: FontWeight.w600),
                    ),
                    if (_result?['latencyMs'] != null) ...[
                      const SizedBox(width: 8),
                      Text('${_result!['latencyMs']}ms', style: MM.mono(size: 11, color: Colors.white.withOpacity(0.5))),
                    ],
                  ],
                ]),
                if (_result?['error'] != null) ...[
                  const SizedBox(height: 8),
                  Text('${_result!['error']}', style: MM.body(size: 11, color: Colors.white.withOpacity(0.5))),
                ],
                const SizedBox(height: 28),
                Divider(color: Colors.white.withOpacity(0.08)),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('MODEL + PROMPT HISTORY', style: MM.display(size: 12, color: MM.white)),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 16, color: Colors.white54),
                      onPressed: _historyLoading ? null : _loadHistory,
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_historyLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                    ),
                  )
                else if (_historyError != null)
                  Text(_historyError!, style: MM.body(size: 11.5, color: MM.red))
                else if (_historyResult != null)
                  _NovaHistoryList(result: _historyResult!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders #A6.3's `{ current, history }` payload. `current` is shown first
/// (even if it's also the newest row in `history`, which it always is once
/// logged); each history row shows when that (model, prompt) pair was FIRST
/// seen — this is a version log, not a per-request audit trail.
class _NovaHistoryList extends StatelessWidget {
  const _NovaHistoryList({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final current = (result['current'] as Map?)?.cast<String, dynamic>();
    final history = asMapList(result['history']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (current != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: MM.teal.withOpacity(0.08),
              border: Border.all(color: MM.teal.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 14, color: MM.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${current['model']}  ·  prompt ${current['promptChars']} chars  ·  hash ${current['promptHash']}',
                    style: MM.mono(size: 11, color: Colors.white.withOpacity(0.85)),
                  ),
                ),
                Text('LIVE', style: MM.body(size: 10, color: MM.teal, weight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (history.isEmpty)
          Text(
            'No prior versions logged yet — this is the first (model, prompt) pair detected.',
            style: MM.body(size: 11.5, color: Colors.white.withOpacity(0.5)),
          )
        else
          ...history.map((row) {
            final isCurrent = row['current'] == true;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isCurrent ? MM.teal : Colors.white24,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatTimestamp(row['firstSeenAt'] as String?),
                    style: MM.mono(size: 11, color: Colors.white.withOpacity(0.55)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${row['model']}  ·  ${row['promptChars']} chars  ·  ${row['promptHash']}',
                      style: MM.mono(size: 11, color: Colors.white.withOpacity(0.75)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  String _formatTimestamp(String? iso) {
    if (iso == null) return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '—';
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }
}
