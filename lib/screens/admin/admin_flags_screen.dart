import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/admin_api_service.dart';
import '../../theme/momentum_tokens.dart';
import 'admin_widgets.dart';

/// §7 Feature flags + kill switches (#A7.6 / #A7.7) — reads `feature_flags/*`
/// straight from Firestore (world-readable per the §0 rules, live via a
/// snapshot stream) and writes ONLY through `adminSetFeatureFlag`, which
/// requires a reason and writes an audit-log entry with the before/after diff.
///
/// Regular-flag document shape (defined here — the backend merges any patch and
/// imposes no schema):
///   { description: String, platforms: { ios, android, web: bool },
///     cohort: String, rolloutPct: 0–100, updatedBy, updatedAt }
/// Kill switches are the same store: `maintenance_mode { enabled }` and
/// `force_update { enabled, minVersion }`.
///
/// HONEST CAVEAT, shown on screen: nothing in the player app reads
/// `feature_flags` yet, so changing a flag or a kill switch records the intent
/// and the audit trail but does not change client behavior until the client
/// gating is built.
const _kMaintenance = 'maintenance_mode';
const _kForceUpdate = 'force_update';
const _kKillSwitches = {_kMaintenance, _kForceUpdate};

class AdminFlagsScreen extends StatefulWidget {
  const AdminFlagsScreen({super.key});

  @override
  State<AdminFlagsScreen> createState() => _AdminFlagsScreenState();
}

class _AdminFlagsScreenState extends State<AdminFlagsScreen> {
  final _api = AdminApiService();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream =
      FirebaseFirestore.instance.collection('feature_flags').snapshots();

