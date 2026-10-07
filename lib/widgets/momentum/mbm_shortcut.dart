import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/golden_habit.dart';
import '../../services/cantina_ideas_service.dart';
import '../../services/habits_service.dart';
import '../../services/offline.dart';
import '../../services/onboarding_service.dart';
import '../../theme/momentum_tokens.dart';
import 'glass_panel.dart';
import 'mm_buttons.dart';

/// MBM Shortcut — New Golden Habits (Returning Players), P1-6. Phase 1 & 2
/// Details: "Every time a returning player creates a new Golden Habit through
/// Phase 1, Stage 1, they are offered the option to attach MBMs to that habit
/// immediately — without going through the full MBS process. Three entry
/// paths": Full MBS · Quick Add from Space Cantina Ideas Well · Manual Entry.
/// In the last two "No AI questions asked; the strategy is tagged and nested
/// immediately", and the player can return to the full MBS any time.

/// The 3 MBM categories a shortcut strategy is filed under.
enum MbmKind {
  obvious('🔍', 'Make it Obvious', 'makeObvious'),
  easy('⚡', 'Make it Easy', 'makeEasy'),
  rewarding('🎉', 'Make it Rewarding', 'makeRewarding');

  const MbmKind(this.emoji, this.label, this.field);
  final String emoji;
  final String label;

  /// GoldenHabit / flutterUpdateGoldenHabitDetail field this kind fills.
  final String field;
}

/// Ideas Well MBM strategies for a habit in [core] (short id): that Core's
/// first, then the rest, most-upvoted first within each.
List<CantinaIdea> mbmIdeasFor(List<CantinaIdea> ideas, String core) {
  final mbm =
      ideas.where((i) => i.kind == 'mbm').toList()..sort((a, b) {
        final ca = a.core == core ? 0 : 1;
        final cb = b.core == core ? 0 : 1;
        return ca != cb ? ca - cb : b.upvotes.compareTo(a.upvotes);
      });
  return mbm;
}

/// Adds [strategy] to an existing MBM field without losing what's there.
String appendMbm(String existing, String strategy) {
  final e = existing.trim();
  final s = strategy.trim();
  if (s.isEmpty) return e;
  if (e.isEmpty) return s;
  if (e.toLowerCase().contains(s.toLowerCase())) return e;
  return '$e\n$s';
}

/// The three entry paths. [onFull] → the Nova MBS; [onIdeas] / [onManual] →
/// [MbmAttachView]; [onLater] skips for now.
class MbmShortcutChooser extends StatelessWidget {
  const MbmShortcutChooser({
    super.key,
    required this.onFull,
    required this.onIdeas,
    required this.onManual,
    required this.onLater,
  });

  final VoidCallback onFull;
  final VoidCallback onIdeas;
  final VoidCallback onManual;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    Widget option(
      String emoji,
      String title,
      String body,
      VoidCallback onTap,
    ) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: GlassPanel(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: MM.body(
                        color: Colors.white,
                        size: 14,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: MM.body(
                        color: Colors.white.withOpacity(0.65),
                        size: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'GOLDEN HABIT FORGED ✓',
          style: MM.displayX(size: 11, color: MM.teal),
        ),
        const SizedBox(height: 6),
        Text(
          'Make it automatic — how do you want to add its MBMs?',
          style: MM.display(size: 18, color: Colors.white),
        ),
        const SizedBox(height: 18),
        option(
          '🚀',
          'Full MBS with Nova',
          'Recommended for a new Core, or when you\'re not sure which strategy will work best.',
          onFull,
        ),
        option(
          '🛸',
          'Quick add from the Ideas Well',
          'Pick a community-upvoted strategy, tweak it, attach it. No questions.',
          onIdeas,
        ),
        option(
          '✍️',
          'Enter my own',
          'You already know what works for you — type it and file it.',
          onManual,
        ),
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: onLater,
            child: Text(
              'Later',
              style: MM.body(color: Colors.white60, size: 13),
            ),
          ),
        ),
      ],
    );
  }
}

/// Quick Add ([fromIdeas]) or Manual Entry: attach one strategy to the
/// newest Golden Habit, filed under an MBM category. [onDone] after saving.
class MbmAttachView extends StatefulWidget {
  const MbmAttachView({
    super.key,
    required this.fromIdeas,
    required this.onDone,
    required this.onBack,
    this.habitId,
  });

  final bool fromIdeas;
  final VoidCallback onDone;
  final VoidCallback onBack;

  /// The habit to attach to; null = the newest (the one just forged).
  final String? habitId;

  @override
  State<MbmAttachView> createState() => _MbmAttachViewState();
}

class _MbmAttachViewState extends State<MbmAttachView> {
  final _habits = HabitsService();
  final _onboarding = OnboardingService();
  final _ideasSvc = CantinaIdeasService();
  final _text = TextEditingController();

