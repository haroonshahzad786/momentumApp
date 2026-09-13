import 'package:flutter/material.dart';

import '../../services/admin_api_service.dart';
import '../../theme/momentum_tokens.dart';
import 'admin_widgets.dart';

const List<String> kAdminKnownPlanets = ['earth', 'moon', 'mars', 'jupiter', 'saturn', 'pluto'];

/// §2 Client Detail + §3 Access & Passwords, in one screen (matching the
/// design, where Access & Passwords lives as actions ON the Client Detail
/// page rather than its own sidebar destination). Backed by
/// `adminGetClientDetail`/`adminAdjustClient`/`adminClientAccess` — every
/// action here is real, not a stub: it writes to the real ledgers/Auth
/// record and lands a real admin_audit_log entry, same as verified via curl
/// while building §2/§3.
class AdminClientDetailScreen extends StatefulWidget {
  const AdminClientDetailScreen({super.key, required this.uid, required this.onBack});
  final String uid;
  final VoidCallback onBack;

  @override
  State<AdminClientDetailScreen> createState() => _AdminClientDetailScreenState();
}

class _AdminClientDetailScreenState extends State<AdminClientDetailScreen> {
  final _api = AdminApiService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _detail;
  bool _busy = false;

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
      final detail = await _api.getClientDetail(widget.uid);
      if (!mounted) return;
      setState(() {
        _detail = detail;
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

  Future<void> _runAdjust(String action, {bool needsAmount = false, bool needsPlanet = false, String amountLabel = 'Amount'}) async {
    final input = await _promptAction(context, title: _actionTitle(action), needsAmount: needsAmount, needsPlanet: needsPlanet, amountLabel: amountLabel);
    if (input == null) return;
    setState(() => _busy = true);
    try {
      await _api.adjustClient(
        uid: widget.uid,
        action: action,
        reason: input['reason'] as String,
        amount: input['amount'] as int?,
        planet: input['planet'] as String?,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_actionTitle(action)} — done.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runAccess(String action, {bool needsNewEmail = false}) async {
    final input = await _promptAction(context, title: _actionTitle(action), needsNewEmail: needsNewEmail);
    if (input == null) return;
    setState(() => _busy = true);
    try {
      final result = await _api.clientAccess(
        uid: widget.uid,
        action: action,
        reason: input['reason'] as String,
        newEmail: input['newEmail'] as String?,
      );
      if (!mounted) return;
      final link = result['resetLink'] ?? result['verificationLink'];
      if (link != null) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: MM.navy,
            title: Text(_actionTitle(action), style: MM.display(size: 15, color: MM.white)),
            content: SelectableText('$link', style: MM.body(size: 11.5, color: Colors.white70)),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_actionTitle(action)} — done.')));
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _actionTitle(String action) => switch (action) {
        'grant_points' => 'Grant / deduct MP',
        'grant_credits' => 'Grant / deduct credits',
        'restore_checkpoint' => 'Restore rocket checkpoint',
        'reset_onboarding' => 'Reset onboarding',
        'suspend' => 'Suspend account',
        'unsuspend' => 'Unsuspend account',
        'send_password_reset' => 'Send password reset link',
        'force_password_reset' => 'Force reset on next sign-in',
        'revoke_sessions' => 'Revoke all sessions',
        'change_email' => 'Change email',
        _ => action,
      };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: MM.blue));
    if (_error != null) return AdminErrorView(message: _error!, onRetry: _load);

    final client = (_detail?['client'] as Map?) ?? const {};
    final habits = ((_detail?['goldenHabits'] as List?) ?? const []).cast<Map>();
    final checkins = ((_detail?['checkins'] as List?) ?? const []).cast<Map>();
    final suspended = client['suspended'] == true;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: widget.onBack,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.chevron_left, size: 16, color: Colors.white60),
                  Text('All clients', style: MM.body(size: 12, color: Colors.white.withOpacity(0.6))),
                ]),
              ),
              const SizedBox(height: 12),
              AdminPanel(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(children: [
                            Text('${client['displayName'] ?? widget.uid}', style: MM.display(size: 16, color: MM.white)),
                            const SizedBox(width: 10),
                            AdminStatusChip(status: '${client['status'] ?? ''}'),
                          ]),
                          const SizedBox(height: 6),
                          Text('${client['email'] ?? ''}  ·  ${widget.uid}', style: MM.mono(size: 10.5, color: Colors.white.withOpacity(0.5))),
                          const SizedBox(height: 4),
                          Text('${client['level']} · ${client['planet']}', style: MM.body(size: 12, color: Colors.white.withOpacity(0.6))),
                        ],
                      ),
                    ),
                    AdminRefreshButton(onTap: _load),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(spacing: 12, runSpacing: 12, children: [
                _stat('Momentum Points', '${client['momentumScore'] ?? 0}', MM.white),
                _stat('Space Credits', '${client['spaceCredits'] ?? 0}', MM.yellow),
                _stat('Streak · longest', '${client['streak'] ?? 0} / ${client['longestStreak'] ?? 0}', MM.red),
                _stat('Stage 1 · Stage 2', '${client['stage1Completed'] == true ? '✓' : '—'} · ${client['stage2Completed'] == true ? '✓' : '—'}', MM.teal),
              ]),
              const SizedBox(height: 24),
              Text('MANUAL ADJUSTMENTS', style: MM.displayX(size: 11, color: Colors.white.withOpacity(0.6))),
              const SizedBox(height: 10),
              Wrap(spacing: 10, runSpacing: 10, children: [
                _actionButton('Grant / deduct MP', () => _runAdjust('grant_points', needsAmount: true, amountLabel: 'MP (use - to deduct)')),
                _actionButton('Grant / deduct credits', () => _runAdjust('grant_credits', needsAmount: true, amountLabel: 'Credits (use - to deduct)')),
                _actionButton('Restore rocket checkpoint', () => _runAdjust('restore_checkpoint', needsPlanet: true)),
                _actionButton('Reset onboarding', () => _runAdjust('reset_onboarding')),
                _actionButton(suspended ? 'Unsuspend account' : 'Suspend account', () => _runAdjust(suspended ? 'unsuspend' : 'suspend'), destructive: !suspended),
              ]),
              const SizedBox(height: 24),
              Text('ACCESS & PASSWORDS', style: MM.displayX(size: 11, color: Colors.white.withOpacity(0.6))),
              const SizedBox(height: 10),
              Wrap(spacing: 10, runSpacing: 10, children: [
                _actionButton('Send password reset link', () => _runAccess('send_password_reset')),
                _actionButton('Force reset on next sign-in', () => _runAccess('force_password_reset')),
                _actionButton('Revoke all sessions', () => _runAccess('revoke_sessions'), destructive: true),
                _actionButton('Change email', () => _runAccess('change_email', needsNewEmail: true)),
              ]),
              const SizedBox(height: 24),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _habitsPanel(habits)),
                const SizedBox(width: 16),
                Expanded(child: _checkinsPanel(checkins)),
              ]),
            ],
          ),
        ),
        if (_busy) Positioned.fill(child: Container(color: Colors.black45, child: const Center(child: CircularProgressIndicator(color: MM.blue)))),
      ],
    );
  }

  Widget _stat(String label, String value, Color color) {
    return AdminPanel(
      width: 200,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(), style: MM.displayX(size: 9, color: Colors.white.withOpacity(0.55))),
          const SizedBox(height: 8),
          Text(value, style: MM.mono(size: 18, color: color)),
        ]),
      ),
    );
  }

  Widget _actionButton(String label, VoidCallback onTap, {bool destructive = false}) {
    return OutlinedButton(
      onPressed: _busy ? null : onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: destructive ? MM.red.withOpacity(0.5) : Colors.white24),
        foregroundColor: destructive ? MM.red : Colors.white70,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _habitsPanel(List<Map> habits) {
    return AdminPanel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('GOLDEN HABITS', style: MM.displayX(size: 10, color: Colors.white.withOpacity(0.5))),
          const SizedBox(height: 10),
          if (habits.isEmpty) Text('None yet.', style: MM.body(size: 12, color: Colors.white.withOpacity(0.5))),
          for (final h in habits)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Expanded(child: Text('${h['habitName'] ?? h['habitId']}', style: MM.body(size: 12, color: MM.white), overflow: TextOverflow.ellipsis)),
                if (h['formed'] == true) const Icon(Icons.emoji_events, size: 14, color: MM.yellow),
                if (h['flagged'] == true) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.flag, size: 14, color: MM.red)),
              ]),
            ),
        ]),
      ),
    );
  }

  Widget _checkinsPanel(List<Map> checkins) {
    return AdminPanel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('RECENT CHECK-INS', style: MM.displayX(size: 10, color: Colors.white.withOpacity(0.5))),
          const SizedBox(height: 10),
          if (checkins.isEmpty) Text('None yet.', style: MM.body(size: 12, color: Colors.white.withOpacity(0.5))),
          for (final c in checkins.take(10))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Text('${c['date']}', style: MM.mono(size: 11, color: Colors.white.withOpacity(0.6))),
                const SizedBox(width: 10),
                Expanded(child: Text((c['scores'] as Map?)?.values.join(', ') ?? '', style: MM.mono(size: 11, color: MM.white))),
              ]),
            ),
        ]),
      ),
    );
  }
}

