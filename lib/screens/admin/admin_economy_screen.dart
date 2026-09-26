import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/admin_api_service.dart';
import '../../services/journey_config_service.dart';
import '../../theme/momentum_tokens.dart';
import 'admin_widgets.dart';

/// §7 Economy — the `config/*` editor (#A7.1 tree, #A7.3 dirty-state + preview
/// diff + versioned publish, #A7.4 change history).
///
/// Reads `config/{economy,levels,streaks,journey}` and `config/_meta` live from
/// Firestore (signed-in read per the §0 rules); writes ONLY through
/// `adminSetConfig`, which merges just the changed keys, bumps
/// `config/_meta.version`, requires a reason, and writes an audit entry with the
/// before/after diff — that audit entry IS the change history.
///
/// Editing model: the editor is generic over whatever fields the doc really
/// has (no invented key list). Each field is edited according to its stored
/// type — number, boolean, string, or JSON for null / object / array — and is
/// "dirty" when its parsed value differs from what's published. Only dirty keys
/// are sent. Adding or deleting keys is deliberately not offered here.
///
/// #A7.2: the Cloud Functions' reward math reads economy / levels / streaks
/// (economyConfig.js), so a publish changes live rewards within ~1 minute.
/// `journey` and the streak grace rules (#B4) are not wired yet — the on-screen
/// note says so.
const _kPaths = ['economy', 'levels', 'streaks', 'journey'];
const _kPathNotes = {
  'economy': 'Momentum Points and Space Credits earn rates',
  'levels': 'Level ladder — a level never downgrades',
  'streaks': 'Streak, miss and habit-formation rules',
  'journey': 'Planet route for the current galaxy',
};

class AdminEconomyScreen extends StatefulWidget {
  const AdminEconomyScreen({super.key});

  @override
  State<AdminEconomyScreen> createState() => _AdminEconomyScreenState();
}

class _AdminEconomyScreenState extends State<AdminEconomyScreen> {
  final _api = AdminApiService();
  final _db = FirebaseFirestore.instance;

  String _path = 'economy';
  int _dirtyCount = 0;

