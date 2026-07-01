import 'package:flutter/material.dart';

import '../../theme/momentum_tokens.dart';
import '../../widgets/momentum/mm_buttons.dart';
import '../../widgets/momentum/starfield.dart';

/// The habit the player composed on [AddHabitPage], handed back to the
/// Routines screen via [Navigator.pop]. Mirrors the design's `addHabit`
/// payload (screens.jsx · AddHabitModal).
class NewHabitDraft {
  const NewHabitDraft({
    required this.name,
    required this.isRoutine,
    required this.coreId,
    required this.coreLabel,
    this.blockId,
  });

  final String name;
  final bool isRoutine;
  final String coreId; // full backend id, e.g. 'physical_health_core'
  final String coreLabel; // short label, e.g. 'Physical'
  final String? blockId; // null for non-routine (no schedule)
}

class _Core {
  const _Core(this.id, this.label, this.hex, this.icon);
  final String id;
  final String label;
  final Color hex;
  final String icon;
}

// Full backend core ids so the new habit slots straight into the Routines
// list's existing per-core colour / icon maps.
const List<_Core> _cores = [
  _Core('mindset_core', 'Mindset', MM.blue, '🧠'),
  _Core('career_finance_core', 'Career', MM.yellow, '💰'),
  _Core('relationships_core', 'Relationships', MM.magenta, '👥'),
  _Core('physical_health_core', 'Physical', MM.teal, '💪'),
  _Core('emotional_mental_core', 'Emotional', MM.violet, '🧘'),
];

class _Block {
  const _Block(this.id, this.label, this.time);
  final String id;
  final String label;
  final String time;
}

const List<_Block> _blocks = [
  _Block('morning', 'MORNING', '06:30'),
  _Block('workday', 'WORKDAY', '09:00'),
  _Block('evening', 'EVENING', '21:00'),
];

/// Keyword → Core suggestion (stands in for the Phase-1 AI core assignment).
/// Ported verbatim from screens.jsx · suggestCore.
String _suggestCore(String name) {
  final n = name.toLowerCase();
  if (RegExp(r'run|gym|lift|walk|stretch|yoga|sleep|hydrate|water|workout|strength|steps')
      .hasMatch(n)) {
    return 'physical_health_core';
  }
  if (RegExp(r'money|budget|invoice|work|email|finance|save|invest|client|deep work')
      .hasMatch(n)) {
    return 'career_finance_core';
  }
  if (RegExp(r'call|text|friend|family|partner|date|connect|reach out|coffee with')
      .hasMatch(n)) {
    return 'relationships_core';
  }
  if (RegExp(r'journal|gratitude|breath|vent|therapy|mood|feel|rest|reflect')
      .hasMatch(n)) {
    return 'emotional_mental_core';
  }
  return 'mindset_core';
}

_Core _coreById(String id) =>
    _cores.firstWhere((c) => c.id == id, orElse: () => _cores.first);

/// Full-screen "Add a habit" form reached from the Routines ADD button.
/// Pops a [NewHabitDraft] on save, or null on cancel.
class AddHabitPage extends StatefulWidget {
  const AddHabitPage({super.key});

  @override
  State<AddHabitPage> createState() => _AddHabitPageState();
}

class _AddHabitPageState extends State<AddHabitPage> {
  final _nameCtrl = TextEditingController();
  bool _isRoutine = true; // routine | non-routine — the defining choice
  String _block = 'morning';
  String? _core; // null → use the Nova suggestion

