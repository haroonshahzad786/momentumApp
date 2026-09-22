import 'package:flutter/material.dart';

import '../../services/admin_api_service.dart';
import '../../theme/momentum_tokens.dart';
import 'admin_widgets.dart';

/// §11 Cantina moderation — BACKEND_PLAN.md #B21-24.
///
/// Built on `space_cantina_posts` (Ideas Well) and `tribes`/`tribes/*/posts`
/// (Space Tribes) — the SAME 2026-09-22 rules fix that unblocks real player
/// writes to these collections (see firestore.rules) also lays down the
/// admin-only moderation fields this screen edits. Soft-delete only
/// (`removed`, never a hard delete), matching every other admin screen.
///
/// HONEST GAPS, shown on screen rather than hidden:
///  * The report queue is real, working infrastructure with ZERO reports in
///    it — no client-side "report" button exists anywhere in the app yet.
///    That's a separate player-facing feature, out of this admin panel's
///    scope; this screen is ready the moment it ships.
///  * The banned-word list is storage + admin CRUD only — nothing scans new
///    posts against it yet (that's BACKEND_PLAN.md #B25, explicitly later
///    scope: an AI moderation pass).
///  * Ban/mute lives on the Client Detail page (`cantina_mute`/
///    `cantina_unmute` via adminAdjustClient) — it acts on a user account,
///    not a post/tribe, so it's not duplicated here.
class AdminCantinaScreen extends StatefulWidget {
  const AdminCantinaScreen({super.key});

  @override
  State<AdminCantinaScreen> createState() => _AdminCantinaScreenState();
}

enum _Tab { posts, tribes, reports, bannedWords }

class _AdminCantinaScreenState extends State<AdminCantinaScreen> {
  final _api = AdminApiService();
  _Tab _tab = _Tab.posts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('CANTINA', style: MM.display(size: 16, color: MM.white)),
            const SizedBox(width: 12),
            Text('Space Tribes + Ideas Well moderation', style: MM.body(size: 11.5, color: Colors.white.withOpacity(0.5))),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            _tabChip('Ideas Well posts', _Tab.posts),
            const SizedBox(width: 8),
            _tabChip('Space Tribes', _Tab.tribes),
            const SizedBox(width: 8),
            _tabChip('Report queue', _Tab.reports),
            const SizedBox(width: 8),
            _tabChip('Banned words', _Tab.bannedWords),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: switch (_tab) {
              _Tab.posts => _PostsTab(api: _api),
              _Tab.tribes => _TribesTab(api: _api),
              _Tab.reports => _ReportsTab(api: _api),
              _Tab.bannedWords => _BannedWordsTab(api: _api),
            },
          ),
        ],
      ),
    );
  }

  Widget _tabChip(String label, _Tab t) {
    final selected = _tab == t;
    return InkWell(
      onTap: () => setState(() => _tab = t),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? MM.blue.withOpacity(0.16) : MM.panel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? MM.blue.withOpacity(0.5) : Colors.white.withOpacity(0.1)),
        ),
        child: Text(label, style: MM.body(size: 12, color: selected ? MM.white : Colors.white.withOpacity(0.6))),
      ),
    );
  }
}

/// Reason-required confirmation, shared by every moderation action here —
/// same contract as every other admin mutation in this app (§2/§3/§7/§8).
Future<String?> _promptReason(BuildContext context, String title, {String? body}) {
  final ctrl = TextEditingController();
  String? error;
  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: MM.panel,
        title: Text(title, style: MM.display(size: 14, color: MM.white)),
        content: SizedBox(
          width: 420,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (body != null) ...[
              Text(body, style: MM.body(size: 12.5, color: Colors.white.withOpacity(0.7))),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: ctrl,
              maxLines: 2,
              autofocus: true,
              style: MM.body(size: 12.5, color: MM.white),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Reason (required — audit log)',
                hintStyle: MM.body(size: 12, color: Colors.white.withOpacity(0.36)),
                errorText: error,
                filled: true,
                fillColor: MM.pageBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide(color: Colors.white.withOpacity(0.18))),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final r = ctrl.text.trim();
              if (r.isEmpty) {
                setState(() => error = 'A reason is required.');
                return;
              }
              Navigator.pop(ctx, r);
            },
            style: ElevatedButton.styleFrom(backgroundColor: MM.blue),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ),
  );
}

// ─── Ideas Well posts ─────────────────────────────────────────────────────

class _PostsTab extends StatefulWidget {
  const _PostsTab({required this.api});
  final AdminApiService api;