  List<Map> _history = const [];
  bool _historyLoading = true;
  String? _historyError;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _historyLoading = true;
      _historyError = null;
    });
    try {
      final resp = await _api.listAuditLog(action: 'admin_publish_config', limit: 100);
      if (!mounted) return;
      setState(() {
        _history = asMapList(resp['rows']);
        _historyLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _historyError = e.toString();
        _historyLoading = false;
      });
    }
  }

  Future<void> _switchTo(String path) async {
    if (path == _path) return;
    if (_dirtyCount > 0) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: MM.panel,
          title: Text('Discard unpublished changes?', style: MM.display(size: 14, color: MM.white)),
          content: Text(
            'config/$_path has $_dirtyCount unpublished change${_dirtyCount == 1 ? '' : 's'}. Switching discards them.',
            style: MM.body(size: 12.5, color: Colors.white.withOpacity(0.7)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep editing')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: MM.red),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (discard != true) return;
    }
    setState(() {
      _path = path;
      _dirtyCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('ECONOMY', style: MM.display(size: 16, color: MM.white)),
            const SizedBox(width: 12),
            Text('config/* — earn rates, streak rules, levels, journey',
                style: MM.body(size: 11.5, color: Colors.white.withOpacity(0.5))),
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
                    'Edit a value, preview the diff, then publish — each publish bumps the config version and is '
                    'written to the audit log with your reason. Live: economy (incl. the Momentum Points mode), '
                    'levels, streak milestones / qualifying average, and the planet route change the app within '
                    'about a minute of publishing. Not wired yet: the streak grace/break rules (#B4).',
                    style: MM.body(size: 12, color: Colors.white.withOpacity(0.6)),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 180, child: _tree()),
            const SizedBox(width: 16),
            Expanded(child: _editorFor(_path)),
          ]),
          const SizedBox(height: 22),
          _historyPanel(),
        ],
      ),
    );
  }

  Widget _tree() {
    return AdminPanel(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
            child: Text('config/', style: MM.displayX(size: 9, color: Colors.white.withOpacity(0.36))),
          ),
          for (final p in _kPaths)
            InkWell(
              onTap: () => _switchTo(p),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: p == _path ? MM.blue.withOpacity(0.16) : null,
                child: Row(children: [
                  Expanded(
                    child: Text('config/$p',
                        style: MM.mono(size: 12, color: p == _path ? MM.white : Colors.white.withOpacity(0.65))),
                  ),
                  if (p == _path && _dirtyCount > 0)
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: MM.yellow, shape: BoxShape.circle)),
                ]),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _editorFor(String path) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.collection('config').doc(path).snapshots(),
      builder: (context, docSnap) {
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _db.collection('config').doc('_meta').snapshots(),
          builder: (context, metaSnap) {
            if (docSnap.hasError) {
              return AdminErrorView(message: '${docSnap.error}', onRetry: () => setState(() {}));
            }
            if (!docSnap.hasData || !metaSnap.hasData) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: MM.blue)),
              );
            }
            final data = docSnap.data!.data();
            if (data == null) {
              return AdminPanel(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('config/$path has not been seeded yet — nothing to edit.',
                      style: MM.body(size: 12.5, color: Colors.white.withOpacity(0.5))),
                ),
              );
            }
            final meta = metaSnap.data!.data() ?? const <String, dynamic>{};
            final version = (meta['version'] as num?)?.toInt() ?? 0;
            final card = switch (path) {
              'economy' => _PointsModeCard(
                  key: ValueKey('pts|${data['updatedAt']}'),
                  data: data,
                  currentVersion: version,
                  api: _api,
                  onPublished: _loadHistory,
                ),
              'streaks' => _RelaunchPenaltyCard(
                  key: ValueKey('penalty|${data['updatedAt']}'),
                  data: data,
                  currentVersion: version,
                  api: _api,
                  onPublished: _loadHistory,
                ),
              'journey' => _PlanetsCard(
                  key: ValueKey('planets|${data['updatedAt']}'),
                  data: data,
                  currentVersion: version,
                  api: _api,
                  onPublished: _loadHistory,
                ),
              _ => null,
            };
            // Re-key on the doc's own updatedAt so a successful publish (or an
            // external edit) rebuilds the editor from the fresh published values.
            final editor = _ConfigEditor(
              key: ValueKey('$path|${data['updatedAt']}'),
              path: path,
              note: _kPathNotes[path] ?? '',
              data: data,
              currentVersion: version,
              api: _api,
              onDirtyChanged: (n) {
                if (n != _dirtyCount) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _dirtyCount = n);
                  });
                }
              },
              onPublished: _loadHistory,
            );
            if (card == null) return editor;
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              card,
              const SizedBox(height: 14),
              editor,
            ]);
          },
        );
      },
    );
  }

  Widget _historyPanel() {
    final rows = _history.where((r) => '${r['target']}' == 'config/$_path').toList();
    return AdminPanel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('CHANGE HISTORY · config/$_path', style: MM.displayX(size: 11, color: Colors.white.withOpacity(0.6))),
            const Spacer(),
            AdminRefreshButton(onTap: _loadHistory),
          ]),
          const SizedBox(height: 10),
          if (_historyLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator(color: MM.blue, strokeWidth: 2)),
            )
          else if (_historyError != null)
            Text('Could not load history: $_historyError', style: MM.body(size: 12, color: MM.red))
          else if (rows.isEmpty)
            Text('No publishes to config/$_path yet.', style: MM.body(size: 12.5, color: Colors.white.withOpacity(0.5)))
          else
            for (final r in rows) ...[
              _historyRow(r),
              const Divider(height: 20, color: Colors.white12),
            ],
        ]),
      ),
    );
  }

  Widget _historyRow(Map r) {
    final before = r['before'] is Map ? (r['before'] as Map) : const {};
    final after = r['after'] is Map ? (r['after'] as Map) : const {};
    final version = after['_configVersion'];
    final keys = {...before.keys, ...after.keys}.where((k) => k != '_configVersion').toList()..sort();
    final who = '${r['adminEmail'] ?? ''}'.isNotEmpty ? '${r['adminEmail']}' : '${r['adminUid'] ?? 'system'}';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        if (version != null) ...[
          Text('v$version', style: MM.mono(size: 12, color: MM.blue)),
          const SizedBox(width: 10),
        ],
        Text(adminShortWhen('${r['when'] ?? ''}'), style: MM.mono(size: 11, color: Colors.white.withOpacity(0.5))),
        const SizedBox(width: 10),
        Expanded(child: Text(who, style: MM.body(size: 12, color: MM.white), overflow: TextOverflow.ellipsis)),
      ]),
      if ('${r['reason'] ?? ''}'.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('“${r['reason']}”', style: MM.body(size: 12, color: Colors.white.withOpacity(0.6))),
        ),
      for (final k in keys)
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text('$k: ${_show(before[k])} → ${_show(after[k])}',
              style: MM.mono(size: 11, color: Colors.white.withOpacity(0.7))),
        ),
    ]);
  }
}

