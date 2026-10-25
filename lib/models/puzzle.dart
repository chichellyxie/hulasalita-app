import 'json.dart';
import 'language.dart';

class PuzzleType {
  static const String daily = 'daily';
  static const String bugtong = 'bugtong';
  static const String scramble = 'scramble';
  static const String translate = 'translate';

  static const List<String> all = [daily, bugtong, scramble, translate];

  static String label(String type) => switch (type) {
        daily => 'Daily Word Guess',
        bugtong => 'Bugtong',
        scramble => 'Word Scramble',
        translate => 'Translate It',
        _ => type,
      };
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
      );
}