  @override
  State<_PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends State<_PostsTab> {
  bool _loading = true;
  String? _error;
  List<Map> _posts = const [];
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
      final resp = await widget.api.listCantinaContent(type: 'posts');
      if (!mounted) return;
      setState(() => _posts = ((resp['posts'] as List?) ?? const []).cast<Map>());
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _act(Map post, String action, {String? confirmBody}) async {
    final title = switch (action) {
      'remove' => 'Remove post',
      'restore' => 'Restore post',
      'pin' => 'Pin post',
      'unpin' => 'Unpin post',
      'feature' => 'Feature post',
      _ => 'Unfeature post',
    };
    final reason = await _promptReason(context, '$title · "${post['title']}"', body: confirmBody);
    if (reason == null) return;
    // Captured before the await — see _ContentEditorState._publish()'s note
    // in admin_content_screen.dart for why (avoids a false "Failed" snackbar
    // on a request that actually succeeded, if the admin navigates away
    // mid-request).
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await widget.api.moderateCantina(type: 'post', id: '${post['id']}', action: action, reason: reason);
      await _load();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: MM.blue));
    if (_error != null) return AdminErrorView(message: _error!, onRetry: _load);
    return Stack(children: [
      AdminPanel(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              Text('${_posts.length} posts', style: MM.body(size: 12, color: Colors.white.withOpacity(0.5))),
              const Spacer(),
              AdminRefreshButton(onTap: _load),
            ]),
          ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: ListView.separated(
              itemCount: _posts.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
              itemBuilder: (context, i) => _postRow(_posts[i]),
            ),
          ),
        ]),
      ),
      if (_busy) Positioned.fill(child: Container(color: Colors.black38, child: const Center(child: CircularProgressIndicator(color: MM.blue)))),
    ]);
  }

  Widget _postRow(Map p) {
    final removed = p['removed'] == true;
    final pinned = p['pinned'] == true;
    final featured = p['featured'] == true;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text('${p['title']}',
                    style: MM.body(size: 13, color: removed ? Colors.white38 : MM.white)
                        .copyWith(decoration: removed ? TextDecoration.lineThrough : null)),
              ),
              if (pinned) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.push_pin, size: 13, color: MM.yellow)),
              if (featured) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.star, size: 13, color: MM.teal)),
            ]),
            const SizedBox(height: 4),
            Text('${p['kind']} · ${p['core']} · ${p['upvotes']} upvotes · ${p['adopted']} adopted',
                style: MM.mono(size: 11, color: Colors.white.withOpacity(0.45))),
            if (removed && p['removedReason'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Removed: "${p['removedReason']}"', style: MM.body(size: 11, color: MM.red)),
              ),
          ]),
        ),
        const SizedBox(width: 12),
        Wrap(spacing: 6, runSpacing: 6, children: [
          if (removed)
            _smallButton('Restore', () => _act(p, 'restore'))
          else ...[
            _smallButton(pinned ? 'Unpin' : 'Pin', () => _act(p, pinned ? 'unpin' : 'pin')),
            _smallButton(featured ? 'Unfeature' : 'Feature', () => _act(p, featured ? 'unfeature' : 'feature')),
            _smallButton('Remove', () => _act(p, 'remove'), destructive: true),
          ],
        ]),
      ]),
    );
  }

  Widget _smallButton(String label, VoidCallback onTap, {bool destructive = false}) {
    return OutlinedButton(
      onPressed: _busy ? null : onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: destructive ? MM.red.withOpacity(0.5) : Colors.white24),
        foregroundColor: destructive ? MM.red : Colors.white70,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}

// ─── Space Tribes ──────────────────────────────────────────────────────────

class _TribesTab extends StatefulWidget {
  const _TribesTab({required this.api});
  final AdminApiService api;

  @override
  State<_TribesTab> createState() => _TribesTabState();
}