// ─── Editor ─────────────────────────────────────────────────────────────

enum _Kind { boolean, number, string, json }

_Kind _kindOf(Object? v) {
  if (v is bool) return _Kind.boolean;
  if (v is num) return _Kind.number;
  if (v is String) return _Kind.string;
  return _Kind.json; // null, Map, List
}

Object? _sanitize(Object? v) {
  if (v is Timestamp) return v.toDate().toUtc().toIso8601String();
  if (v is Map) return {for (final e in v.entries) '${e.key}': _sanitize(e.value)};
  if (v is List) return v.map(_sanitize).toList();
  return v;
}

/// Canonical JSON (sorted map keys) so equality ignores key ordering.
String _canon(Object? v) {
  Object? norm(Object? x) {
    if (x is Map) {
      final keys = x.keys.map((k) => '$k').toList()..sort();
      return {for (final k in keys) k: norm(x[k])};
    }
    if (x is List) return x.map(norm).toList();
    // 1 and 1.0 are the same config value — don't flag a false "unpublished change".
    if (x is num && x.isFinite && x == x.roundToDouble()) return x.toInt();
    return x;
  }

  return jsonEncode(norm(v));
}

String _show(Object? v) {
  if (v == null) return 'null';
  if (v is String) return '"$v"';
  return jsonEncode(_sanitize(v));
}

class _Field {
  _Field(this.key, Object? published)
      : published = _sanitize(published),
        kind = _kindOf(_sanitize(published)) {
    boolValue = this.published == true;
    ctrl = TextEditingController(text: _initialText());
  }

  final String key;
  final Object? published;
  final _Kind kind;
  late bool boolValue;
  late final TextEditingController ctrl;

  String _initialText() {
    switch (kind) {
      case _Kind.boolean:
        return '';
      case _Kind.number:
        final n = published as num;
        return n == n.roundToDouble() ? '${n.toInt()}' : '$n';
      case _Kind.string:
        return published as String;
      case _Kind.json:
        return published == null
            ? 'null'
            : const JsonEncoder.withIndent('  ').convert(published);
    }
  }

  /// (value, error). `error` non-null means the current text can't be parsed
  /// into this field's type — the row is flagged and Publish is blocked.
  (Object?, String?) parse() {
    switch (kind) {
      case _Kind.boolean:
        return (boolValue, null);
      case _Kind.number:
        final n = num.tryParse(ctrl.text.trim());
        return n == null ? (null, 'Enter a number') : (n, null);
      case _Kind.string:
        return (ctrl.text, null);
      case _Kind.json:
        try {
          return (jsonDecode(ctrl.text.trim().isEmpty ? 'null' : ctrl.text), null);
        } catch (_) {
          return (null, 'Not valid JSON');
        }
    }
  }

  bool get dirty {
    final (v, err) = parse();
    if (err != null) return true;
    return _canon(v) != _canon(published);
  }

  void dispose() => ctrl.dispose();
}

class _ConfigEditor extends StatefulWidget {
  const _ConfigEditor({
    super.key,
    required this.path,
    required this.note,
    required this.data,
    required this.currentVersion,
    required this.api,
    required this.onDirtyChanged,
    required this.onPublished,
  });

  final String path;
  final String note;
  final Map<String, dynamic> data;
  final int currentVersion;
  final AdminApiService api;
  final ValueChanged<int> onDirtyChanged;
  final VoidCallback onPublished;

  @override
  State<_ConfigEditor> createState() => _ConfigEditorState();
}

