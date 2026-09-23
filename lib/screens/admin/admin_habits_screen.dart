import 'package:flutter/material.dart';

import '../../services/admin_api_service.dart';
import '../../theme/momentum_tokens.dart';
import 'admin_widgets.dart';

/// §4 Habits library — real, backed by `adminListHabitTemplates` (list +
/// per-core distribution + `config/streaks`) and `adminHabitTemplate`
/// (create / update / duplicate / archive / unarchive — no hard delete; every
/// write needs a reason and is audit-logged).
///
/// Honest gaps, stated on screen rather than faked:
///  * "Assigned" and "Form rate" per template show "—": nothing in the app
///    assigns a Golden Habit FROM a template yet (onboarding forges habits via
///    the Claude agent), so any number would be fabricated (#A4.2).
///  * "Habits per core" IS real — a tally over actual golden habits (#A4.4) —
///    but it counts habits, not template usage.
///  * Formation rules are a read-only view of `config/streaks`; they're edited
///    in Economy (one editor, one version history).
const _kCores = ['mindset', 'career', 'relationships', 'physical', 'emotional'];
const _kCoreLabels = {
  'mindset': 'Mindset',
  'career': 'Career',
  'relationships': 'Relationships',
  'physical': 'Physical',
  'emotional': 'Emotional',
};
const _kDifficulties = ['Easy', 'Medium', 'Hard'];

class AdminHabitsScreen extends StatefulWidget {
  const AdminHabitsScreen({super.key, this.onOpenEconomy});

  /// Jumps to the Economy editor (where `config/streaks` is edited).
  final VoidCallback? onOpenEconomy;

  @override
  State<AdminHabitsScreen> createState() => _AdminHabitsScreenState();
}

class _AdminHabitsScreenState extends State<AdminHabitsScreen> {
  final _api = AdminApiService();

  bool _loading = true;
  String? _error;
  List<Map> _templates = const [];
  Map<String, dynamic> _distribution = const {};
  Map<String, dynamic> _rules = const {};
  String _templatesNote = '';

  String _coreFilter = 'all';
  bool _showArchived = false;
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
      final r = await _api.listHabitTemplates();
      if (!mounted) return;
      setState(() {
        _templates = asMapList(r['templates']);
        _distribution = (r['distribution'] as Map?)?.cast<String, dynamic>() ?? const {};
        _rules = (r['formationRules'] as Map?)?.cast<String, dynamic>() ?? const {};
        _templatesNote = '${r['templatesNote'] ?? ''}';
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

  Future<void> _run(Future<Map<String, dynamic>> Function() call, String okMessage) async {
    setState(() => _busy = true);
    try {
      await call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(okMessage)));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit([Map? existing]) async {
    final result = await showDialog<_TemplateEdit>(
      context: context,
      builder: (_) => _TemplateDialog(existing: existing),
    );
    if (result == null) return;
    if (existing == null) {
      await _run(
        () => _api.habitTemplate(
          action: 'create',
          reason: result.reason,
          name: result.name,
          coreId: result.coreId,
          cadence: result.cadence,
          difficulty: result.difficulty,
        ),
        'Template "${result.name}" created.',
      );
    } else {
      // Only send fields that actually changed — the backend's before/after
      // diff in the audit log is then exactly what the admin touched.
      await _run(
        () => _api.habitTemplate(
          action: 'update',
          templateId: '${existing['id']}',
          reason: result.reason,
          name: result.name == '${existing['name']}' ? null : result.name,
          coreId: result.coreId == '${existing['coreId']}' ? null : result.coreId,
          cadence: result.cadence == '${existing['cadence']}' ? null : result.cadence,
          difficulty: result.difficulty == '${existing['difficulty']}' ? null : result.difficulty,
        ),
        'Template "${result.name}" updated.',
      );
    }
  }

  Future<void> _simpleAction(Map t, String action, String verb) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _ReasonDialog(
        title: '$verb "${t['name']}"',
        confirmLabel: verb,
        destructive: action == 'archive',
        blurb: switch (action) {
          'archive' =>
            'Archived templates disappear from the pick list but nothing is deleted — existing habits keep working and you can restore it any time.',
          'unarchive' => 'The template will appear in the pick list again.',
          _ => 'Creates a copy named "${t['name']} (copy)" that you can then edit.',
        },
      ),
    );
    if (reason == null) return;
    await _run(
      () => _api.habitTemplate(action: action, templateId: '${t['id']}', reason: reason),
      switch (action) {
        'archive' => 'Archived "${t['name']}".',
        'unarchive' => 'Restored "${t['name']}".',
        _ => 'Duplicated "${t['name']}".',
      },
    );
  }

