import 'json.dart';
import 'puzzle.dart';
import 'stats.dart';

class GameBadge {
  const GameBadge({required this.code, required this.name, required this.rule, required this.earned, this.earnedAt});

  final String code;
  final String name;
  final String rule;
  final bool earned;
  final String? earnedAt;

  /// Turns "type_solved:bugtong:10" into "Solve 10 Bugtong puzzles".
  String get description {
    final parts = rule.split(':');
    final n = parts.isNotEmpty ? parts.last : '';
    switch (parts.first) {
      case 'puzzles_solved':
        return n == '1' ? 'Solve your first puzzle' : 'Solve $n puzzles';
      case 'streak':
        return 'Play $n days in a row';
      case 'points_total':
        return 'Earn $n points in total';
      case 'type_solved':
        final type = parts.length == 3 ? parts[1] : '';
        final name = type == PuzzleType.daily ? 'Daily Word' : PuzzleType.label(type);
        return 'Solve $n $name puzzles';
      case 'languages_solved':
        return 'Solve puzzles in $n languages';
      default:
        return rule;
    }
  }

  /// Goal from the rule, e.g. 10 for "type_solved:bugtong:10".
  int get goal => int.tryParse(rule.split(':').last) ?? 1;

  /// How far the player is toward this badge, worked out from their stats.
  /// (Streak badges use the CURRENT streak.)
  int progress(PlayerStats stats) {
    final parts = rule.split(':');
    final value = switch (parts.first) {
      'puzzles_solved' => stats.puzzlesSolved,
      'streak' => stats.currentStreak,
      'points_total' => stats.totalPoints,
      'type_solved' => parts.length == 3 ? (stats.solvedByType[parts[1]] ?? 0) : 0,
      'languages_solved' => stats.languagesPlayed,
      _ => 0,
    };
    return earned ? goal : value.clamp(0, goal).toInt();
  }

  factory GameBadge.fromJson(Map<String, dynamic> json) => GameBadge(
        code: asString(json['code']),
        name: asString(json['name']),
        rule: asString(json['rule']),
        earned: asBool(json['earned']),
        earnedAt: asStringOrNull(json['earned_at']),
      );
}