class _ConfigEditorState extends State<_ConfigEditor> {
  late final List<_Field> _fields;
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    final keys = widget.data.keys.where((k) => k != 'updatedAt').toList()..sort();
    _fields = [for (final k in keys) _Field(k, widget.data[k])];
    for (final f in _fields) {
      f.ctrl.addListener(_changed);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDirtyChanged(0));
  }

  @override
  void dispose() {
    for (final f in _fields) {
      f.dispose();
    }
    super.dispose();
  }

  void _changed() {
    setState(() {});
    widget.onDirtyChanged(_dirty.length);
  }

  List<_Field> get _dirty => _fields.where((f) => f.dirty).toList();
  bool get _hasError => _fields.any((f) => f.parse().$2 != null);

  void _discard() {
    for (final f in _fields) {
      f.boolValue = f.published == true;
      f.ctrl.text = f._initialText();
    }
    _changed();
  }

  Map<String, dynamic> get _changes => {
        for (final f in _dirty) f.key: f.parse().$1,
      };

  Future<void> _preview({required bool publish}) async {
    final dirty = _dirty;
    if (dirty.isEmpty) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _DiffDialog(
        path: widget.path,
        nextVersion: widget.currentVersion + 1,
        diffs: [for (final f in dirty) (f.key, _show(f.published), _show(f.parse().$1))],
        publish: publish,
      ),
    );
    if (!publish || reason == null) return;
    setState(() => _publishing = true);
    try {
      final resp = await widget.api.setConfig(path: widget.path, changes: _changes, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Published config/${widget.path} as v${resp['version']}.')),
      );
      widget.onPublished();
      // The Firestore stream now delivers the new updatedAt, which re-keys (and
      // therefore rebuilds) this editor from the published values.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Publish failed: $e')));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dirtyCount = _dirty.length;
    return AdminPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Text('config/${widget.path}', style: MM.mono(size: 13, color: MM.white)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(widget.note, style: MM.body(size: 11.5, color: Colors.white.withOpacity(0.5))),
            ),
            Text('v${widget.currentVersion} published', style: MM.mono(size: 11, color: Colors.white.withOpacity(0.36))),
          ]),
        ),
        Container(
          color: MM.navy,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            _head('KEY', 3),
            _head('VALUE', 5),
            _head('TYPE', 1),
          ]),
        ),
        if (_fields.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text('This document has no editable fields.',
                style: MM.body(size: 12.5, color: Colors.white.withOpacity(0.5))),
          )
        else
          for (final f in _fields) ...[
            _row(f),
            const Divider(height: 1, color: Colors.white12),
          ],
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            if (dirtyCount > 0) ...[
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: MM.yellow, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('$dirtyCount unpublished change${dirtyCount == 1 ? '' : 's'}',
                  style: MM.body(size: 12, color: MM.yellow)),
            ] else
              Text('No unpublished changes', style: MM.body(size: 12, color: Colors.white.withOpacity(0.4))),
            const Spacer(),
            TextButton(onPressed: dirtyCount == 0 || _publishing ? null : _discard, child: const Text('Discard')),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: dirtyCount == 0 || _publishing ? null : () => _preview(publish: false),
              child: const Text('Preview diff'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: dirtyCount == 0 || _hasError || _publishing ? null : () => _preview(publish: true),
              style: ElevatedButton.styleFrom(backgroundColor: MM.blue),
              child: _publishing
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Publish v${widget.currentVersion + 1}'),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _row(_Field f) {
    final (_, err) = f.parse();
    final dirty = f.dirty;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: BorderSide(color: err != null ? MM.red : (dirty ? MM.yellow : Colors.white.withOpacity(0.18))),
    );
    Widget editor;
    switch (f.kind) {
      case _Kind.boolean:
        editor = Align(
          alignment: Alignment.centerLeft,
          child: Switch(
            value: f.boolValue,
            activeColor: MM.blue,
            onChanged: (v) {
              f.boolValue = v;
              _changed();
            },
          ),
        );
      case _Kind.json:
        editor = TextField(
          controller: f.ctrl,
          minLines: 1,
          maxLines: 8,
          style: MM.mono(size: 12),
          decoration: _fieldDec(border, err),
        );
      case _Kind.number:
        editor = TextField(
          controller: f.ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          style: MM.mono(size: 12.5),
          decoration: _fieldDec(border, err),
        );
      case _Kind.string:
        editor = TextField(
          controller: f.ctrl,
          style: MM.body(size: 12.5, color: MM.white),
          decoration: _fieldDec(border, err),
        );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.only(top: 9),
            child: Text(f.key, style: MM.mono(size: 12, color: dirty ? MM.yellow : MM.white)),
          ),
        ),
        Expanded(
          flex: 5,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            editor,
            if (dirty && err == null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('was ${_show(f.published)}', style: MM.mono(size: 10.5, color: Colors.white.withOpacity(0.4))),
              ),
          ]),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              switch (f.kind) {
                _Kind.boolean => 'bool',
                _Kind.number => 'number',
                _Kind.string => 'text',
                _Kind.json => f.published == null ? 'null' : (f.published is List ? 'list' : 'object'),
              },
              style: MM.displayX(size: 8.5, color: Colors.white.withOpacity(0.36)),
            ),
          ),
        ),
      ]),
    );
  }

  InputDecoration _fieldDec(InputBorder border, String? err) => InputDecoration(
        isDense: true,
        filled: true,
        fillColor: MM.pageBg,
        errorText: err,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: border,
        enabledBorder: border,
        focusedBorder: border,
      );

  Widget _head(String label, int flex) => Expanded(
        flex: flex,
        child: Text(label, style: MM.displayX(size: 9, color: Colors.white.withOpacity(0.36))),
      );
}

