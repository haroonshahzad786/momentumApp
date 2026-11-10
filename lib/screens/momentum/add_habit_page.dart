import 'package:flutter/material.dart';

import '../../services/routine_schedule.dart';
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
    this.anchorId,
    this.scheduledTime,
    this.triggers = const [],
  });

  final String name;
  final bool isRoutine;
  final String coreId; // full backend id, e.g. 'physical_health_core'
  final String coreLabel; // short label, e.g. 'Physical'
  final String? blockId; // null for non-routine (no schedule)

  /// Routine slot: an anchor id, or a set time (HH:mm) — never both.
  final String? anchorId;
  final String? scheduledTime;

  /// Non-routine: what triggers it ("Stress spikes").
  final List<String> triggers;
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
  const AddHabitPage({
    super.key,
    this.embedded = false,
    this.initialCoreId,
    this.initialAnchorId,
  });

  /// Preselects a Core ("+ Add to Physical") / an anchor ("Stack a habit on…").
  final String? initialCoreId;
  final String? initialAnchorId;

  /// Inside a web dialog: no Scaffold / starfield / safe area, and the form
  /// sizes to its content instead of filling the screen.
  final bool embedded;

  @override
  State<AddHabitPage> createState() => _AddHabitPageState();
}

class _AddHabitPageState extends State<AddHabitPage> {
  final _nameCtrl = TextEditingController();
  bool _isRoutine = true; // routine | non-routine — the defining choice
  String _block = 'morning';
  String? _core; // null → use the Nova suggestion
  String? _anchorId = 'after_breakfast';
  bool _setTime = false;
  final _timeCtrl = TextEditingController(text: '07:00');
  final _triggerCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _core = widget.initialCoreId;
    if (widget.initialAnchorId != null) _anchorId = widget.initialAnchorId;
    // The suggested core tracks the name as it's typed.
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _timeCtrl.dispose();
    _triggerCtrl.dispose();
    super.dispose();
  }

  String get _name => _nameCtrl.text.trim();
  bool get _canSave =>
      _name.isNotEmpty && (!_isRoutine || !_setTime || parseHm(_timeCtrl.text) != null);
  String get _suggested => _suggestCore(_name);
  String get _activeCoreId => _core ?? _suggested;

  void _save() {
    if (!_canSave) return;
    final core = _coreById(_activeCoreId);
    // The per-Core list line still carries a coarse block word (Routines/Habits
    // read it); derive it from the chosen slot.
    final mins = !_isRoutine
        ? null
        : _setTime
            ? parseHm(_timeCtrl.text)
            : kDefaultAnchors
                .firstWhere((a) => a.id == _anchorId,
                    orElse: () => kDefaultAnchors[1])
                .minutes;
    final block = mins == null
        ? null
        : (mins < 720 ? 'morning' : (mins < 1020 ? 'workday' : 'evening'));
    Navigator.of(context).pop(NewHabitDraft(
      name: _name,
      isRoutine: _isRoutine,
      coreId: core.id,
      coreLabel: core.label,
      blockId: block,
      anchorId: _isRoutine && !_setTime ? _anchorId : null,
      scheduledTime: _isRoutine && _setTime ? _timeCtrl.text.trim() : null,
      triggers: _isRoutine
          ? const []
          : [
              for (final t in _triggerCtrl.text.split(','))
                if (t.trim().isNotEmpty) t.trim(),
            ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final hex = _coreById(_activeCoreId).hex;
    if (widget.embedded) {
      return Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [_header(hex), Flexible(child: _form(hex)), _actions()],
        ),
      );
    }
    return Scaffold(
      backgroundColor: MM.pageBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          SafeArea(
            child: Column(
              children: [
                _header(hex),
                Expanded(child: _form(hex)),
                _actions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(Color hex) => Padding(
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
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            Text('ADD A HABIT', style: MM.displayX(size: 12, color: hex)),
          ],
        ),
      );

  Widget _form(Color hex) => SingleChildScrollView(
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
              _label('WHEN · ANCHOR OR SET TIME'),
              const SizedBox(height: 6),
              _slotChooser(hex),
            ] else ...[
              const SizedBox(height: 18),
              _label('TRIGGERS WHEN (COMMA-SEPARATED)'),
              const SizedBox(height: 6),
              _plainField(_triggerCtrl, 'e.g. Stress spikes, Before a hard conversation', hex),
            ],
            const SizedBox(height: 18),
            _coreHeader(),
            const SizedBox(height: 8),
            _coreChooser(),
            const SizedBox(height: 16),
            _forgeNote(),
          ],
        ),
      );

  Widget _actions() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Row(
          children: [
            Expanded(
              child: MMGhostButton(
                label: 'Cancel',
                expand: true,
                padding: const EdgeInsets.symmetric(vertical: 14),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: MMPrimaryButton(
                label: 'Add Habit',
                padding: const EdgeInsets.symmetric(vertical: 15),
                onPressed: _canSave ? _save : null,
              ),
            ),
          ],
        ),
      );

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

  Widget _plainField(TextEditingController c, String hint, Color hex,
      {ValueChanged<String>? onChanged}) {
    return TextField(
      controller: c,
      onChanged: onChanged,
      style: MM.body(color: Colors.white, size: 14),
      cursorColor: hex,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: MM.body(color: Colors.white.withOpacity(0.4), size: 13),
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

  /// Routine slot: stack on an anchor ("After breakfast") or pin a set time.
  Widget _slotChooser(Color hex) {
    Widget pill(String label, bool on, VoidCallback tap) => InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: tap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: on ? hex.withOpacity(0.16) : MM.navy.withOpacity(0.45),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                  color: on ? hex : Colors.white.withOpacity(0.12)),
            ),
            child: Text(label,
                style: MM.body(
                    size: 12,
                    color: on ? Colors.white : Colors.white.withOpacity(0.7))),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final a in kDefaultAnchors)
          pill(a.label, !_setTime && _anchorId == a.id,
              () => setState(() {
                    _setTime = false;
                    _anchorId = a.id;
                  })),
        pill('Set time', _setTime, () => setState(() => _setTime = true)),
      ]),
      if (_setTime) ...[
        const SizedBox(height: 8),
        _plainField(_timeCtrl, 'HH:mm, e.g. 07:00', hex,
            onChanged: (_) => setState(() {})),
      ],
    ]);
  }

  // ignore: unused_element
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