  List<Map> get _visible => _templates.where((t) {
        if (!_showArchived && t['archived'] == true) return false;
        if (_coreFilter != 'all' && '${t['coreId']}' != _coreFilter) return false;
        return true;
      }).toList();

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: MM.blue));
    if (_error != null) return AdminErrorView(message: _error!, onRetry: _load);

    final rows = _visible;
    final activeCount = _templates.where((t) => t['archived'] != true).length;
    int countFor(String core) =>
        _templates.where((t) => '${t['coreId']}' == core && (_showArchived || t['archived'] != true)).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('HABITS LIBRARY', style: MM.display(size: 16, color: MM.white)),
            const SizedBox(width: 12),
            Text('$activeCount active template${activeCount == 1 ? '' : 's'} · habit_templates in Firestore',
                style: MM.body(size: 11.5, color: Colors.white.withOpacity(0.5))),
            const Spacer(),
            AdminRefreshButton(onTap: _load),
          ]),
          const SizedBox(height: 16),
          AdminPanel(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'The habit templates clients can choose from. Archive rather than delete — nothing is removed. '
                '${_templatesNote.isEmpty ? '' : 'Assigned and form rate show "—" because $_templatesNote.'}',
                style: MM.body(size: 12, color: Colors.white.withOpacity(0.6)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            _chip('All', 'all', _templates.where((t) => _showArchived || t['archived'] != true).length, null),
            for (final c in _kCores) _chip(_kCoreLabels[c]!, c, countFor(c), MM.coreColor[c]),
            const SizedBox(width: 6),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Checkbox(value: _showArchived, onChanged: (v) => setState(() => _showArchived = v == true)),
              Text('Show archived', style: MM.body(size: 12, color: Colors.white.withOpacity(0.6))),
            ]),
            ElevatedButton.icon(
              onPressed: _busy ? null : () => _edit(),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('New'),
              style: ElevatedButton.styleFrom(backgroundColor: MM.blue),
            ),
          ]),
          const SizedBox(height: 14),
          _table(rows),
          const SizedBox(height: 22),
          LayoutBuilder(builder: (context, c) {
            final rules = _formationRules();
            final dist = _distributionPanel();
            if (c.maxWidth < 900) {
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [rules, const SizedBox(height: 16), dist]);
            }
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: rules),
              const SizedBox(width: 16),
              Expanded(child: dist),
            ]);
          }),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, int count, Color? dot) {
    final on = _coreFilter == value;
    return InkWell(
      onTap: () => setState(() => _coreFilter = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: on ? MM.blue.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: on ? MM.blue : Colors.white.withOpacity(0.18)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (dot != null) ...[
            Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            const SizedBox(width: 7),
          ],
          Text('$label · $count', style: MM.body(size: 12, color: on ? MM.white : Colors.white.withOpacity(0.7))),
        ]),
      ),
    );
  }

  Widget _table(List<Map> rows) {
    return AdminPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          color: MM.navy,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            _head('HABIT TEMPLATE', 4),
            _head('CORE', 2),
            _head('CADENCE', 2),
            _head('DIFFICULTY', 2),
            _head('ASSIGNED', 1),
            _head('FORM RATE', 1),
            const SizedBox(width: 220),
          ]),
        ),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: Text(
                _templates.isEmpty
                    ? 'No habit templates yet — use "New" to add the first one.'
                    : 'No templates match this filter.',
                style: MM.body(size: 12.5, color: Colors.white.withOpacity(0.5)),
              ),
            ),
          )
        else
          for (final t in rows) ...[
            _row(t),
            const Divider(height: 1, color: Colors.white12),
          ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text('${rows.length} of ${_templates.length} · habit_templates/{id}',
              style: MM.mono(size: 10.5, color: Colors.white.withOpacity(0.36))),
        ),
      ]),
    );
  }

  Widget _row(Map t) {
    final archived = t['archived'] == true;
    final core = '${t['coreId']}';
    final dim = archived ? 0.45 : 1.0;
    return Opacity(
      opacity: dim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Expanded(
            flex: 4,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text('${t['name']}', style: MM.body(size: 12.5, color: MM.white), overflow: TextOverflow.ellipsis)),
                if (archived) ...[
                  const SizedBox(width: 8),
                  Text('ARCHIVED', style: MM.displayX(size: 8, color: Colors.white.withOpacity(0.5))),
                ],
              ]),
              Text('${t['id']}', style: MM.mono(size: 10, color: Colors.white.withOpacity(0.36)), overflow: TextOverflow.ellipsis),
            ]),
          ),
          Expanded(
            flex: 2,
            child: Row(children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(color: MM.coreColor[core] ?? Colors.white38, shape: BoxShape.circle)),
              const SizedBox(width: 7),
              Text(_kCoreLabels[core] ?? core, style: MM.body(size: 12, color: Colors.white.withOpacity(0.75))),
            ]),
          ),
          Expanded(flex: 2, child: Text('${t['cadence']}'.isEmpty ? '—' : '${t['cadence']}', style: MM.body(size: 12, color: Colors.white.withOpacity(0.7)))),
          Expanded(flex: 2, child: Text('${t['difficulty']}'.isEmpty ? '—' : '${t['difficulty']}', style: MM.body(size: 12, color: Colors.white.withOpacity(0.7)))),
          Expanded(flex: 1, child: Text('—', style: MM.mono(size: 12, color: Colors.white.withOpacity(0.36)))),
          Expanded(flex: 1, child: Text('—', style: MM.mono(size: 12, color: Colors.white.withOpacity(0.36)))),
          SizedBox(
            width: 220,
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (!archived) ...[
                _link('Edit', () => _edit(t)),
                _link('Duplicate', () => _simpleAction(t, 'duplicate', 'Duplicate')),
                _link('Archive', () => _simpleAction(t, 'archive', 'Archive'), color: MM.red),
              ] else
                _link('Restore', () => _simpleAction(t, 'unarchive', 'Restore')),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _link(String label, VoidCallback onTap, {Color color = MM.blue}) => Padding(
        padding: const EdgeInsets.only(left: 14),
        child: InkWell(
          onTap: _busy ? null : onTap,
          child: Text(label, style: MM.body(size: 12, color: color)),
        ),
      );

  Widget _formationRules() {
    final entries = _rules.entries.where((e) => e.key != 'updatedAt').toList()..sort((a, b) => a.key.compareTo(b.key));
    return AdminPanel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('FORMATION RULES', style: MM.displayX(size: 11, color: Colors.white.withOpacity(0.6))),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text('config/streaks has not been published yet.',
                style: MM.body(size: 12.5, color: Colors.white.withOpacity(0.5)))
          else
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: Text(e.key, style: MM.mono(size: 11.5, color: Colors.white.withOpacity(0.7)))),
                  Expanded(flex: 4, child: Text(_valueText(e.value), style: MM.mono(size: 11.5, color: MM.white))),
                ]),
              ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: Text('Read-only view of config/streaks. Edit and publish it in Economy.',
                  style: MM.body(size: 11, color: Colors.white.withOpacity(0.4))),
            ),
            if (widget.onOpenEconomy != null)
              InkWell(
                onTap: widget.onOpenEconomy,
                child: Text('Open Economy →', style: MM.body(size: 12, color: MM.blue)),
              ),
          ]),
        ]),
      ),
    );
  }

  String _valueText(Object? v) {
    if (v == null) return 'null';
    if (v is Map || v is List) return _compact(v);
    return '$v';
  }

  String _compact(Object? v) {
    if (v is Map) return v.entries.map((e) => '${e.key}: ${_compact(e.value)}').join(' · ');
    if (v is List) return v.map(_compact).join(', ');
    return '$v';
  }

  Widget _distributionPanel() {
    int assigned(String c) => ((_distribution[c] as Map?)?['assigned'] as num?)?.toInt() ?? 0;
    int formed(String c) => ((_distribution[c] as Map?)?['formed'] as num?)?.toInt() ?? 0;
    final maxAssigned = _kCores.map(assigned).fold<int>(0, (a, b) => a > b ? a : b);
    final total = _kCores.map(assigned).fold<int>(0, (a, b) => a + b);
    return AdminPanel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('HABITS PER CORE · $total golden habit${total == 1 ? '' : 's'}',
              style: MM.displayX(size: 11, color: Colors.white.withOpacity(0.6))),
          const SizedBox(height: 12),
          for (final c in _kCores)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(_kCoreLabels[c]!, style: MM.body(size: 12.5, color: MM.white)),
                  const Spacer(),
                  Text('${assigned(c)} assigned · ${formed(c)} formed',
                      style: MM.mono(size: 11, color: Colors.white.withOpacity(0.5))),
                ]),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: maxAssigned == 0 ? 0 : assigned(c) / maxAssigned,
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation(MM.coreColor[c] ?? MM.blue),
                  ),
                ),
              ]),
            ),
          const SizedBox(height: 6),
          Text('Real tally over golden habits clients have actually created — not template usage.',
              style: MM.body(size: 11, color: Colors.white.withOpacity(0.4))),
        ]),
      ),
    );
  }

  Widget _head(String label, int flex) => Expanded(
        flex: flex,
        child: Text(label, style: MM.displayX(size: 9, color: Colors.white.withOpacity(0.36))),
      );
}