class _DiffDialog extends StatefulWidget {
  const _DiffDialog({
    required this.path,
    required this.nextVersion,
    required this.diffs,
    required this.publish,
  });
  final String path;
  final int nextVersion;
  final List<(String, String, String)> diffs; // key, was, now
  final bool publish;

  @override
  State<_DiffDialog> createState() => _DiffDialogState();
}

class _DiffDialogState extends State<_DiffDialog> {
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
      title: Text(
        widget.publish ? 'Publish config/${widget.path} → v${widget.nextVersion}' : 'Diff · config/${widget.path}',
        style: MM.display(size: 14, color: MM.white),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final (key, was, now) in widget.diffs)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(key, style: MM.mono(size: 12, color: MM.white)),
                  Text('− $was', style: MM.mono(size: 11.5, color: MM.red)),
                  Text('+ $now', style: MM.mono(size: 11.5, color: MM.teal)),
                ]),
              ),
            if (widget.publish) ...[
              const SizedBox(height: 4),
              TextField(
                controller: _reason,
                maxLines: 2,
                style: MM.body(size: 12.5, color: MM.white),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Reason (required — audit log)',
                  hintStyle: MM.body(size: 12, color: Colors.white.withOpacity(0.36)),
                  filled: true,
                  fillColor: MM.pageBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: MM.body(size: 11.5, color: MM.red)),
              ],
            ],
          ]),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.publish ? 'Cancel' : 'Close'),
        ),
        if (widget.publish)
          ElevatedButton(
            onPressed: () {
              final r = _reason.text.trim();
              if (r.isEmpty) {
                setState(() => _error = 'A reason is required — it goes in the audit log.');
                return;
              }
              Navigator.pop(context, r);
            },
            style: ElevatedButton.styleFrom(backgroundColor: MM.blue),
            child: Text('Publish v${widget.nextVersion}'),
          ),
      ],
    );
  }
}

// ─── Purpose-built cards (Will's decisions, 2026-09-25) ────────────────────

/// Shared publish step for the cards: diff + required reason → adminSetConfig.
Future<bool> _publishCard(
  BuildContext context, {
  required String path,
  required int currentVersion,
  required AdminApiService api,
  required Map<String, dynamic> published,
  required Map<String, dynamic> changes,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final reason = await showDialog<String>(
    context: context,
    builder: (_) => _DiffDialog(
      path: path,
      nextVersion: currentVersion + 1,
      diffs: [
        for (final e in changes.entries) (e.key, _show(_sanitize(published[e.key])), _show(e.value)),
      ],
      publish: true,
    ),
  );
  if (reason == null) return false;
  try {
    final resp = await api.setConfig(path: path, changes: changes, reason: reason);
    messenger.showSnackBar(SnackBar(content: Text('Published config/$path as v${resp['version']}.')));
    return true;
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Publish failed: $e')));
    return false;
  }
}

Widget _cardHeader(String title, String subtitle) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(children: [
        Text(title, style: MM.displayX(size: 11, color: MM.white)),
        const SizedBox(width: 12),
        Expanded(child: Text(subtitle, style: MM.body(size: 11.5, color: Colors.white.withOpacity(0.5)))),
      ]),
    );

InputDecoration _numDec() => InputDecoration(
      isDense: true,
      filled: true,
      fillColor: MM.pageBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
      ),
    );

/// #41 — how many Momentum Points a completed check-in earns: a fixed amount
/// (the Gamification spec's +10, default) or scaled by the day's Core scores.
class _PointsModeCard extends StatefulWidget {
  const _PointsModeCard({
    super.key,
    required this.data,
    required this.currentVersion,
    required this.api,
    required this.onPublished,
  });
  final Map<String, dynamic> data;
  final int currentVersion;
  final AdminApiService api;
  final VoidCallback onPublished;

