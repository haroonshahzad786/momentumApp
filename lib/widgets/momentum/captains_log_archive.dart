import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/checkin_service.dart';
import '../../theme/momentum_tokens.dart';

/// The Captain's Log archive (Momentum List #15, PRD 10/12): every 🏆 win and
/// 📚 lesson the player logged in daily check-ins, newest first, grouped by
/// day and Core. Read-only — entries are written by the check-in itself.
class CaptainsLogArchive extends StatefulWidget {
  const CaptainsLogArchive({super.key, this.days = 30});

  /// How many recent check-in days to show.
  final int days;

  @override
  State<CaptainsLogArchive> createState() => _CaptainsLogArchiveState();
}

class _CaptainsLogArchiveState extends State<CaptainsLogArchive> {
  static const _cores = {
    'mindset': ('🧠', 'Mindset'),
    'career': ('💰', 'Career & Finances'),
    'relationships': ('👥', 'Relationships'),
    'physical': ('💪', 'Physical Health'),
    'emotional': ('🧘', 'Emotional & Mental'),
  };

  List<DailyCheckin>? _days;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      setState(() => _days = const []);
      return;
    }
    setState(() => _error = null);
    try {
      final recent = await CheckinService().getRecent(uid, limit: widget.days);
      if (!mounted) return;
      setState(() => _days = recent.where((d) => d.captainsLog.isNotEmpty).toList());
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  String _when(String ymd) {
    final d = DateTime.tryParse(ymd);
    if (d == null) return ymd;
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const w = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${w[d.weekday - 1]} ${d.day} ${m[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final muted = Colors.white.withOpacity(0.55);
    if (_error != null) {
      return Row(children: [
        Expanded(child: Text("Couldn't load your Captain's Log.", style: MM.body(size: 12.5, color: muted))),
        TextButton(onPressed: _load, child: const Text('Retry')),
      ]);
    }
    final days = _days;
    if (days == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(color: MM.blue, strokeWidth: 2)),
      );
    }
    if (days.isEmpty) {
      return Text(
        "No entries yet. Add a win or a lesson for any Core during your daily check-in — "
        "they collect here and help Nova spot patterns.",
        style: MM.body(size: 12.5, color: muted),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final day in days) ...[
        Text(_when(day.date).toUpperCase(), style: MM.displayX(size: 10, color: muted)),
        const SizedBox(height: 6),
        for (final e in day.captainsLog.entries)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(color: MM.coreColor[e.key] ?? MM.blue, width: 3),
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('${_cores[e.key]?.$1 ?? '•'}  ${_cores[e.key]?.$2 ?? e.key}',
                    style: MM.body(size: 12.5, color: Colors.white, weight: FontWeight.w600)),
                const Spacer(),
                if (day.scores[e.key] != null)
                  Text('${day.scores[e.key]}/5', style: MM.mono(size: 11, color: muted)),
              ]),
              if (e.value.wins.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('🏆  ${e.value.wins.trim()}', style: MM.body(size: 12.5, color: Colors.white.withOpacity(0.85))),
              ],
              if (e.value.lessons.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('📚  ${e.value.lessons.trim()}',
                    style: MM.body(size: 12.5, color: Colors.white.withOpacity(0.85))),
              ],
            ]),
          ),
        const SizedBox(height: 10),
      ],
    ]);
  }
}