  Future<void> _save({
    required String key,
    required Map<String, dynamic> patch,
    required String reason,
    required String okMessage,
  }) async {
    try {
      await _api.setFeatureFlag(key: key, patch: patch, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(okMessage)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _editFlag({Map<String, dynamic>? existing, required Set<String> takenKeys}) async {
    final result = await showDialog<_FlagEdit>(
      context: context,
      builder: (_) => _FlagDialog(existing: existing, takenKeys: takenKeys),
    );
    if (result == null) return;
    await _save(
      key: result.key,
      patch: result.patch,
      reason: result.reason,
      okMessage: existing == null ? 'Flag "${result.key}" created.' : 'Flag "${result.key}" updated.',
    );
  }

  Future<void> _toggleKillSwitch(String key, Map<String, dynamic>? current, bool turnOn) async {
    final result = await showDialog<_KillEdit>(
      context: context,
      builder: (_) => _KillSwitchDialog(
        flagKey: key,
        turnOn: turnOn,
        currentMinVersion: '${current?['minVersion'] ?? ''}',
      ),
    );
    if (result == null) return;
    await _save(
      key: key,
      patch: {
        'enabled': turnOn,
        if (key == _kForceUpdate && result.minVersion != null) 'minVersion': result.minVersion,
      },
      reason: result.reason,
      okMessage: '$key turned ${turnOn ? 'ON' : 'OFF'}.',
    );
  }

  Future<void> _editMinVersion(Map<String, dynamic>? current) async {
    final result = await showDialog<_KillEdit>(
      context: context,
      builder: (_) => _KillSwitchDialog(
        flagKey: _kForceUpdate,
        turnOn: current?['enabled'] == true,
        currentMinVersion: '${current?['minVersion'] ?? ''}',
        minVersionOnly: true,
      ),
    );
    if (result == null || result.minVersion == null) return;
    await _save(
      key: _kForceUpdate,
      patch: {'minVersion': result.minVersion},
      reason: result.reason,
      okMessage: 'Minimum version set to ${result.minVersion}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return AdminErrorView(message: '${snap.error}', onRetry: () => setState(() {}));
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: MM.blue));

        final docs = {for (final d in snap.data!.docs) d.id: d.data()};
        final flags = docs.entries.where((e) => !_kKillSwitches.contains(e.key)).toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        final taken = docs.keys.toSet();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('FEATURE FLAGS', style: MM.display(size: 16, color: MM.white)),
                const SizedBox(width: 12),
                Text('Per-platform rollout control',
                    style: MM.body(size: 11.5, color: Colors.white.withOpacity(0.5))),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _editFlag(takenKeys: taken),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('New flag'),
                  style: ElevatedButton.styleFrom(backgroundColor: MM.blue),
                ),
              ]),
              const SizedBox(height: 16),
              AdminPanel(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.info_outline, size: 16, color: MM.yellow),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Turn features on per platform, target a cohort, and roll out by percentage. '
                        'Every change needs a reason and is written to the audit log. '
                        'Note: the player app does not read these flags yet, so a change is recorded '
                        'but does not alter client behavior until client-side gating is built.',
                        style: MM.body(size: 12, color: Colors.white.withOpacity(0.6)),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              _flagTable(flags, taken),
              const SizedBox(height: 22),
              _killSwitches(docs[_kMaintenance], docs[_kForceUpdate]),
            ],
          ),
        );
      },
    );
  }

  Widget _flagTable(List<MapEntry<String, Map<String, dynamic>>> flags, Set<String> taken) {
    return AdminPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          color: MM.navy,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            _head('FLAG', 4),
            _head('PLATFORMS', 3),
            _head('COHORT', 2),
            _head('ROLLOUT', 3),
            _head('LAST CHANGED BY', 3),
          ]),
        ),
        if (flags.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text('No feature flags yet — use "New flag" to create the first one.',
                  style: MM.body(size: 12.5, color: Colors.white.withOpacity(0.5))),
            ),
          )
        else
          for (final e in flags) ...[
            InkWell(
              onTap: () => _editFlag(existing: {...e.value, 'key': e.key}, takenKeys: taken),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(
                    flex: 4,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.key, style: MM.mono(size: 12.5, color: MM.white)),
                      if ('${e.value['description'] ?? ''}'.isNotEmpty)
                        Text('${e.value['description']}',
                            style: MM.body(size: 11, color: Colors.white.withOpacity(0.5))),
                    ]),
                  ),
                  Expanded(flex: 3, child: _platformChips(e.value['platforms'])),
                  Expanded(
                    flex: 2,
                    child: Text('${e.value['cohort'] ?? 'All clients'}',
                        style: MM.body(size: 12, color: Colors.white.withOpacity(0.7))),
                  ),
                  Expanded(flex: 3, child: _rollout(e.value['rolloutPct'])),
                  Expanded(
                    flex: 3,
                    child: Text(_changedBy(e.value),
                        style: MM.body(size: 11.5, color: Colors.white.withOpacity(0.5))),
                  ),
                ]),
              ),
            ),
            const Divider(height: 1, color: Colors.white12),
          ],
      ]),
    );
  }

  Widget _platformChips(Object? raw) {
    final p = raw is Map ? raw : const {};
    Widget chip(String label, bool on) => Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: (on ? MM.teal : Colors.white).withOpacity(on ? 0.16 : 0.05),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: (on ? MM.teal : Colors.white).withOpacity(on ? 0.4 : 0.12)),
          ),
          child: Text(label, style: MM.displayX(size: 8.5, color: on ? MM.teal : Colors.white.withOpacity(0.3))),
        );
    return Row(children: [
      chip('IOS', p['ios'] == true),
      chip('ANDROID', p['android'] == true),
      chip('WEB', p['web'] == true),
    ]);
  }

  Widget _rollout(Object? raw) {
    final pct = (raw is num ? raw.toInt() : 0).clamp(0, 100);
    return Row(children: [
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 6,
            backgroundColor: Colors.white.withOpacity(0.08),
            valueColor: const AlwaysStoppedAnimation(MM.blue),
          ),
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(width: 38, child: Text('$pct%', style: MM.mono(size: 11.5))),
    ]);
  }

  String _changedBy(Map<String, dynamic> d) {
    final by = '${d['updatedBy'] ?? ''}';
    if (by.isEmpty) return '—';
    final at = d['updatedAt'];
    if (at is! Timestamp) return by;
    final diff = DateTime.now().difference(at.toDate());
    final ago = diff.inDays >= 1
        ? '${diff.inDays}d ago'
        : diff.inHours >= 1
            ? '${diff.inHours}h ago'
            : '${diff.inMinutes.clamp(0, 59)}m ago';
    return '$by · $ago';
  }

  Widget _killSwitches(Map<String, dynamic>? maintenance, Map<String, dynamic>? forceUpdate) {
    final mOn = maintenance?['enabled'] == true;
    final fOn = forceUpdate?['enabled'] == true;
    final minVer = '${forceUpdate?['minVersion'] ?? ''}';
    return AdminPanel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('KILL SWITCHES', style: MM.displayX(size: 11, color: Colors.white.withOpacity(0.6))),
          const SizedBox(height: 14),
          _switchRow(
            name: _kMaintenance,
            blurb: 'All clients see the maintenance screen. Check-ins queue locally and sync on release.',
            on: mOn,
            missing: maintenance == null,
            onChanged: (v) => _toggleKillSwitch(_kMaintenance, maintenance, v),
          ),
          const Divider(height: 28, color: Colors.white12),
          _switchRow(
            name: _kForceUpdate,
            blurb: 'Blocks clients below the minimum version until they update.',
            on: fOn,
            missing: forceUpdate == null,
            onChanged: (v) => _toggleKillSwitch(_kForceUpdate, forceUpdate, v),
            extra: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Minimum version', style: MM.body(size: 11, color: Colors.white.withOpacity(0.5))),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _editMinVersion(forceUpdate),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: MM.pageBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Text(minVer.isEmpty ? 'not set' : minVer, style: MM.mono(size: 12)),
                ),
              ),
              const SizedBox(width: 14),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _switchRow({
    required String name,
    required String blurb,
    required bool on,
    required bool missing,
    required ValueChanged<bool> onChanged,
    Widget? extra,
  }) {
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: MM.mono(size: 13, color: MM.red)),
          const SizedBox(height: 4),
          Text(blurb, style: MM.body(size: 11.5, color: Colors.white.withOpacity(0.5))),
          if (missing)
            Text('Not seeded yet — the first toggle creates it.',
                style: MM.body(size: 10.5, color: Colors.white.withOpacity(0.36))),
        ]),
      ),
      if (extra != null) extra,
      Text(on ? 'ON' : 'off', style: MM.mono(size: 12, color: on ? MM.red : Colors.white.withOpacity(0.5))),
      const SizedBox(width: 8),
      Switch(value: on, activeColor: MM.red, onChanged: onChanged),
    ]);
  }

  Widget _head(String label, int flex) => Expanded(
        flex: flex,
        child: Text(label, style: MM.displayX(size: 9, color: Colors.white.withOpacity(0.36))),
      );
}