  @override
  void initState() {
    super.initState();
    // The suggested core tracks the name as it's typed.
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String get _name => _nameCtrl.text.trim();
  bool get _canSave => _name.isNotEmpty;
  String get _suggested => _suggestCore(_name);
  String get _activeCoreId => _core ?? _suggested;

  void _save() {
    if (!_canSave) return;
    final core = _coreById(_activeCoreId);
    Navigator.of(context).pop(NewHabitDraft(
      name: _name,
      isRoutine: _isRoutine,
      coreId: core.id,
      coreLabel: core.label,
      blockId: _isRoutine ? _block : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final hex = _coreById(_activeCoreId).hex;
    return Scaffold(
      backgroundColor: MM.pageBg,
      body: Stack(
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).maybePop(),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: MM.navy.withOpacity(0.55),
                            border:
                                Border.all(color: Colors.white.withOpacity(0.12)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('ADD A HABIT',
                          style: MM.displayX(size: 12, color: hex)),
                    ],
                  ),
                ),
                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('HABIT NAME'),
                        const SizedBox(height: 6),
                        _nameField(hex),
                        const SizedBox(height: 18),
                        _label('HABIT TYPE'),
                        const SizedBox(height: 6),
                        _typeChooser(hex),
                        if (_isRoutine) ...[
                          const SizedBox(height: 18),
                          _label('WHEN · TIME BLOCK'),
                          const SizedBox(height: 6),
                          _blockChooser(),
                        ],
                        const SizedBox(height: 18),
                        _coreHeader(),
                        const SizedBox(height: 8),
                        _coreChooser(),
                        const SizedBox(height: 16),
                        _forgeNote(),
                      ],
                    ),
                  ),
                ),
                // Actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: MMGhostButton(
                          label: 'Cancel',
                          expand: true,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: MMPrimaryButton(
                          label: 'Add Habit',
                          padding:
                              const EdgeInsets.symmetric(vertical: 15),
                          onPressed: _canSave ? _save : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: MM.displayX(size: 9, color: Colors.white.withOpacity(0.55)));

  Widget _nameField(Color hex) {
    return TextField(
      controller: _nameCtrl,
      autofocus: true,
      style: MM.body(color: Colors.white, size: 14),
      cursorColor: hex,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _save(),
      decoration: InputDecoration(
        hintText: 'e.g. 10-minute morning walk',
        hintStyle: MM.body(color: Colors.white.withOpacity(0.4), size: 14),
        filled: true,
        fillColor: MM.navy.withOpacity(0.55),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: hex.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: hex, width: 1.5),
        ),
      ),
    );
  }

  Widget _typeChooser(Color hex) {
    const opts = [
      ('routine', 'Routine', 'Daily schedule. Turns green & stays in this list.'),
      (
        'non_routine',
        'Non-routine',
        'Identity habit. Graduates to the Trophy Room.'
      ),
    ];
    return Row(
      children: [
        for (final o in opts) ...[
          Expanded(
            child: _TypeCard(
              title: o.$2,
              desc: o.$3,
              hex: hex,
              selected: (_isRoutine ? 'routine' : 'non_routine') == o.$1,
              onTap: () => setState(() => _isRoutine = o.$1 == 'routine'),
            ),
          ),
          if (o.$1 == 'routine') const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _blockChooser() {
    return Row(
      children: [
        for (var i = 0; i < _blocks.length; i++) ...[
          Expanded(
            child: _BlockPill(
              block: _blocks[i],
              selected: _block == _blocks[i].id,
              onTap: () => setState(() => _block = _blocks[i].id),
            ),
          ),
          if (i < _blocks.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }

  Widget _coreHeader() {
    final s = _coreById(_suggested);
    return Row(
      children: [
        _label('CORE'),
        const SizedBox(width: 8),
        Flexible(
          child: Text('✦ NOVA SUGGESTS ${s.label.toUpperCase()}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MM.displayX(size: 9, color: s.hex)),
        ),
      ],
    );
  }

  Widget _coreChooser() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final c in _cores)
          _CorePill(
            core: c,
            selected: _activeCoreId == c.id,
            suggested: _core == null && _suggested == c.id,
            onTap: () => setState(() => _core = c.id),
          ),
      ],
    );
  }

  Widget _forgeNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: MM.navy.withOpacity(0.4),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Text.rich(
        TextSpan(
          style: MM.body(color: Colors.white.withOpacity(0.5), size: 10.5),
          children: [
            const TextSpan(text: 'Minimal setup — you can run the full '),
            TextSpan(
              text: 'Golden Habit Forge',
              style: MM.body(
                  color: Colors.white.withOpacity(0.75),
                  size: 10.5,
                  weight: FontWeight.w700),
            ),
            const TextSpan(
                text: ' (Phase 1) later to add cues, MBM strategies and your '
                    'Back-to-the-Future vision.'),
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.title,
    required this.desc,
    required this.hex,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String desc;
  final Color hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? hex.withOpacity(0.12) : MM.navy.withOpacity(0.45),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? hex : Colors.white.withOpacity(0.12),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: hex.withOpacity(0.27), blurRadius: 12)]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: MM.display(
                    size: 13,
                    color: selected ? Colors.white : Colors.white.withOpacity(0.8))),
            const SizedBox(height: 4),
            Text(desc,
                style: MM.body(color: Colors.white.withOpacity(0.6), size: 10)),
          ],
        ),
      ),
    );
  }
}

class _BlockPill extends StatelessWidget {
  const _BlockPill({
    required this.block,
    required this.selected,
    required this.onTap,
  });
  final _Block block;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        decoration: BoxDecoration(
          color: selected
              ? MM.teal.withOpacity(0.18)
              : MM.navy.withOpacity(0.45),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? MM.teal : Colors.white.withOpacity(0.12),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(block.label,
                style: MM.displayX(
                    size: 8,
                    color: selected ? Colors.white : Colors.white.withOpacity(0.7))),
            const SizedBox(height: 3),
            Text(block.time,
                style: MM.mono(
                    size: 10,
                    color: selected ? MM.teal : Colors.white.withOpacity(0.5))),
          ],
        ),
      ),
    );
  }
}

class _CorePill extends StatelessWidget {
  const _CorePill({
    required this.core,
    required this.selected,
    required this.suggested,
    required this.onTap,
  });
  final _Core core;
  final bool selected;
  final bool suggested;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? core.hex.withOpacity(0.13) : MM.navy.withOpacity(0.45),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? core.hex
                : (suggested
                    ? core.hex.withOpacity(0.47)
                    : Colors.white.withOpacity(0.12)),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: core.hex.withOpacity(0.33), blurRadius: 10)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(core.icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Text(core.label,
                style: MM.body(
                    color: selected ? Colors.white : Colors.white.withOpacity(0.75),
                    size: 12)),
          ],
        ),
      ),
    );
  }
}
