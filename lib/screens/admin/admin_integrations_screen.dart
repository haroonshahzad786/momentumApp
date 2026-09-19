import 'package:flutter/material.dart';

import '../../services/admin_api_service.dart';
import '../../theme/momentum_tokens.dart';
import 'admin_widgets.dart';

/// §6 Integrations — still an honest partial: the design's full connection
/// card (API key reveal/rotate, model + prompt version history) isn't
/// built (#A6.3/#A6.4, and #A0.6-adjacent secret-reveal auditing for the key
/// itself), so the nav row keeps its "soon" tag. What IS real here is
/// #A6.2 — a genuine round-trip health check against the Claude API, not a
/// static "Connected" badge.
class AdminIntegrationsScreen extends StatefulWidget {
  const AdminIntegrationsScreen({super.key});

  @override
  State<AdminIntegrationsScreen> createState() => _AdminIntegrationsScreenState();
}

class _AdminIntegrationsScreenState extends State<AdminIntegrationsScreen> {
  final _api = AdminApiService();
  bool _testing = false;
  Map<String, dynamic>? _result;

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
                  'Claude API (Nova). The full connection card — API key reveal/rotate, model + '
                  'prompt version history — isn\'t built yet. "Test connection" below is real, though: '
                  'a live round-trip against the Claude API, not a static badge.',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