// ─── Dialogs ────────────────────────────────────────────────────────────

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

class _TemplateEdit {
  const _TemplateEdit(this.name, this.coreId, this.cadence, this.difficulty, this.reason);
  final String name;
  final String coreId;
  final String cadence;
  final String difficulty;
  final String reason;
}

class _TemplateDialog extends StatefulWidget {
  const _TemplateDialog({this.existing});
  final Map? existing;

  @override
  State<_TemplateDialog> createState() => _TemplateDialogState();
}

class _TemplateDialogState extends State<_TemplateDialog> {
  late final _name = TextEditingController(text: '${widget.existing?['name'] ?? ''}');
  late final _cadence = TextEditingController(text: '${widget.existing?['cadence'] ?? ''}');
  final _reason = TextEditingController();
  late String _core = _kCores.contains('${widget.existing?['coreId']}') ? '${widget.existing!['coreId']}' : _kCores.first;
  late String _difficulty = _kDifficulties.contains('${widget.existing?['difficulty']}') ? '${widget.existing!['difficulty']}' : '';
  String? _error;

  bool get _isNew => widget.existing == null;

  @override
  void dispose() {
    _name.dispose();
    _cadence.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'A name is required.');
      return;
    }
    if (_reason.text.trim().isEmpty) {
      setState(() => _error = 'A reason is required — it goes in the audit log.');
      return;
    }
    if (!_isNew) {
      final e = widget.existing!;
      final unchanged = _name.text.trim() == '${e['name']}' &&
          _core == '${e['coreId']}' &&
          _cadence.text.trim() == '${e['cadence']}' &&
          _difficulty == '${e['difficulty']}';
      if (unchanged) {
        setState(() => _error = 'Nothing changed.');
        return;
      }
    }
    Navigator.pop(context, _TemplateEdit(_name.text.trim(), _core, _cadence.text.trim(), _difficulty, _reason.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: MM.panel,
      title: Text(_isNew ? 'New habit template' : 'Edit template', style: MM.display(size: 14, color: MM.white)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(controller: _name, style: MM.body(size: 12.5, color: MM.white), decoration: _dec('Habit name')),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _select<String>('Core', _core, {for (final c in _kCores) c: _kCoreLabels[c]!}, (v) => setState(() => _core = v!))),
              const SizedBox(width: 10),
              Expanded(
                child: _select<String>(
                  'Difficulty',
                  _difficulty,
                  {'': '—', for (final d in _kDifficulties) d: d},
                  (v) => setState(() => _difficulty = v ?? ''),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            TextField(controller: _cadence, style: MM.body(size: 12.5, color: MM.white), decoration: _dec('Cadence (e.g. Daily)')),
            const SizedBox(height: 10),
            TextField(controller: _reason, maxLines: 2, style: MM.body(size: 12.5, color: MM.white), decoration: _dec('Reason (required — audit log)')),
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

  Widget _select<T>(String label, T value, Map<T, String> options, ValueChanged<T?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: MM.pageBg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: options.containsKey(value) ? value : options.keys.first,
          isExpanded: true,
          dropdownColor: MM.navy,
          isDense: true,
          hint: Text(label),
          style: MM.body(size: 12, color: Colors.white.withOpacity(0.85)),
          items: options.entries.map((e) => DropdownMenuItem<T>(value: e.key, child: Text(e.value))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({
    required this.title,
    required this.confirmLabel,
    required this.blurb,
    this.destructive = false,
  });
  final String title;
  final String confirmLabel;
  final String blurb;
  final bool destructive;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: MM.panel,
      title: Text(widget.title, style: MM.display(size: 14, color: MM.white)),
      content: SizedBox(
        width: 400,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.blurb, style: MM.body(size: 12, color: Colors.white.withOpacity(0.6))),
          const SizedBox(height: 12),
          TextField(controller: _reason, maxLines: 2, style: MM.body(size: 12.5, color: MM.white), decoration: _dec('Reason (required — audit log)')),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: MM.body(size: 11.5, color: MM.red)),
          ],
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final r = _reason.text.trim();
            if (r.isEmpty) {
              setState(() => _error = 'A reason is required — it goes in the audit log.');
              return;
            }
            Navigator.pop(context, r);
          },
          style: ElevatedButton.styleFrom(backgroundColor: widget.destructive ? MM.red : MM.blue),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
