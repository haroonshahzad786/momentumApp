import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/admin_api_service.dart';
import '../../theme/momentum_tokens.dart';
import 'admin_widgets.dart';

/// §8 Content (copy/microcopy) editor — #A8.1 backend + #A8.2 live preview.
///
/// Unlike §7's Economy editor (which mirrors EXISTING hardcoded constants),
/// there is no existing copy store to mirror: every player-facing string
/// today is a Dart literal, and picking which ones to expose is a real
/// content-scope decision, not something to fabricate here. So this is the
/// generic mechanism only — admins create sections and keys from nothing via
/// this screen. Reads stream live from Firestore (signed-in read per §0's
/// rules); writes go ONLY through `adminSetContent`, which requires a reason
/// and bumps `content/_meta.version` (a version counter separate from
/// `config/_meta.version` — a copy edit and a reward-math change are
/// different kinds of risk).
///
/// HONEST CAVEAT, shown on screen: nothing in the app reads `content/*` at
/// runtime yet, and there's no copy-key → screen-context mapping, so the
/// "live preview" below is exactly what it says — the raw draft string, not
/// a fabricated phone-frame mockup of a screen that doesn't consume it.
class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});

  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen> {
  final _api = AdminApiService();
  final _db = FirebaseFirestore.instance;

  String? _selectedSection;
  String? _selectedKey;

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
      final resp = await _api.listAuditLog(action: 'admin_publish_content', limit: 100);
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

  Future<void> _newSection() async {
    final id = await showDialog<String>(
      context: context,
      builder: (_) => _NewSectionDialog(),
    );
    if (id == null || id.isEmpty) return;
    setState(() => _selectedSection = id);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('CONTENT', style: MM.display(size: 16, color: MM.white)),
            const SizedBox(width: 12),
            Text('content/* — copy & microcopy, keyed strings',
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
                    'Nothing in the app reads content/* yet — every screen still uses hardcoded strings, so a '
                    'publish here is versioned and audited but changes nothing live. The preview pane shows the '
                    'raw draft string; there is no copy-key → screen mapping yet, so it is not a phone mockup.',
                    style: MM.body(size: 12, color: Colors.white.withOpacity(0.6)),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 200, child: _sectionTree()),
            const SizedBox(width: 16),
            Expanded(flex: 3, child: _editorPanel()),
            const SizedBox(width: 16),
            SizedBox(width: 260, child: _previewPanel()),
          ]),
          const SizedBox(height: 22),
          _historyPanel(),
        ],
      ),
    );
  }

  Widget _sectionTree() {
    return AdminPanel(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _db.collection('content').orderBy(FieldPath.documentId).snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(14),
                child: Text('${snap.error}', style: MM.body(size: 11.5, color: MM.red)),
              );
            }
            final ids = (snap.data?.docs ?? const [])
                .map((d) => d.id)
                .where((id) => id != '_meta')
                .toList();
            _selectedSection ??= ids.isNotEmpty ? ids.first : null;
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
                child: Row(children: [
                  Expanded(
                    child: Text('content/', style: MM.displayX(size: 9, color: Colors.white.withOpacity(0.36))),
                  ),
                  InkWell(
                    onTap: _newSection,
                    child: const Icon(Icons.add_circle_outline, size: 16, color: MM.blue),
                  ),
                ]),
              ),
              if (ids.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text('No sections yet.', style: MM.body(size: 12, color: Colors.white.withOpacity(0.4))),
                ),
              for (final id in ids)
                InkWell(
                  onTap: () => setState(() {
                    _selectedSection = id;
                    _selectedKey = null;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    color: id == _selectedSection ? MM.blue.withOpacity(0.16) : null,
                    child: Text('content/$id',
                        style: MM.mono(size: 12, color: id == _selectedSection ? MM.white : Colors.white.withOpacity(0.65))),
                  ),
                ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _editorPanel() {
    final section = _selectedSection;
    if (section == null) {
      return AdminPanel(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Create a section to start adding copy.',
              style: MM.body(size: 12.5, color: Colors.white.withOpacity(0.5))),
        ),
      );
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.collection('content').doc(section).snapshots(),
      builder: (context, docSnap) {
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _db.collection('content').doc('_meta').snapshots(),
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
            final data = docSnap.data!.data() ?? const <String, dynamic>{};
            final meta = metaSnap.data!.data() ?? const <String, dynamic>{};
            final version = (meta['version'] as num?)?.toInt() ?? 0;
            return _ContentEditor(
              key: ValueKey('$section|${data['updatedAt']}'),
              section: section,
              data: data,
              currentVersion: version,
              api: _api,
              selectedKey: _selectedKey,
              onKeySelected: (k) => setState(() => _selectedKey = k),
              onPublished: _loadHistory,
            );
          },
        );
      },
    );
  }

  Widget _previewPanel() {
    final section = _selectedSection;
    final key = _selectedKey;
    return AdminPanel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('LIVE PREVIEW', style: MM.displayX(size: 11, color: Colors.white.withOpacity(0.6))),
          const SizedBox(height: 12),
          if (section == null || key == null)
            Text('Select a key to preview it.', style: MM.body(size: 12, color: Colors.white.withOpacity(0.4)))
          else
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _db.collection('content').doc(section).snapshots(),
              builder: (context, snap) {
                final value = snap.data?.data()?[key];
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: MM.pageBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(
                    value is String && value.isNotEmpty ? value : '(empty)',
                    style: MM.body(size: 13, color: MM.white),
                  ),
                );
              },
            ),
        ]),
      ),
    );
  }

  Widget _historyPanel() {
    final rows = _history.where((r) => '${r['target']}' == 'content/$_selectedSection').toList();
    return AdminPanel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('CHANGE HISTORY · content/$_selectedSection', style: MM.displayX(size: 11, color: Colors.white.withOpacity(0.6))),
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
          else if (_selectedSection == null || rows.isEmpty)
            Text('No publishes yet.', style: MM.body(size: 12.5, color: Colors.white.withOpacity(0.5)))
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
    final version = after['_contentVersion'];
    final keys = {...before.keys, ...after.keys}.where((k) => k != '_contentVersion').toList()..sort();
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
          child: Text(
            '$k: ${before[k] == null ? '(none)' : '"${before[k]}"'} → ${after[k] == null ? '(deleted)' : '"${after[k]}"'}',
            style: MM.mono(size: 11, color: Colors.white.withOpacity(0.7)),
          ),
        ),
    ]);
  }
}

