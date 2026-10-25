import 'json.dart';

class LeaderboardEntry {
  const LeaderboardEntry({required this.rank, required this.username, required this.points, required this.solved, required this.isMe});

  final int rank;
  final String username;
  final int points;
  final int solved;
  final bool isMe;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        rank: asInt(json['rank']),
        username: asString(json['username']),
        points: asInt(json['points']),
        solved: asInt(json['solved']),
        isMe: asBool(json['is_me']),
      );
}

class Leaderboard {
  const Leaderboard({
    required this.entries,
    required this.weekStart,
    required this.weekEnd,
    required this.totalPlayers,
    required this.myPoints,
    this.school,
    this.myRank,
  });

  final List<LeaderboardEntry> entries;
  final String? school;
  final String weekStart;
  final String weekEnd;
  final int totalPlayers;
  final int? myRank;
  final int myPoints;

  factory Leaderboard.fromJson(Map<String, dynamic> json) {
    final meta = asMap(json['meta']);
    final me = asMap(meta['me']);
    return Leaderboard(
      entries: asList(json['data']).map((e) => LeaderboardEntry.fromJson(asMap(e))).toList(),
      school: asStringOrNull(meta['school']),
      weekStart: asString(meta['week_start']),
      weekEnd: asString(meta['week_end']),
      totalPlayers: asInt(meta['total_players']),
      myRank: me['rank'] == null ? null : asInt(me['rank']),
      myPoints: asInt(me['points']),
    );
  }
}
