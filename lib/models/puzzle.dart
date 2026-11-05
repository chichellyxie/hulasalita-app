import 'json.dart';
import 'language.dart';

class PuzzleType {
  static const String daily = 'daily';
  static const String bugtong = 'bugtong';
  static const String scramble = 'scramble';
  static const String translate = 'translate';
  static const String salawikain = 'salawikain'; // complete the proverb
  static const String sawikain = 'sawikain'; // meaning of an idiom
  static const String panitikan = 'panitikan'; // literature review
  static const String context = 'context'; // English context clues

  static const List<String> all = [daily, bugtong, scramble, translate, salawikain, sawikain, panitikan, context];

  /// Games that use one fixed language, so the language picker is hidden.
  static const List<String> singleLanguage = [salawikain, sawikain, panitikan, context];

  /// Only these games are sorted by school level (Grades 1–3 … 11–12).
  /// Bugtong, Word Scramble, Translate It and the Daily Word are for everyone.
  static const List<String> leveled = [salawikain, sawikain, panitikan, context];

  static String label(String type) => switch (type) {
        daily => 'Daily Word Guess',
        bugtong => 'Bugtong',
        scramble => 'Word Scramble',
        translate => 'Translate It',
        salawikain => 'Salawikain',
        sawikain => 'Sawikain',
        panitikan => 'Panitikan',
        context => 'Context Clues',
        _ => type,
      };
}

/// School levels. Puzzles with no level are shown to everyone.
class SchoolLevel {
  static const String elemLower = 'elem_lower';
  static const String elemUpper = 'elem_upper';
  static const String jhs = 'jhs';
  static const String shs = 'shs';

  static const List<String> all = [elemLower, elemUpper, jhs, shs];

  static String label(String level) => switch (level) {
        elemLower => 'Grades 1–3',
        elemUpper => 'Grades 4–6',
        jhs => 'Grades 7–10',
        shs => 'Grades 11–12',
        _ => 'All levels',
      };

  static String shortLabel(String level) => switch (level) {
        elemLower => 'Gr 1–3',
        elemUpper => 'Gr 4–6',
        jhs => 'Gr 7–10',
        shs => 'Gr 11–12',
        _ => 'All',
      };

  static String group(String level) => switch (level) {
        elemLower || elemUpper => 'Elementary',
        jhs => 'Junior High',
        shs => 'Senior High',
        _ => '',
      };

  static String? forGrade(int? grade) {
    if (grade == null) return null;
    if (grade <= 3) return elemLower;
    if (grade <= 6) return elemUpper;
    if (grade <= 10) return jhs;
    return shs;
  }
}

class MyAttempt {
  const MyAttempt({this.triesUsed = 0, this.triesLeft = 0, this.solved = false, this.finished = false, this.points = 0});

  final int triesUsed;
  final int triesLeft;
  final bool solved;
  final bool finished;
  final int points;

  factory MyAttempt.fromJson(Map<String, dynamic> json) => MyAttempt(
        triesUsed: asInt(json['tries_used']),
        triesLeft: asInt(json['tries_left']),
        solved: asBool(json['solved']),
        finished: asBool(json['finished']),
        points: asInt(json['points']),
      );
}

/// Teaching content shown after a puzzle is finished (with the answer).
/// Every field is optional — the admin may fill in only some of them.
class LearnCard {
  const LearnCard({this.explanation, this.translations = const {}, this.glossary, this.funFact});

  final String? explanation;
  final Map<String, String> translations; // en | fil | pag -> word
  final String? glossary;
  final String? funFact;

  static String? _clean(dynamic v) {
    final s = asStringOrNull(v)?.trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  static LearnCard? fromJsonOrNull(dynamic value) {
    if (value is! Map) return null;
    final json = asMap(value);
    final words = <String, String>{};
    asMap(json['translations']).forEach((code, word) {
      final w = _clean(word);
      if (w != null) words[code] = w;
    });
    final card = LearnCard(
      explanation: _clean(json['explanation']),
      translations: words,
      glossary: _clean(json['glossary']),
      funFact: _clean(json['fun_fact']),
    );
    return card.isEmpty ? null : card;
  }

  bool get isEmpty => explanation == null && translations.isEmpty && glossary == null && funFact == null;
}

/// A puzzle as a student sees it. [answer] is null until the puzzle is finished.
class Puzzle {
  const Puzzle({
    required this.id,
    required this.type,
    required this.difficulty,
    required this.basePoints,
    required this.prompt,
    required this.maxTries,
    required this.myAttempt,
    this.hint,
    this.answerLength,
    this.scheduledFor,
    this.language,
    this.category,
    this.answer,
    this.learn,
    this.choices = const [],
    this.level,
  });

  final int id;
  final String type;
  final String difficulty;
  final int basePoints;
  final String prompt;
  final String? hint;
  final int maxTries;
  final int? answerLength;
  final String? scheduledFor;
  final Language? language;
  final PuzzleCategory? category;
  final MyAttempt myAttempt;
  final String? answer;
  final LearnCard? learn; // null until finished, or when no learn content exists
  final List<String> choices; // empty = type the answer
  final String? level; // elem_lower | elem_upper | jhs | shs | null (everyone)

  bool get isMultipleChoice => choices.isNotEmpty;

  factory Puzzle.fromJson(Map<String, dynamic> json) => Puzzle(
        id: asInt(json['id']),
        type: asString(json['type']),
        difficulty: asString(json['difficulty'], 'easy'),
        basePoints: asInt(json['base_points']),
        prompt: asString(json['prompt']),
        hint: asStringOrNull(json['hint']),
        maxTries: asInt(json['max_tries'], 1),
        answerLength: json['answer_length'] == null ? null : asInt(json['answer_length']),
        scheduledFor: asStringOrNull(json['scheduled_for']),
        language: json['language'] is Map ? Language.fromJson(asMap(json['language'])) : null,
        category: json['category'] is Map ? PuzzleCategory.fromJson(asMap(json['category'])) : null,
        myAttempt: MyAttempt.fromJson(asMap(json['my_attempt'])),
        answer: asStringOrNull(json['answer']),
        learn: LearnCard.fromJsonOrNull(json['learn']),
        choices: asList(json['choices']).map((e) => asString(e)).where((e) => e.isNotEmpty).toList(),
        level: asStringOrNull(json['level']),
      );
}