class _NewSectionDialog extends StatefulWidget {
  @override
  State<_NewSectionDialog> createState() => _NewSectionDialogState();
}

class _NewSectionDialogState extends State<_NewSectionDialog> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: MM.panel,
      title: Text('New content section', style: MM.display(size: 14, color: MM.white)),
      content: SizedBox(
        width: 360,
        child: TextField(
          controller: _ctrl,
          autofocus: true,
          style: MM.mono(size: 13, color: MM.white),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'e.g. onboarding, dashboard',
            hintStyle: MM.body(size: 12, color: Colors.white.withOpacity(0.36)),
            errorText: _error,
            filled: true,
            fillColor: MM.pageBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final id = _ctrl.text.trim();
            if (!RegExp(r'^[a-z0-9_]{1,64}$').hasMatch(id) || id == '_meta') {
              setState(() => _error = 'Lowercase letters, numbers, underscores only');
              return;
            }
            Navigator.pop(context, id);
          },
          style: ElevatedButton.styleFrom(backgroundColor: MM.blue),
          child: const Text('Create'),
        ),
      ],
    );
  }
}

// ─── Editor ─────────────────────────────────────────────────────────────

class _KeyRow {
  _KeyRow({required this.key, required this.published, this.isNew = false})
      : ctrl = TextEditingController(text: published);

  final String key;
  final String published;
  final bool isNew;
  final TextEditingController ctrl;
  bool markedForDelete = false;

  bool get dirty => markedForDelete || ctrl.text != published;

  void dispose() => ctrl.dispose();
}

class _ContentEditor extends StatefulWidget {
  const _ContentEditor({
    super.key,
    required this.section,
    required this.data,
    required this.currentVersion,
    required this.api,
    required this.selectedKey,
    required this.onKeySelected,
    required this.onPublished,
  });