  GoldenHabit? _habit;
  List<CantinaIdea> _ideas = const [];
  CantinaIdea? _picked;
  MbmKind? _kind;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _habits.dispose();
    _onboarding.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final id =
          widget.habitId ?? (await _onboarding.activeHabit(_uid))?.habitId;
      final all = (await _habits.getGoldenHabits(_uid)).data;
      final habit = all.where((h) => h.habitId == id).firstOrNull;
      var ideas = const <CantinaIdea>[];
      if (widget.fromIdeas && habit != null) {
        final feed = await _ideasSvc.getFeed(_uid);
        ideas = mbmIdeasFor(feed.ideas, GoldenHabitRef.shortCore(habit.coreId));
      }
      if (!mounted) return;
      setState(() {
        _habit = habit;
        _ideas = ideas;
        _loading = false;
        if (habit == null) _error = 'No Golden Habit found';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = isNetworkError(e) ? "You're offline" : "Couldn't load";
        });
      }
    }
  }

  void _pick(CantinaIdea idea) => setState(() {
    _picked = idea;
    _text.text =
        idea.desc.trim().isNotEmpty
            ? '${idea.title.trim()} — ${idea.desc.trim()}'
            : idea.title.trim();
  });

  Future<void> _save() async {
    final h = _habit;
    final kind = _kind;
    final strategy = _text.text.trim();
    if (h == null || kind == null || strategy.isEmpty) return;
    setState(() => _saving = true);
    try {
      final current = '${h.toJson()[kind.field] ?? ''}';
      await _habits.updateHabitDetail(
        userId: _uid,
        habitId: h.habitId,
        fields: {kind.field: appendMbm(current, strategy)},
      );
      final picked = _picked;
      if (picked != null) await _ideasSvc.markAdopted(_uid, picked.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${kind.emoji} Attached to ${h.habitName}',
            style: MM.body(color: Colors.white, size: 12),
          ),
          backgroundColor: MM.teal.withOpacity(0.92),
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onDone();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNetworkError(e)
                ? "You're offline — nothing saved"
                : "Couldn't save — try again",
            style: MM.body(color: Colors.white, size: 12),
          ),
          backgroundColor: MM.red.withOpacity(0.92),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(child: CircularProgressIndicator(color: MM.yellow)),
      );
    }
    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!, style: MM.display(size: 15, color: Colors.white)),
          const SizedBox(height: 12),
          MMGhostButton(label: 'Retry', onPressed: _load),
          const SizedBox(height: 8),
          MMGhostButton(label: 'Back', onPressed: widget.onBack),
        ],
      );
    }
    final h = _habit!;
    final showForm = !widget.fromIdeas || _picked != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.fromIdeas ? 'QUICK ADD · IDEAS WELL' : 'ENTER MY OWN MBM',
          style: MM.displayX(size: 11, color: MM.yellow),
        ),
        const SizedBox(height: 6),
        Text(h.habitName, style: MM.display(size: 18, color: Colors.white)),
        const SizedBox(height: 14),
        if (widget.fromIdeas && _picked == null) ..._ideaList(),
        if (showForm) ..._form(),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed:
                widget.fromIdeas && _picked != null
                    ? () => setState(() => _picked = null)
                    : widget.onBack,
            child: Text(
              widget.fromIdeas && _picked != null ? '← Other ideas' : '← Back',
              style: MM.body(color: Colors.white60, size: 13),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _ideaList() {
    if (_ideas.isEmpty) {
      return [
        Text(
          'No MBM strategies in the Ideas Well yet — enter your own instead.',
          style: MM.body(color: Colors.white.withOpacity(0.6), size: 12),
        ),
      ];
    }
    return [
      for (final idea in _ideas.take(12))
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _pick(idea),
            child: GlassPanel(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          idea.title,
                          style: MM.body(
                            color: Colors.white,
                            size: 13,
                            weight: FontWeight.w600,
                          ),
                        ),
                        if (idea.desc.trim().isNotEmpty)
                          Text(
                            idea.desc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: MM.body(
                              color: Colors.white.withOpacity(0.6),
                              size: 11.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '▲ ${idea.upvotes}',
                    style: MM.body(color: MM.yellow, size: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _form() => [
    Text(
      widget.fromIdeas ? 'Make it yours:' : 'Your strategy:',
      style: MM.body(color: Colors.white.withOpacity(0.7), size: 12),
    ),
    const SizedBox(height: 6),
    TextField(
      controller: _text,
      minLines: 2,
      maxLines: 5,
      onChanged: (_) => setState(() {}),
      style: MM.body(color: Colors.white, size: 13),
      decoration: InputDecoration(
        hintText: 'e.g. Leave my running shoes by the door the night before',
        hintStyle: MM.body(color: Colors.white.withOpacity(0.35), size: 12),
        filled: true,
        fillColor: MM.navy.withOpacity(0.55),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    const SizedBox(height: 12),
    Text(
      'Which method is it?',
      style: MM.body(color: Colors.white.withOpacity(0.7), size: 12),
    ),
    const SizedBox(height: 6),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final k in MbmKind.values)
          ChoiceChip(
            label: Text('${k.emoji} ${k.label}'),
            selected: _kind == k,
            onSelected: (_) => setState(() => _kind = k),
          ),
      ],
    ),
    const SizedBox(height: 14),
    MMPrimaryButton(
      label: 'Attach to my Golden Habit',
      busy: _saving,
      padding: const EdgeInsets.symmetric(vertical: 13),
      onPressed:
          _saving || _kind == null || _text.text.trim().isEmpty ? null : _save,
    ),
  ];
}
