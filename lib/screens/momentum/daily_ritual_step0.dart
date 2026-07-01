import 'package:flutter/material.dart';
import '../../models/momentum_list.dart';
import '../../services/momentum_lists_service.dart';
import '../../theme/momentum_tokens.dart';
import '../../widgets/momentum/glass_panel.dart';
import '../../widgets/momentum/mm_buttons.dart';
import '../../widgets/momentum/offline_banner.dart';
import '../../widgets/momentum/starfield.dart';
import 'sub_screens.dart';

/// Daily Ritual — Step 0 (Optional): Mantra & Grateful List.
///
/// Shown ahead of the Check-In scoring (PHASE 1 & 2 DETAILS §"STEP 0"). It
/// primes the player's emotional state before they review yesterday: read your
/// Mantra, scan your Grateful List, then continue to scoring. Skippable. The
/// caller (MomentumHome) remembers per-day completion so it appears at most
/// once a day — tapping "Continue to Scoring" marks today done; "Skip" does
/// not (so it can gently reappear later the same day).
class DailyRitualStep0 extends StatefulWidget {
  const DailyRitualStep0({
    super.key,
    required this.userId,
    required this.onContinue,
    required this.onSkip,
    required this.onClose,
  });

  final String userId;

  /// Player engaged / acknowledged → mark done for today + go to scoring.
  final VoidCallback onContinue;

  /// "I'll do this later" → go to scoring WITHOUT marking done.
  final VoidCallback onSkip;

  /// Close (X) → back to the dashboard without starting the check-in.
  final VoidCallback onClose;

  @override
  State<DailyRitualStep0> createState() => _DailyRitualStep0State();
}

class _DailyRitualStep0State extends State<DailyRitualStep0> {
  final _service = MomentumListsService();
  List<MomentumList> _lists = const [];
  bool _loading = true;
  bool _offline = false;

  // Lists are free-named server-side (no type metadata), so the Mantra and
  // Grateful buckets are matched by keyword, case-insensitive.
  static final _mantraRe = RegExp(r'mantra|affirmation', caseSensitive: false);
  static final _gratefulRe =
      RegExp(r'grateful|gratitude|thank', caseSensitive: false);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.userId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await _service.getAllLists(widget.userId);
      if (!mounted) return;
      setState(() {
        _lists = res.data;
        _offline = res.fromCache;
        _loading = false;
      });
    } catch (_) {
      // Best-effort: a load failure just shows the "set one up" prompts.
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  MomentumList? _match(RegExp re) {
    for (final l in _lists) {
      if (re.hasMatch(l.name)) return l;
    }
    return null;
  }

  /// Opens the full Command Center Lists screen (pre-expanding [focus] if it
  /// exists), then returns here on back — per spec, the lists "open from
  /// Command Center, then return here."
  void _openLists(MomentumList? focus) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ListsScreen(
        onBack: () => Navigator.of(context).maybePop(),
        expand: focus == null ? const <String>{} : <String>{focus.name},
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final mantra = _match(_mantraRe);
    final grateful = _match(_gratefulRe);
    return Scaffold(
      backgroundColor: MM.pageBg,
      body: Stack(
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          SafeArea(
            child: Column(
              children: [
                _header(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_offline) ...[
                          OfflineBanner(onRefresh: _load),
                          const SizedBox(height: 10),
                        ],
                        Text('🕉  PRIME YOUR STATE',
                            style: MM.displayX(size: 10, color: MM.violet)),
                        const SizedBox(height: 8),
                        Text(
                          "Haven't done your Mantra or Grateful List yet today?",
                          style: MM.display(size: 18, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Set your emotional state before reviewing "
                          "yesterday's performance.",
                          style: MM.body(
                            color: Colors.white.withOpacity(0.6),
                            size: 12.5,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _MantraCard(mantra: mantra, loading: _loading),
                        const SizedBox(height: 12),
                        _GratefulCard(grateful: grateful, loading: _loading),
                        const SizedBox(height: 18),
                        Row(children: [
                          Expanded(
                            child: MMGhostButton(
                              label: 'View Your Mantra',
                              expand: true,
                              borderColor: MM.violet.withOpacity(0.5),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              onPressed: () => _openLists(mantra),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: MMGhostButton(
                              label: 'View Grateful List',
                              expand: true,
                              borderColor: MM.teal.withOpacity(0.5),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              onPressed: () => _openLists(grateful),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
                _footer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      child: Row(children: [
        InkWell(
          onTap: widget.onClose,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.close, size: 18, color: Colors.white),
          ),
        ),
        Expanded(
          child: Center(
            child: Text('Daily Ritual',
                style: MM.displayX(size: 12, color: Colors.white)),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text('STEP 0',
              style: MM.display(size: 10, color: Colors.white)),
        ),
      ]),
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: Row(children: [
        Expanded(
          flex: 1,
          child: MMGhostButton(
            label: 'Skip',
            expand: true,
            padding: const EdgeInsets.symmetric(vertical: 14),
            onPressed: widget.onSkip,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: MMPrimaryButton(
            label: 'Continue to Scoring →',
            onPressed: widget.onContinue,
          ),
        ),
      ]),
    );
  }
}

/// The player's Mantra in a large quotation block. Falls back to a gentle
/// "set one up" prompt when no mantra list exists yet.
class _MantraCard extends StatelessWidget {
  const _MantraCard({required this.mantra, required this.loading});
  final MomentumList? mantra;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final text = mantra == null || mantra!.items.isEmpty
        ? null
        : mantra!.items.join('  ·  ');
    return GlassPanel(
      leftAccentColor: MM.violet,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🕉  YOUR MANTRA',
              style: MM.displayX(size: 9, color: MM.violet)),
          const SizedBox(height: 10),
          if (loading)
            _skeletonLine()
          else if (text == null)
            Text(
              'No Mantra set yet — tap “View Your Mantra” to add one in '
              'Command Center.',
              style: MM.body(
                  color: Colors.white.withOpacity(0.55), size: 12.5),
            )
          else
            Text(
              '"$text"',
              style: MM
                  .display(size: 16, color: Colors.white, height: 1.45)
                  .copyWith(fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }
}

/// The player's Grateful List items as a short bulleted scan.
class _GratefulCard extends StatelessWidget {
  const _GratefulCard({required this.grateful, required this.loading});
  final MomentumList? grateful;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final items = grateful?.items ?? const <String>[];
    final shown = items.take(5).toList();
    return GlassPanel(
      leftAccentColor: MM.teal,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🙏  GRATEFUL FOR',
              style: MM.displayX(size: 9, color: MM.teal)),
          const SizedBox(height: 10),
          if (loading)
            _skeletonLine()
          else if (shown.isEmpty)
            Text(
              'No Grateful List yet — tap “View Grateful List” to start one '
              'in Command Center.',
              style: MM.body(
                  color: Colors.white.withOpacity(0.55), size: 12.5),
            )
          else
            ...shown.map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6, right: 8),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                              color: MM.teal, shape: BoxShape.circle),
                        ),
                      ),
                      Expanded(
                        child: Text(g,
                            style: MM.body(color: Colors.white, size: 13)),
                      ),
                    ],
                  ),
                )),
          if (!loading && items.length > shown.length) ...[
            const SizedBox(height: 4),
            Text('+${items.length - shown.length} more',
                style: MM.body(
                    color: Colors.white.withOpacity(0.45), size: 11)),
          ],
        ],
      ),
    );
  }
}

Widget _skeletonLine() => Container(
      height: 14,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(4),
      ),
    );