  final String section;
  final Map<String, dynamic> data;
  final int currentVersion;
  final AdminApiService api;
  final String? selectedKey;
  final ValueChanged<String> onKeySelected;
  final VoidCallback onPublished;

  @override
  State<_ContentEditor> createState() => _ContentEditorState();
}

class _ContentEditorState extends State<_ContentEditor> {
  late List<_KeyRow> _rows;
  bool _publishing = false;
  final _newKeyCtrl = TextEditingController();
  final _newValueCtrl = TextEditingController();
  String? _newKeyError;

  @override
  void initState() {
    super.initState();
    final keys = widget.data.keys.where((k) => k != 'updatedAt' && k != 'updatedBy').toList()..sort();
    _rows = [
      for (final k in keys) _KeyRow(key: k, published: '${widget.data[k] ?? ''}'),
    ];
    for (final r in _rows) {
      r.ctrl.addListener(_changed);
    }
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    _newKeyCtrl.dispose();
    _newValueCtrl.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  List<_KeyRow> get _dirtyRows => _rows.where((r) => r.dirty).toList();
  int get _dirtyCount => _dirtyRows.length + (_pendingNewKey != null ? 1 : 0);

  String? get _pendingNewKey {
    final k = _newKeyCtrl.text.trim();
    return k.isEmpty ? null : k;
  }

  void _addPendingKey() {
    final key = _newKeyCtrl.text.trim();
    if (!RegExp(r'^[a-zA-Z0-9_.]{1,128}$').hasMatch(key)) {
      setState(() => _newKeyError = 'Letters, numbers, underscore, dot only');
      return;
    }
    if (_rows.any((r) => r.key == key)) {
      setState(() => _newKeyError = 'Key already exists');
      return;
    }
    setState(() {
      final row = _KeyRow(key: key, published: '', isNew: true)..ctrl.text = _newValueCtrl.text;
      row.ctrl.addListener(_changed);
      _rows = [..._rows, row]..sort((a, b) => a.key.compareTo(b.key));
      _newKeyCtrl.clear();
      _newValueCtrl.clear();
      _newKeyError = null;
    });
    widget.onKeySelected(key);
  }

  void _discard() {
    for (final r in _rows) {
      r.ctrl.text = r.published;
      r.markedForDelete = false;
    }
    _rows.removeWhere((r) => r.isNew && r.ctrl.text == r.published);
    _changed();
  }

  Future<void> _publish() async {
    final dirty = _dirtyRows;
    if (dirty.isEmpty) return;
    final changes = <String, String>{};
    final deletes = <String>[];
    for (final r in dirty) {
      if (r.markedForDelete) {
        deletes.add(r.key);
      } else {
        changes[r.key] = r.ctrl.text;
      }
    }
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _ContentDiffDialog(
        section: widget.section,
        nextVersion: widget.currentVersion + 1,
        changes: changes,
        deletes: deletes,
        rows: dirty,
      ),
    );
    if (reason == null) return;
    // Captured BEFORE the await: resolving ScaffoldMessenger.of(context) after
    // an async gap can throw "Looking up a deactivated widget's ancestor is
    // unsafe" if the admin navigates away while the request is in flight —
    // which then surfaces as a false "Publish failed" even though the write
    // already succeeded server-side. The messenger instance itself stays
    // valid regardless of what happens to this context afterward.
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _publishing = true);
    try {
      final resp = await widget.api.setContent(
        section: widget.section,
        changes: changes,
        deletes: deletes,
        reason: reason,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Published content/${widget.section} as v${resp['version']}.')),
      );
      widget.onPublished();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Publish failed: $e')));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dirtyCount = _dirtyCount;
    return AdminPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Text('content/${widget.section}', style: MM.mono(size: 13, color: MM.white)),
            const Spacer(),
            Text('v${widget.currentVersion} published', style: MM.mono(size: 11, color: Colors.white.withOpacity(0.36))),
          ]),
        ),
        Container(
          color: MM.navy,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Expanded(flex: 3, child: Text('KEY', style: MM.displayX(size: 9, color: Colors.white.withOpacity(0.36)))),
            Expanded(flex: 5, child: Text('VALUE', style: MM.displayX(size: 9, color: Colors.white.withOpacity(0.36)))),
            const SizedBox(width: 32),
          ]),
        ),
        if (_rows.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text('No keys yet — add the first one below.',
                style: MM.body(size: 12.5, color: Colors.white.withOpacity(0.5))),
          )
        else
          for (final r in _rows) ...[
            _row(r),
            const Divider(height: 1, color: Colors.white12),
          ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _newKeyCtrl,
                style: MM.mono(size: 12, color: MM.white),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'new_key',
                  errorText: _newKeyError,
                  hintStyle: MM.body(size: 11.5, color: Colors.white.withOpacity(0.3)),
                  filled: true,
                  fillColor: MM.pageBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide(color: Colors.white.withOpacity(0.18))),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: TextField(
                controller: _newValueCtrl,
                style: MM.body(size: 12.5, color: MM.white),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'value',
                  hintStyle: MM.body(size: 11.5, color: Colors.white.withOpacity(0.3)),
                  filled: true,
                  fillColor: MM.pageBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide(color: Colors.white.withOpacity(0.18))),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.add_circle, color: MM.blue),
              onPressed: _addPendingKey,
              tooltip: 'Add key',
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
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
            ElevatedButton(
              onPressed: _dirtyRows.isEmpty || _publishing ? null : _publish,
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

  Widget _row(_KeyRow r) {
    final dirty = r.dirty;
    final selected = widget.selectedKey == r.key;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: BorderSide(color: r.markedForDelete ? MM.red : (dirty ? MM.yellow : Colors.white.withOpacity(0.18))),
    );
    return InkWell(
      onTap: () => widget.onKeySelected(r.key),
      child: Container(
        color: selected ? MM.blue.withOpacity(0.08) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Text(r.key,
                  style: MM.mono(size: 12, color: r.markedForDelete ? Colors.white38 : (dirty ? MM.yellow : MM.white))),
            ),
          ),
          Expanded(
            flex: 5,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(
                controller: r.ctrl,
                enabled: !r.markedForDelete,
                minLines: 1,
                maxLines: 4,
                style: MM.body(size: 12.5, color: MM.white),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: MM.pageBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  border: border,
                  enabledBorder: border,
                  focusedBorder: border,
                ),
              ),
              if (dirty && !r.markedForDelete && !r.isNew)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('was "${r.published}"', style: MM.mono(size: 10.5, color: Colors.white.withOpacity(0.4))),
                ),
            ]),
          ),
          SizedBox(
            width: 32,
            child: IconButton(
              icon: Icon(r.markedForDelete ? Icons.restore : Icons.delete_outline, size: 18, color: r.markedForDelete ? MM.teal : Colors.white38),
              tooltip: r.markedForDelete ? 'Keep' : 'Delete',
              onPressed: () => setState(() => r.markedForDelete = !r.markedForDelete),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ContentDiffDialog extends StatefulWidget {
  const _ContentDiffDialog({
    required this.section,
    required this.nextVersion,
    required this.changes,
    required this.deletes,
    required this.rows,
  });

  final String section;
  final int nextVersion;
  final Map<String, String> changes;
  final List<String> deletes;
  final List<_KeyRow> rows;

  @override
  State<_ContentDiffDialog> createState() => _ContentDiffDialogState();
}

class _ContentDiffDialogState extends State<_ContentDiffDialog> {
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
      title: Text('Publish content/${widget.section} → v${widget.nextVersion}', style: MM.display(size: 14, color: MM.white)),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final r in widget.rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.key, style: MM.mono(size: 12, color: MM.white)),
                  if (r.markedForDelete)
                    Text('− "${r.published}" (deleted)', style: MM.mono(size: 11.5, color: MM.red))
                  else ...[
                    if (!r.isNew) Text('− "${r.published}"', style: MM.mono(size: 11.5, color: MM.red)),
                    Text('+ "${r.ctrl.text}"', style: MM.mono(size: 11.5, color: MM.teal)),
                  ],
                ]),
              ),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide(color: Colors.white.withOpacity(0.18))),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: MM.body(size: 11.5, color: MM.red)),
            ],
          ]),
        ),
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
          style: ElevatedButton.styleFrom(backgroundColor: MM.blue),
          child: Text('Publish v${widget.nextVersion}'),
        ),
      ],
    );
  }
}