  @override
  State<_PointsModeCard> createState() => _PointsModeCardState();
}

class _PointsModeCardState extends State<_PointsModeCard> {
  static const _defaultTable = {1: 0, 2: 5, 3: 10, 4: 15, 5: 20};
  late String _mode;
  late final TextEditingController _flat;
  late final TextEditingController _base;
  late final Map<int, TextEditingController> _table;
  bool _busy = false;

  int _int(Object? v, int d) => v is num && v >= 0 ? v.toInt() : d;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _mode = d['checkinPointsMode'] == 'scaled' ? 'scaled' : 'flat';
    _flat = TextEditingController(text: '${_int(d['checkinPoints'], 10)}');
    _base = TextEditingController(text: '${_int(d['scaledCheckinBase'], 10)}');
    final t = d['scaledPointsPerScore'] is Map ? d['scaledPointsPerScore'] as Map : const {};
    _table = {
      for (final k in [1, 2, 3, 4, 5])
        k: TextEditingController(text: '${_int(t['$k'] ?? t[k], _defaultTable[k]!)}'),
    };
    for (final c in [_flat, _base, ..._table.values]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_flat, _base, ..._table.values]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _read(TextEditingController c) {
    final n = int.tryParse(c.text.trim());
    return n != null && n >= 0 ? n : null;
  }

  /// Keys that differ from what's live; null while any field is invalid.
  Map<String, dynamic>? get _changes {
    final flat = _read(_flat), base = _read(_base);
    final table = {for (final e in _table.entries) '${e.key}': _read(e.value)};
    if (flat == null || base == null || table.values.any((v) => v == null)) return null;
    final next = <String, dynamic>{
      'checkinPointsMode': _mode,
      'checkinPoints': flat,
      'scaledCheckinBase': base,
      'scaledPointsPerScore': table,
    };
    return {
      for (final e in next.entries)
        if (_canon(e.value) != _canon(_sanitize(widget.data[e.key]))) e.key: e.value,
    };
  }