// ─── Dialogs ────────────────────────────────────────────────────────────

class _FlagEdit {
  const _FlagEdit(this.key, this.patch, this.reason);
  final String key;
  final Map<String, dynamic> patch;
  final String reason;
}

InputDecoration _dec(String hint) => InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: MM.body(size: 12, color: Colors.white.withOpacity(0.36)),
      filled: true,
      fillColor: MM.pageBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
      ),
    );

class _FlagDialog extends StatefulWidget {
  const _FlagDialog({required this.existing, required this.takenKeys});
  final Map<String, dynamic>? existing;
  final Set<String> takenKeys;

  @override
  State<_FlagDialog> createState() => _FlagDialogState();
}

class _FlagDialogState extends State<_FlagDialog> {
  static final _keyRe = RegExp(r'^[a-z][a-z0-9_]{1,39}$');

  late final _key = TextEditingController(text: '${widget.existing?['key'] ?? ''}');
  late final _desc = TextEditingController(text: '${widget.existing?['description'] ?? ''}');
  late final _cohort = TextEditingController(text: '${widget.existing?['cohort'] ?? 'All clients'}');
  final _reason = TextEditingController();
  late bool _ios;
  late bool _android;
  late bool _web;
  late double _pct;
  String? _error;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing?['platforms'];
    final m = p is Map ? p : const {};
    _ios = m['ios'] == true;
    _android = m['android'] == true;
    _web = m['web'] == true;
    final raw = widget.existing?['rolloutPct'];
    _pct = (raw is num ? raw.toDouble() : 0).clamp(0, 100).toDouble();
  }

  @override
  void dispose() {
    _key.dispose();
    _desc.dispose();
    _cohort.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final key = _key.text.trim();
    if (_isNew) {
      if (!_keyRe.hasMatch(key)) {
        setState(() => _error = 'Key: lowercase letters, digits, underscores (2–40 chars, starts with a letter).');
        return;
      }
      if (_kKillSwitches.contains(key) || widget.takenKeys.contains(key)) {
        setState(() => _error = 'A flag named "$key" already exists.');
        return;
      }
    }
    if (_reason.text.trim().isEmpty) {
      setState(() => _error = 'A reason is required — it goes in the audit log.');
      return;
    }
    Navigator.pop(
      context,
      _FlagEdit(
        key,
        {
          'description': _desc.text.trim(),
          'platforms': {'ios': _ios, 'android': _android, 'web': _web},
          'cohort': _cohort.text.trim().isEmpty ? 'All clients' : _cohort.text.trim(),
          'rolloutPct': _pct.round(),
        },
        _reason.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: MM.panel,
      title: Text(_isNew ? 'New feature flag' : 'Edit ${widget.existing!['key']}',
          style: MM.display(size: 14, color: MM.white)),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_isNew) ...[
              TextField(controller: _key, style: MM.mono(size: 12.5), decoration: _dec('flag_key')),
              const SizedBox(height: 10),
            ],
            TextField(controller: _desc, style: MM.body(size: 12.5, color: MM.white), decoration: _dec('What it gates')),
            const SizedBox(height: 12),
            Wrap(spacing: 14, children: [
              _check('iOS', _ios, (v) => setState(() => _ios = v)),
              _check('Android', _android, (v) => setState(() => _android = v)),
              _check('Web', _web, (v) => setState(() => _web = v)),
            ]),
            const SizedBox(height: 8),
            TextField(controller: _cohort, style: MM.body(size: 12.5, color: MM.white), decoration: _dec('Cohort (e.g. All clients)')),
            const SizedBox(height: 12),
            Row(children: [
              Text('Rollout', style: MM.body(size: 12, color: Colors.white.withOpacity(0.6))),
              Expanded(
                child: Slider(
                  value: _pct,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  activeColor: MM.blue,
                  onChanged: (v) => setState(() => _pct = v),
                ),
              ),
              SizedBox(width: 40, child: Text('${_pct.round()}%', style: MM.mono(size: 12))),
            ]),
            const SizedBox(height: 6),
            TextField(
              controller: _reason,
              maxLines: 2,
              style: MM.body(size: 12.5, color: MM.white),
              decoration: _dec('Reason (required — audit log)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: MM.body(size: 11.5, color: MM.red)),
            ],
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: MM.blue),
          child: Text(_isNew ? 'Create' : 'Save'),
        ),
      ],
    );
  }

  Widget _check(String label, bool v, ValueChanged<bool> on) => Row(mainAxisSize: MainAxisSize.min, children: [
        Checkbox(value: v, onChanged: (x) => on(x == true)),
        Text(label, style: MM.body(size: 12, color: Colors.white.withOpacity(0.8))),
      ]);
}

