import 'json.dart';

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
        const names = {'daily': 'Daily Word', 'bugtong': 'Bugtong', 'scramble': 'Word Scramble', 'translate': 'Translate It'};
        return 'Solve $n ${names[type] ?? type} puzzles';
      case 'languages_solved':
        return 'Solve puzzles in $n languages';
      default:
        return rule;
    }
  }

  factory GameBadge.fromJson(Map<String, dynamic> json) => GameBadge(
        code: asString(json['code']),
        name: asString(json['name']),
        rule: asString(json['rule']),
        earned: asBool(json['earned']),
        earnedAt: asStringOrNull(json['earned_at']),
      );
}