  Future<void> _publish() async {
    final changes = _changes;
    if (changes == null || changes.isEmpty) return;
    setState(() => _busy = true);
    final ok = await _publishCard(context,
        path: 'economy',
        currentVersion: widget.currentVersion,
        api: widget.api,
        published: widget.data,
        changes: changes);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) widget.onPublished();
  }

  String _example(List<int> scores) {
    final base = _read(_base) ?? 0;
    final b = [for (final s in scores) _read(_table[s]!) ?? 0];
    return '${base + (b.reduce((a, c) => a + c) / b.length).round()}';
  }

  @override
  Widget build(BuildContext context) {
    final changes = _changes;
    return AdminPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _cardHeader('MOMENTUM POINTS PER CHECK-IN', 'What a completed weekday check-in earns'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'flat', label: Text('Fixed amount'), icon: Icon(Icons.horizontal_rule, size: 16)),
                ButtonSegment(
                    value: 'scaled', label: Text('Scale with scores'), icon: Icon(Icons.trending_up, size: 16)),
              ],
              selected: {_mode},
              onSelectionChanged: (v) => setState(() => _mode = v.first),
            ),
          ),
        ),
        if (_mode == 'flat')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(children: [
              Text('Points per check-in', style: MM.body(size: 12.5, color: MM.white)),
              const SizedBox(width: 12),
              SizedBox(width: 90, child: TextField(controller: _flat, style: MM.mono(size: 12.5), decoration: _numDec())),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Same for every check-in, whatever the scores (Gamification spec: +10).',
                    style: MM.body(size: 11.5, color: Colors.white.withOpacity(0.5))),
              ),
            ]),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Base points', style: MM.body(size: 12.5, color: MM.white)),
                const SizedBox(width: 12),
                SizedBox(width: 90, child: TextField(controller: _base, style: MM.mono(size: 12.5), decoration: _numDec())),
              ]),
              const SizedBox(height: 10),
              Text('+ bonus by Core score (averaged over the Cores scored that day)',
                  style: MM.body(size: 11.5, color: Colors.white.withOpacity(0.6))),
              const SizedBox(height: 6),
              Wrap(spacing: 10, runSpacing: 8, children: [
                for (final e in _table.entries)
                  SizedBox(
                    width: 110,
                    child: Row(children: [
                      Text('Score ${e.key}', style: MM.mono(size: 11.5, color: Colors.white.withOpacity(0.7))),
                      const SizedBox(width: 6),
                      Expanded(child: TextField(controller: e.value, style: MM.mono(size: 12.5), decoration: _numDec())),
                    ]),
                  ),
              ]),
              const SizedBox(height: 8),
              if (_read(_base) != null && _table.values.every((c) => _read(c) != null))
                Text(
                  'Example: one Core scored 4 → ${_example([4])} MP · Cores scored 4 and 2 → ${_example([4, 2])} MP · '
                  'all 5s → ${_example([5])} MP',
                  style: MM.mono(size: 11, color: MM.teal),
                ),
            ]),
          ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Text(
              changes == null
                  ? 'Enter whole numbers ≥ 0'
                  : changes.isEmpty
                      ? 'Matches what is live'
                      : changes.keys.every((k) => !widget.data.containsKey(k)) && _mode == 'flat' &&
                              changes['checkinPoints'] == 10
                          ? 'Live now: built-in default (+10 fixed). Publish to save it to config.'
                          : '${changes.length} unpublished change${changes.length == 1 ? '' : 's'}',
              style: MM.body(
                  size: 12, color: changes == null ? MM.red : (changes.isEmpty ? Colors.white38 : MM.yellow)),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _busy || changes == null || changes.isEmpty ? null : _publish,
              style: ElevatedButton.styleFrom(backgroundColor: MM.blue),
              child: Text('Publish v${widget.currentVersion + 1}'),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// #42 — which planets are on the route for the current galaxy. Earth is the
/// fixed launch point; 5–8 destinations (default 5). Publishing rewrites
/// `config/journey.planets` as the full catalogue with `enabled` flags, keeping
/// any names / MP thresholds already published.
class _PlanetsCard extends StatefulWidget {
  const _PlanetsCard({
    super.key,
    required this.data,
    required this.currentVersion,
    required this.api,
    required this.onPublished,
  });
  final Map<String, dynamic> data;
  final int currentVersion;
  final AdminApiService api;
  final VoidCallback onPublished;

  @override
  State<_PlanetsCard> createState() => _PlanetsCardState();
}

class _PlanetsCardState extends State<_PlanetsCard> {
  late final List<JourneyPlanet> _published;
  late final Map<String, bool> _on;
  late final String _galaxy;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final (g, planets) = JourneyConfigService.parse(widget.data);
    _galaxy = g;
    _published = planets;
    _on = {for (final p in planets) p.id: p.enabled};
  }

  int get _count => _published.where((p) => !p.start && _on[p.id]!).length;
  bool get _valid =>
      _count >= JourneyConfigService.minDestinations && _count <= JourneyConfigService.maxDestinations;

  /// Also dirty while the live doc predates the catalogue format (no
  /// galaxyId / enabled flags), so the first publish writes the full shape.
  bool get _dirty => _published.any((p) => p.enabled != _on[p.id]) || widget.data['galaxyId'] == null;

  String _hex(Color c) => '#${(c.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  Future<void> _publish() async {
    setState(() => _busy = true);
    final planets = [
      for (var i = 0; i < _published.length; i++)
        {
          'id': _published[i].id,
          'name': _published[i].name,
          'order': i,
          'color': _hex(_published[i].color),
          'mpRequired': _published[i].mpRequired,
          'enabled': _on[_published[i].id],
        },
    ];
    final ok = await _publishCard(context,
        path: 'journey',
        currentVersion: widget.currentVersion,
        api: widget.api,
        published: widget.data,
        changes: {'galaxyId': _galaxy, 'planets': planets});
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) widget.onPublished();
  }

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _cardHeader(
            'PLANET ROUTE',
            'Galaxy: ${_galaxy == 'milky_way' ? 'Milky Way' : _galaxy} · Earth → destinations → Station. '
                'Reaching the last planet will unlock the next galaxy (future).'),
        for (final p in _published)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: p.color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Text(p.name, style: MM.body(size: 13, color: MM.white))),
              if (p.start)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('Launch point — always on', style: MM.body(size: 11.5, color: Colors.white38)),
                )
              else
                Switch(
                  value: _on[p.id]!,
                  activeColor: MM.blue,
                  onChanged: (v) => setState(() => _on[p.id] = v),
                ),
            ]),
          ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Text(
              '$_count destinations — '
              '${!_valid ? 'choose between 5 and 8' : !_dirty ? 'matches what is live' : _published.every((p) => p.enabled == _on[p.id]) ? 'live now: built-in default route. Publish to save it to config.' : 'unpublished changes'}',
              style: MM.body(size: 12, color: !_valid ? MM.red : (_dirty ? MM.yellow : Colors.white38)),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _busy || !_valid || !_dirty ? null : _publish,
              style: ElevatedButton.styleFrom(backgroundColor: MM.blue),
              child: Text('Publish v${widget.currentVersion + 1}'),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// #16 — Momentum Points removed when a player misses enough weekdays for a
/// relaunch (spec §6 "Momentum Points reduced", amount [PLACEHOLDER]). 0 = off.
/// Applied once per gap by `flutterGetUserProfile`.
class _RelaunchPenaltyCard extends StatefulWidget {
  const _RelaunchPenaltyCard({
    super.key,
    required this.data,
    required this.currentVersion,
    required this.api,
    required this.onPublished,
  });
  final Map<String, dynamic> data;
  final int currentVersion;
  final AdminApiService api;
  final VoidCallback onPublished;

  @override
  State<_RelaunchPenaltyCard> createState() => _RelaunchPenaltyCardState();
}

class _RelaunchPenaltyCardState extends State<_RelaunchPenaltyCard> {
  // (key, label, default, min, help) — defaults mirror economyConfig.js so a
  // not-yet-seeded key shows what the server actually uses.
  static const _rows = <(String, String, int, int, String)>[
    ('missPenaltyPoints', 'Relaunch penalty (Momentum Points)', 0, 0,
        'Removed once per gap after 2+ missed weekdays, never below 0. 0 = off. Trophy Room, credits, lists and level are never touched.'),
    ('streakSaverMilestone', 'Streak Saver earned at (days)', 30, 0,
        'Streak length that awards a Streak Saver. 0 = Savers off.'),
    ('maxStreakSavers', 'Max Streak Savers held', 1, 0,
        'Savers are spent automatically to cover missed weekdays.'),
    ('vacationMaxDays', 'Vacation Mode max length (days)', 7, 1,
        'PRD: up to 7 days. Vacation weekdays never count as missed.'),
    ('vacationsPerYear', 'Vacations per year', 0, 0,
        '0 = no limit (the spec leaves this open).'),
  ];

  late final Map<String, TextEditingController> _ctrl = {
    for (final r in _rows) r.$1: TextEditingController(text: '${_published(r)}'),
  };
  bool _busy = false;

  int _published((String, String, int, int, String) r) {
    final v = widget.data[r.$1];
    return v is num ? v.toInt() : r.$3;
  }

  @override
  void initState() {
    super.initState();
    for (final c in _ctrl.values) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final changes = <String, Object?>{};
    var valid = true;
    for (final r in _rows) {
      final n = int.tryParse(_ctrl[r.$1]!.text.trim());
      if (n == null || n < r.$4) {
        valid = false;
      } else if (n != _published(r)) {
        changes[r.$1] = n;
      }
    }
    final dirty = valid && changes.isNotEmpty;
    return AdminPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _cardHeader('STREAK RULES', 'Relaunch penalty · Streak Savers · Vacation Mode'),
        for (final r in _rows)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(children: [
              SizedBox(width: 230, child: Text(r.$2, style: MM.body(size: 12.5, color: MM.white))),
              const SizedBox(width: 12),
              SizedBox(
                  width: 90,
                  child: TextField(controller: _ctrl[r.$1], style: MM.mono(size: 12.5), decoration: _numDec())),
              const SizedBox(width: 12),
              Expanded(
                child: Text(r.$5, style: MM.body(size: 11.5, color: Colors.white.withOpacity(0.5))),
              ),
            ]),
          ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Text(
              !valid ? 'Enter whole numbers (vacation length ≥ 1)' : (dirty ? 'Unpublished change' : 'Matches what is live'),
              style: MM.body(size: 12, color: !valid ? MM.red : (dirty ? MM.yellow : Colors.white38)),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _busy || !dirty
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      final ok = await _publishCard(context,
                          path: 'streaks',
                          currentVersion: widget.currentVersion,
                          api: widget.api,
                          published: widget.data,
                          changes: changes);
                      if (!mounted) return;
                      setState(() => _busy = false);
                      if (ok) widget.onPublished();
                    },
              style: ElevatedButton.styleFrom(backgroundColor: MM.blue),
              child: Text('Publish v${widget.currentVersion + 1}'),
            ),
          ]),
        ),
      ]),
    );
  }
}
