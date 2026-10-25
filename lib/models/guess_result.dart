import 'badge.dart';
import 'json.dart';

class LetterFeedback {
  const LetterFeedback({required this.letter, required this.state});

  final String letter;
  final String state; // correct | present | absent

  factory LetterFeedback.fromJson(Map<String, dynamic> json) => LetterFeedback(
        letter: asString(json['letter']),
        state: asString(json['state'], 'absent'),
      );
}

class GuessResult {
  const GuessResult({
    required this.puzzleId,
    required this.correct,
    required this.solved,
    required this.finished,
    required this.triesUsed,
    required this.triesLeft,
    required this.maxTries,
    required this.pointsEarned,
    required this.basePoints,
    required this.pointsToday,
    required this.dailyCap,
    required this.dailyCapReached,
    required this.currentStreak,
    required this.newBadges,
    this.letters,
    this.answer,
  });

  final int puzzleId;
  final bool correct;
  final bool solved;
  final bool finished;
  final int triesUsed;
  final int triesLeft;
  final int maxTries;
  final int pointsEarned;
  final int basePoints;
  final int pointsToday;
  final int dailyCap;
  final bool dailyCapReached;
  final int currentStreak;
  final List<LetterFeedback>? letters;
  final String? answer;
  final List<GameBadge> newBadges;

  factory GuessResult.fromJson(Map<String, dynamic> json) => GuessResult(
        puzzleId: asInt(json['puzzle_id']),
        correct: asBool(json['correct']),
        solved: asBool(json['solved']),
        finished: asBool(json['finished']),
        triesUsed: asInt(json['tries_used']),
        triesLeft: asInt(json['tries_left']),
        maxTries: asInt(json['max_tries']),
        pointsEarned: asInt(json['points_earned']),
        basePoints: asInt(json['base_points']),
        pointsToday: asInt(json['points_today']),
        dailyCap: asInt(json['daily_cap'], 150),
        dailyCapReached: asBool(json['daily_cap_reached']),
        currentStreak: asInt(json['current_streak']),
        letters: json['letters'] is List
            ? asList(json['letters']).map((e) => LetterFeedback.fromJson(asMap(e))).toList()
            : null,
        answer: asStringOrNull(json['answer']),
        newBadges: asList(json['new_badges']).map((e) => GameBadge.fromJson(asMap(e))).toList(),
      );
}