class _TribesTabState extends State<_TribesTab> {
  bool _loading = true;
  String? _error;
  List<Map> _tribes = const [];
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
      final resp = await widget.api.listCantinaContent(type: 'tribes');
      if (!mounted) return;
      setState(() => _tribes = ((resp['tribes'] as List?) ?? const []).cast<Map>());
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _rename(Map t) async {
    final ctrl = TextEditingController(text: '${t['name']}');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MM.panel,
        title: Text('Rename tribe', style: MM.display(size: 14, color: MM.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: MM.body(size: 13, color: MM.white),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: MM.pageBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide(color: Colors.white.withOpacity(0.18))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: MM.blue),
            child: const Text('Next'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final reason = await _promptReason(context, 'Rename "${t['name']}" → "$name"');
    if (reason == null) return;
    await _run(() => widget.api.moderateCantina(type: 'tribe', id: '${t['id']}', action: 'rename', name: name, reason: reason));
  }

  Future<void> _setStatus(Map t, String status) async {
    final reason = await _promptReason(context, 'Set "${t['name']}" → $status');
    if (reason == null) return;
    await _run(() => widget.api.moderateCantina(type: 'tribe', id: '${t['id']}', action: 'set_status', status: status, reason: reason));
  }

  Future<void> _deleteRestore(Map t, bool deleting) async {
    final reason = await _promptReason(context, deleting ? 'Delete tribe "${t['name']}"' : 'Restore tribe "${t['name']}"');
    if (reason == null) return;
    await _run(() => widget.api.moderateCantina(type: 'tribe', id: '${t['id']}', action: deleting ? 'delete' : 'restore', reason: reason));
  }

  Future<void> _run(Future<void> Function() call) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await call();
      await _load();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: MM.blue));
    if (_error != null) return AdminErrorView(message: _error!, onRetry: _load);
    return Stack(children: [
      AdminPanel(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              Text('${_tribes.length} tribes', style: MM.body(size: 12, color: Colors.white.withOpacity(0.5))),
              const Spacer(),
              AdminRefreshButton(onTap: _load),
            ]),
          ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: ListView.separated(
              itemCount: _tribes.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
              itemBuilder: (context, i) => _tribeRow(_tribes[i]),
            ),
          ),
        ]),
      ),
      if (_busy) Positioned.fill(child: Container(color: Colors.black38, child: const Center(child: CircularProgressIndicator(color: MM.blue)))),
    ]);
  }

  Widget _tribeRow(Map t) {
    final removed = t['removed'] == true;
    final status = '${t['status'] ?? 'active'}';
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text('${t['name']}',
                    style: MM.body(size: 13, color: removed ? Colors.white38 : MM.white)
                        .copyWith(decoration: removed ? TextDecoration.lineThrough : null)),
              ),
              AdminStatusChip(status: status),
            ]),
            const SizedBox(height: 4),
            Text('${t['core']} · ${t['isPublic'] == true ? 'public' : 'private'} · ${t['memberCount']} shown / ${t['realMemberCount']} real members',
                style: MM.mono(size: 11, color: Colors.white.withOpacity(0.45))),
          ]),
        ),
        const SizedBox(width: 12),
        Wrap(spacing: 6, runSpacing: 6, children: [
          if (removed)
            _smallButton('Restore', () => _deleteRestore(t, false))
          else ...[
            _smallButton('Rename', () => _rename(t)),
            PopupMenuButton<String>(
              onSelected: (s) => _setStatus(t, s),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'active', child: Text('Set active')),
                PopupMenuItem(value: 'watch', child: Text('Set watch')),
                PopupMenuItem(value: 'pending', child: Text('Set pending')),
              ],
              child: _smallButtonLike('Status'),
            ),
            _smallButton('Delete', () => _deleteRestore(t, true), destructive: true),
          ],
        ]),
      ]),
    );
  }

  Widget _smallButton(String label, VoidCallback onTap, {bool destructive = false}) {
    return OutlinedButton(
      onPressed: _busy ? null : onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: destructive ? MM.red.withOpacity(0.5) : Colors.white24),
        foregroundColor: destructive ? MM.red : Colors.white70,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }

  Widget _smallButtonLike(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white24)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        const Icon(Icons.arrow_drop_down, size: 14, color: Colors.white54),
      ]),
    );
  }
}

// ─── Report queue ───────────────────────────────────────────────────────────

