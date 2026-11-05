import 'json.dart';
import 'language.dart';
import 'puzzle.dart';

/// A finished puzzle the student saved to their Word Bank.
class SavedWord {
  const SavedWord({
    required this.puzzleId,
    required this.type,
    required this.difficulty,
    required this.prompt,
    required this.answer,
    this.language,
    this.learn,
    this.savedAt,
  });

  final int puzzleId;
  final String type;
  final String difficulty;
  final String prompt;
  final String answer;
  final Language? language;
  final LearnCard? learn;
  final String? savedAt;

  factory SavedWord.fromJson(Map<String, dynamic> json) => SavedWord(
        puzzleId: asInt(json['puzzle_id']),
        type: asString(json['type']),
        difficulty: asString(json['difficulty'], 'easy'),
        prompt: asString(json['prompt']),
        answer: asString(json['answer']),
        language: json['language'] is Map ? Language.fromJson(asMap(json['language'])) : null,
        learn: LearnCard.fromJsonOrNull(json['learn']),
        savedAt: asStringOrNull(json['saved_at']),
      );
}