class _KillEdit {
  const _KillEdit(this.reason, this.minVersion);
  final String reason;
  final String? minVersion;
}

class _KillSwitchDialog extends StatefulWidget {
  const _KillSwitchDialog({
    required this.flagKey,
    required this.turnOn,
    required this.currentMinVersion,
    this.minVersionOnly = false,
  });
  final String flagKey;
  final bool turnOn;
  final String currentMinVersion;
  final bool minVersionOnly;

  @override
  State<_KillSwitchDialog> createState() => _KillSwitchDialogState();
}

class _KillSwitchDialogState extends State<_KillSwitchDialog> {
  static final _verRe = RegExp(r'^\d+\.\d+\.\d+$');
  late final _minVer = TextEditingController(text: widget.currentMinVersion);
  final _reason = TextEditingController();
  String? _error;

  bool get _needsVersion => widget.flagKey == _kForceUpdate;

  @override
  void dispose() {
    _minVer.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    String? ver;
    if (_needsVersion) {
      ver = _minVer.text.trim();
      final mustHave = widget.minVersionOnly || (widget.turnOn && ver.isEmpty);
      if (ver.isNotEmpty && !_verRe.hasMatch(ver)) {
        setState(() => _error = 'Version must look like 1.8.0.');
        return;
      }
      if (mustHave && ver.isEmpty) {
        setState(() => _error = 'Set a minimum version (e.g. 1.8.0) — a force-update needs one.');
        return;
      }
      if (ver.isEmpty) ver = null;
    }
    if (_reason.text.trim().isEmpty) {
      setState(() => _error = 'A reason is required — it goes in the audit log.');
      return;
    }
    Navigator.pop(context, _KillEdit(_reason.text.trim(), ver));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.minVersionOnly
        ? 'Set minimum version'
        : 'Turn ${widget.flagKey} ${widget.turnOn ? 'ON' : 'OFF'}';
    return AlertDialog(
      backgroundColor: MM.panel,
      title: Text(title, style: MM.display(size: 14, color: MM.white)),
      content: SizedBox(
        width: 400,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (widget.turnOn && !widget.minVersionOnly)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                widget.flagKey == _kMaintenance
                    ? 'This is a kill switch: once clients enforce it, every player sees the maintenance screen.'
                    : 'This is a kill switch: once clients enforce it, players below the minimum version are blocked.',
                style: MM.body(size: 12, color: MM.yellow),
              ),
            ),
          if (_needsVersion) ...[
            TextField(controller: _minVer, style: MM.mono(size: 12.5), decoration: _dec('Minimum version, e.g. 1.8.0')),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: _reason,
            maxLines: 2,
            style: MM.body(size: 12.5, color: MM.white),
            decoration: _dec('Reason (required — audit log)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: MM.body(size: 11.5, color: MM.red)),
          ],
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: widget.turnOn && !widget.minVersionOnly ? MM.red : MM.blue),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
