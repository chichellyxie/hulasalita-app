import 'badge.dart';
import 'json.dart';

class PlayerStats {
  const PlayerStats({
    required this.username,
    required this.totalPoints,
    required this.pointsToday,
    required this.pointsLeftToday,
    required this.dailyCap,
    required this.pointsThisWeek,
    required this.currentStreak,
    required this.puzzlesSolved,
    required this.solvedByType,
    required this.languagesPlayed,
    required this.badges,
    this.school,
    this.lastPlayedOn,
  });

  final String username;
  final String? school;
  final int totalPoints;
  final int pointsToday;
  final int pointsLeftToday;
  final int dailyCap;
  final int pointsThisWeek;
  final int currentStreak;
  final String? lastPlayedOn;
  final int puzzlesSolved;
  final Map<String, int> solvedByType;
  final int languagesPlayed;
  final List<GameBadge> badges;

  int get badgesEarned => badges.where((b) => b.earned).length;

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    final byType = <String, int>{};
    asMap(json['solved_by_type']).forEach((key, value) => byType[key] = asInt(value));

    return PlayerStats(
      username: asString(json['username']),
      school: asStringOrNull(json['school']),
      totalPoints: asInt(json['total_points']),
      pointsToday: asInt(json['points_today']),
      pointsLeftToday: asInt(json['points_left_today']),
      dailyCap: asInt(json['daily_cap'], 150),
      pointsThisWeek: asInt(json['points_this_week']),
      currentStreak: asInt(json['current_streak']),
      lastPlayedOn: asStringOrNull(json['last_played_on']),
      puzzlesSolved: asInt(json['puzzles_solved']),
      solvedByType: byType,
      languagesPlayed: asInt(json['languages_played']),
      badges: asList(json['badges']).map((e) => GameBadge.fromJson(asMap(e))).toList(),
    );
  }
}