/// Every admin mutation requires a `reason` server-side (§2/§3) — this
/// dialog is the one place that's collected, plus whatever extra field the
/// action needs (amount, planet, new email).
Future<Map<String, dynamic>?> _promptAction(
  BuildContext context, {
  required String title,
  bool needsAmount = false,
  bool needsPlanet = false,
  bool needsNewEmail = false,
  String amountLabel = 'Amount',
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => _ActionDialog(
      title: title,
      needsAmount: needsAmount,
      needsPlanet: needsPlanet,
      needsNewEmail: needsNewEmail,
      amountLabel: amountLabel,
    ),
  );
}

class _ActionDialog extends StatefulWidget {
  const _ActionDialog({
    required this.title,
    required this.needsAmount,
    required this.needsPlanet,
    required this.needsNewEmail,
    required this.amountLabel,
  });

  final String title;
  final bool needsAmount;
  final bool needsPlanet;
  final bool needsNewEmail;
  final String amountLabel;

  @override
  State<_ActionDialog> createState() => _ActionDialogState();
}

class _ActionDialogState extends State<_ActionDialog> {
  final _reasonCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _planet = kAdminKnownPlanets.first;
  String? _formError;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _amountCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _reasonCtrl.text.trim();
    if (reason.isEmpty) {
      setState(() => _formError = 'Reason is required.');
      return;
    }
    int? amount;
    if (widget.needsAmount) {
      amount = int.tryParse(_amountCtrl.text.trim());
      if (amount == null || amount == 0) {
        setState(() => _formError = 'Enter a non-zero whole number.');
        return;
      }
    }
    String? newEmail;
    if (widget.needsNewEmail) {
      newEmail = _emailCtrl.text.trim();
      if (!newEmail.contains('@')) {
        setState(() => _formError = 'Enter a valid email.');
        return;
      }
    }
    Navigator.pop(context, {
      'reason': reason,
      if (widget.needsAmount) 'amount': amount,
      if (widget.needsPlanet) 'planet': _planet,
      if (widget.needsNewEmail) 'newEmail': newEmail,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: MM.navy,
      title: Text(widget.title, style: MM.display(size: 15, color: MM.white)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.needsAmount) ...[
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                style: MM.body(size: 13, color: MM.white),
                decoration: InputDecoration(labelText: widget.amountLabel, labelStyle: MM.body(size: 12, color: Colors.white60)),
              ),
              const SizedBox(height: 12),
            ],
            if (widget.needsPlanet) ...[
              DropdownButtonFormField<String>(
                value: _planet,
                dropdownColor: MM.navy,
                style: MM.body(size: 13, color: MM.white),
                decoration: InputDecoration(labelText: 'Planet', labelStyle: MM.body(size: 12, color: Colors.white60)),
                items: kAdminKnownPlanets.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => _planet = v ?? _planet),
              ),
              const SizedBox(height: 12),
            ],
            if (widget.needsNewEmail) ...[
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: MM.body(size: 13, color: MM.white),
                decoration: InputDecoration(labelText: 'New email', labelStyle: MM.body(size: 12, color: Colors.white60)),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _reasonCtrl,
              style: MM.body(size: 13, color: MM.white),
              decoration: InputDecoration(labelText: 'Reason (required)', labelStyle: MM.body(size: 12, color: Colors.white60)),
            ),
            if (_formError != null) ...[
              const SizedBox(height: 8),
              Text(_formError!, style: MM.body(size: 11.5, color: MM.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _confirm, style: ElevatedButton.styleFrom(backgroundColor: MM.blue), child: const Text('Confirm')),
      ],
    );
  }
}