class _ReportsTab extends StatefulWidget {
  const _ReportsTab({required this.api});
  final AdminApiService api;

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  bool _loading = true;
  String? _error;
  List<Map> _reports = const [];
  String _status = 'open';
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
      final resp = await widget.api.listCantinaContent(type: 'reports', status: _status);
      if (!mounted) return;
      setState(() => _reports = ((resp['reports'] as List?) ?? const []).cast<Map>());
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resolve(Map r, bool resolve) async {
    final reason = await _promptReason(context, resolve ? 'Resolve report' : 'Dismiss report');
    if (reason == null) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await widget.api.moderateCantina(type: 'report', id: '${r['id']}', action: resolve ? 'resolve' : 'dismiss', reason: reason);
      await _load();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AdminPanel(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info_outline, size: 15, color: MM.yellow),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No client-side "report" button exists in the app yet, so this queue is real but empty — it\'s ready the moment '
                'reporting ships as a player-facing feature.',
                style: MM.body(size: 11.5, color: Colors.white.withOpacity(0.55)),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      Row(children: [
        for (final s in ['open', 'resolved', 'dismissed']) ...[
          ChoiceChip(
            label: Text(s),
            selected: _status == s,
            onSelected: (_) {
              setState(() => _status = s);
              _load();
            },
          ),
          const SizedBox(width: 8),
        ],
        const Spacer(),
        AdminRefreshButton(onTap: _load),
      ]),
      const SizedBox(height: 12),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: MM.blue))
            : _error != null
                ? AdminErrorView(message: _error!, onRetry: _load)
                : Stack(children: [
                    AdminPanel(
                      child: _reports.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text('No $_status reports.', style: MM.body(size: 12.5, color: Colors.white.withOpacity(0.5))),
                            )
                          : ListView.separated(
                              itemCount: _reports.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
                              itemBuilder: (context, i) => _reportRow(_reports[i]),
                            ),
                    ),
                    if (_busy) Positioned.fill(child: Container(color: Colors.black38, child: const Center(child: CircularProgressIndicator(color: MM.blue)))),
                  ]),
      ),
    ]);
  }

  Widget _reportRow(Map r) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${r['targetType']} · ${r['targetPath']}', style: MM.mono(size: 11.5, color: MM.white)),
            const SizedBox(height: 4),
            Text('"${r['reason']}"', style: MM.body(size: 12, color: Colors.white.withOpacity(0.7))),
            const SizedBox(height: 4),
            Text('${adminShortWhen('${r['createdAt'] ?? ''}')} · reported by ${r['reporterEmail'] ?? r['reporterId']}',
                style: MM.mono(size: 10.5, color: Colors.white.withOpacity(0.4))),
          ]),
        ),
        if (r['status'] == 'open') ...[
          OutlinedButton(onPressed: () => _resolve(r, true), child: const Text('Resolve', style: TextStyle(fontSize: 11))),
          const SizedBox(width: 6),
          OutlinedButton(onPressed: () => _resolve(r, false), child: const Text('Dismiss', style: TextStyle(fontSize: 11))),
        ],
      ]),
    );
  }
}

// ─── Banned words ──────────────────────────────────────────────────────────

class _BannedWordsTab extends StatefulWidget {
  const _BannedWordsTab({required this.api});
  final AdminApiService api;

  @override
  State<_BannedWordsTab> createState() => _BannedWordsTabState();
}

class _BannedWordsTabState extends State<_BannedWordsTab> {
  bool _loading = true;
  String? _error;
  List<String> _words = const [];
  final _newWordCtrl = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _newWordCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await widget.api.listCantinaContent(type: 'banned_words');
      if (!mounted) return;
      setState(() => _words = ((resp['words'] as List?) ?? const []).map((e) => '$e').toList());
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _publish(List<String> next) async {
    final reason = await _promptReason(context, 'Publish banned-word list');
    if (reason == null) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await widget.api.moderateCantina(type: 'banned_words', action: 'set', words: next, reason: reason);
      await _load();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: MM.blue));
    if (_error != null) return AdminErrorView(message: _error!, onRetry: _load);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AdminPanel(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info_outline, size: 15, color: MM.yellow),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Storage only — nothing scans new posts against this list yet (that\'s an AI moderation pass, later scope).',
                style: MM.body(size: 11.5, color: Colors.white.withOpacity(0.55)),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      Expanded(
        child: AdminPanel(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final w in _words)
                    Chip(
                      label: Text(w, style: const TextStyle(fontSize: 12)),
                      backgroundColor: MM.pageBg,
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: _busy ? null : () => _publish([..._words]..remove(w)),
                    ),
                  if (_words.isEmpty) Text('No banned words yet.', style: MM.body(size: 12.5, color: Colors.white.withOpacity(0.4))),
                ],
              ),
              const SizedBox(height: 16),
              Row(children: [
                SizedBox(
                  width: 240,
                  child: TextField(
                    controller: _newWordCtrl,
                    style: MM.body(size: 12.5, color: MM.white),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Add a word',
                      hintStyle: MM.body(size: 12, color: Colors.white.withOpacity(0.36)),
                      filled: true,
                      fillColor: MM.pageBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide(color: Colors.white.withOpacity(0.18))),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _busy
                      ? null
                      : () {
                          final w = _newWordCtrl.text.trim().toLowerCase();
                          if (w.isEmpty || _words.contains(w)) return;
                          _newWordCtrl.clear();
                          _publish([..._words, w]);
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: MM.blue),
                  child: const Text('Add + publish'),
                ),
              ]),
            ]),
          ),
        ),
      ),
    ]);
  }
}
