import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../models/admin_models.dart';
import '../../models/language.dart';
import '../../models/puzzle.dart';
import '../../repositories/admin_repository.dart';
import '../../core/theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/error_view.dart';

/// Add or edit a puzzle. PUT sends every field (full replace).
class PuzzleFormScreen extends StatefulWidget {
  const PuzzleFormScreen({super.key, this.puzzle});

  final AdminPuzzle? puzzle;

  @override
  State<PuzzleFormScreen> createState() => _PuzzleFormScreenState();
}

class _PuzzleFormScreenState extends State<PuzzleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _prompt;
  late final TextEditingController _hint;
  late final TextEditingController _answer;
  // Learn card
  late final TextEditingController _explanation;
  late final TextEditingController _trEn;
  late final TextEditingController _trFil;
  late final TextEditingController _trPag;
  late final TextEditingController _glossary;
  late final TextEditingController _funFact;

  late String _type;
  late String _difficulty;
  late int _maxTries;
  String? _level; // null = every level
  final List<TextEditingController> _choices = List.generate(4, (_) => TextEditingController());
  int? _languageId;
  int? _categoryId;
  String? _scheduledFor;

  List<Language> _languages = [];
  List<PuzzleCategory> _categories = [];
  bool _loadingLists = true;
  bool _saving = false;
  Map<String, String?> _errors = {};

  bool get _editing => widget.puzzle != null;

  @override
  void initState() {
    super.initState();
    final p = widget.puzzle;
    _prompt = TextEditingController(text: p?.prompt ?? '');
    _hint = TextEditingController(text: p?.hint ?? '');
    _answer = TextEditingController(text: p?.answer ?? '');
    _explanation = TextEditingController(text: p?.explanation ?? '');
    _trEn = TextEditingController(text: p?.translationEn ?? '');
    _trFil = TextEditingController(text: p?.translationFil ?? '');
    _trPag = TextEditingController(text: p?.translationPag ?? '');
    _glossary = TextEditingController(text: p?.glossary ?? '');
    _funFact = TextEditingController(text: p?.funFact ?? '');
    _type = p?.type ?? PuzzleType.bugtong;
    _difficulty = p?.difficulty ?? 'easy';
    _maxTries = p?.maxTries ?? 4;
    _level = p?.level;
    for (var i = 0; i < _choices.length && i < (p?.choices.length ?? 0); i++) {
      _choices[i].text = p!.choices[i];
    }
    _languageId = p?.languageId;
    _categoryId = p?.categoryId;
    _scheduledFor = p?.scheduledFor;
    _loadLists();
  }

  @override
  void dispose() {
    _prompt.dispose();
    _hint.dispose();
    _answer.dispose();
    for (final c in [_explanation, _trEn, _trFil, _trPag, _glossary, _funFact, ..._choices]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadLists() async {
    final repo = context.read<AdminRepository>();
    try {
      final results = await Future.wait([repo.languages(), repo.categories()]);
      _languages = results[0] as List<Language>;
      _categories = results[1] as List<PuzzleCategory>;
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
    if (mounted) setState(() => _loadingLists = false);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _scheduledFor != null ? DateTime.tryParse(_scheduledFor!) ?? now : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      setState(() => _scheduledFor = '${picked.year}-$m-$d');
    }
  }

  List<String> _choiceValues() => _choices.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

  static String? _textOrNull(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    setState(() => _errors = {});
    if (!_formKey.currentState!.validate()) return;
    if (_languageId == null || _categoryId == null) {
      showSnack(context, 'Choose a language and a category.', error: true);
      return;
    }
    if (_type == PuzzleType.daily && _scheduledFor == null) {
      showSnack(context, 'A daily puzzle needs a date.', error: true);
      return;
    }

    final body = {
      'type': _type,
      'difficulty': _difficulty,
      'language_id': _languageId,
      'category_id': _categoryId,
      'prompt': _prompt.text.trim(),
      'hint': _hint.text.trim().isEmpty ? null : _hint.text.trim(),
      'answer': _answer.text.trim(),
      'max_tries': _maxTries,
      'level': PuzzleType.leveled.contains(_type) ? _level : null,
      'choices': _choiceValues().isEmpty ? null : _choiceValues(),
      'scheduled_for': _type == PuzzleType.daily ? _scheduledFor : null,
      'explanation': _textOrNull(_explanation),
      'translation_en': _textOrNull(_trEn),
      'translation_fil': _textOrNull(_trFil),
      'translation_pag': _textOrNull(_trPag),
      'glossary': _textOrNull(_glossary),
      'fun_fact': _textOrNull(_funFact),
    };

    setState(() => _saving = true);
    try {
      final repo = context.read<AdminRepository>();
      if (_editing) {
        await repo.updatePuzzle(widget.puzzle!.id, body);
      } else {
        await repo.createPuzzle(body);
      }
      if (!mounted) return;
      showSnack(context, 'Puzzle saved.');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errors = {
          'prompt': e.fieldError('prompt'),
          'answer': e.fieldError('answer'),
          'scheduled_for': e.fieldError('scheduled_for'),
          'choices': e.fieldError('choices'),
        };
      });
      showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: _editing ? 'Edit puzzle' : 'New puzzle',
        subtitle: _editing ? '${PuzzleType.label(widget.puzzle!.type)} · ${widget.puzzle!.attemptsCount} plays' : 'Admin · Puzzles',
      ),
      body: _loadingLists
          ? const LoadingView()
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text('Game type', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: PuzzleType.all
                          .map((t) => ChoiceChip(
                                label: Text(PuzzleType.label(t)),
                                selected: _type == t,
                                onSelected: (_) => setState(() => _type = t),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Difficulty', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'easy', label: Text('Easy 10')),
                        ButtonSegment(value: 'medium', label: Text('Medium 20')),
                        ButtonSegment(value: 'hard', label: Text('Hard 30')),
                      ],
                      selected: {_difficulty},
                      onSelectionChanged: (s) => setState(() => _difficulty = s.first),
                    ),
                    if (PuzzleType.leveled.contains(_type)) ...[
                      const SizedBox(height: 16),
                      const Text('School level', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [null, ...SchoolLevel.all]
                            .map((l) => ChoiceChip(
                                  label: Text(l == null ? 'All levels' : SchoolLevel.label(l)),
                                  selected: _level == l,
                                  onSelected: (_) => setState(() => _level = l),
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    DropdownMenu<int>(
                      expandedInsets: EdgeInsets.zero,
                      label: const Text('Language of the answer'),
                      initialSelection: _languageId,
                      onSelected: (v) => setState(() => _languageId = v),
                      dropdownMenuEntries: _languages.map((l) => DropdownMenuEntry<int>(value: l.id, label: l.name)).toList(),
                    ),
                    const SizedBox(height: 16),
                    DropdownMenu<int>(
                      expandedInsets: EdgeInsets.zero,
                      label: const Text('Category'),
                      initialSelection: _categoryId,
                      onSelected: (v) => setState(() => _categoryId = v),
                      dropdownMenuEntries: _categories.map((c) => DropdownMenuEntry<int>(value: c.id, label: c.name)).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _prompt,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: _type == PuzzleType.scramble ? 'Scrambled letters (e.g. LOOHCS)' : 'Prompt / riddle',
                        errorText: _errors['prompt'],
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(controller: _hint, decoration: const InputDecoration(labelText: 'Hint (optional)')),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _answer,
                      decoration: InputDecoration(
                        labelText: 'Answer (never shown to students before they finish)',
                        errorText: _errors['answer'],
                      ),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Required';
                        if (_type == PuzzleType.daily && !RegExp(r'^[A-Za-zÑñ]+$').hasMatch(value)) return 'Letters only';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Maximum tries', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          onPressed: _maxTries > 1 ? () => setState(() => _maxTries--) : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('$_maxTries', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          onPressed: _maxTries < 10 ? () => setState(() => _maxTries++) : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    if (_type == PuzzleType.daily) ...[
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event),
                        title: Text(_scheduledFor ?? 'Choose the date for this daily puzzle'),
                        subtitle: _errors['scheduled_for'] != null
                            ? Text(_errors['scheduled_for']!, style: TextStyle(color: Colors.red.shade700))
                            : null,
                        trailing: const Icon(Icons.edit_calendar),
                        onTap: _pickDate,
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (_type != PuzzleType.daily && _type != PuzzleType.scramble) ...[
                      _choicesSection(),
                      const SizedBox(height: 16),
                    ],
                    _learnSection(),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                          : Text(_editing ? 'Save changes' : 'Add puzzle'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Optional multiple choice. Leave all empty to let students type the answer.
  Widget _choicesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.navySoft, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('Multiple choice · optional', color: AppColors.navy),
          const SizedBox(height: 4),
          const Text('Leave empty so students type the answer. If you add choices, one must be exactly the answer above.',
              style: TextStyle(fontSize: 12, color: Color(0xFF3A4060))),
          if (_errors['choices'] != null) ...[
            const SizedBox(height: 6),
            Text(_errors['choices']!, style: const TextStyle(color: AppColors.wrong, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
          const SizedBox(height: 10),
          for (var i = 0; i < _choices.length; i++) ...[
            TextFormField(
              controller: _choices[i],
              maxLength: 150,
              decoration: InputDecoration(labelText: 'Choice ${String.fromCharCode(65 + i)}', counterText: ''),
            ),
            const SizedBox(height: 8),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                final answer = _answer.text.trim();
                if (answer.isEmpty) return;
                final empty = _choices.indexWhere((c) => c.text.trim().isEmpty);
                if (empty >= 0 && !_choiceValues().contains(answer)) setState(() => _choices[empty].text = answer);
              },
              icon: const Icon(Icons.content_copy_rounded, size: 18),
              label: const Text('Copy the answer into an empty choice'),
            ),
          ),
        ],
      ),
    );
  }

  /// Optional teaching content shown to students AFTER they finish.
  Widget _learnSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.goldSoft, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('Learn card · shown after answering', color: Color(0xFF6B4600)),
          const SizedBox(height: 4),
          const Text('All optional. Students see this together with the answer, never before.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B5A2E))),
          const SizedBox(height: 12),
          TextFormField(
            controller: _explanation,
            maxLines: 3,
            maxLength: 1000,
            decoration: const InputDecoration(labelText: 'Why is this the answer?'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: TextFormField(controller: _trEn, maxLength: 100, decoration: const InputDecoration(labelText: 'English', counterText: ''))),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(controller: _trFil, maxLength: 100, decoration: const InputDecoration(labelText: 'Filipino', counterText: ''))),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(controller: _trPag, maxLength: 100, decoration: const InputDecoration(labelText: 'Pangasinan', counterText: ''))),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _glossary,
            maxLength: 255,
            decoration: const InputDecoration(labelText: 'Word to explain (e.g. butil = grain)'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _funFact,
            maxLines: 2,
            maxLength: 1000,
            decoration: const InputDecoration(labelText: 'Did you know? (a short fact)'),
          ),
        ],
      ),
    );
  }
}
