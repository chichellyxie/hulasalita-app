import 'json.dart';
import 'language.dart';

class AdminVerification {
  const AdminVerification({
    required this.id,
    required this.status,
    required this.hasDocument,
    required this.username,
    required this.email,
    this.school,
    this.submittedAt,
  });

  final int id;
  final String status;
  final bool hasDocument;
  final String username;
  final String email;
  final String? school;
  final String? submittedAt;

  factory AdminVerification.fromJson(Map<String, dynamic> json) {
    final user = asMap(json['user']);
    return AdminVerification(
      id: asInt(json['id']),
      status: asString(json['status']),
      hasDocument: asBool(json['has_document']),
      username: asString(user['username']),
      email: asString(user['email']),
      school: asStringOrNull(user['school']),
      submittedAt: asStringOrNull(json['submitted_at']),
    );
  }
}

/// Puzzle as the admin sees it (includes the answer).
class AdminPuzzle {
  const AdminPuzzle({
    required this.id,
    required this.type,
    required this.difficulty,
    required this.prompt,
    required this.answer,
    required this.maxTries,
    required this.languageId,
    required this.categoryId,
    this.hint,
    this.scheduledFor,
    this.language,
    this.category,
    this.attemptsCount = 0,
  });

  final int id;
  final String type;
  final String difficulty;
  final String prompt;
  final String? hint;
  final String answer;
  final int maxTries;
  final String? scheduledFor;
  final int languageId;
  final int categoryId;
  final Language? language;
  final PuzzleCategory? category;
  final int attemptsCount;

  factory AdminPuzzle.fromJson(Map<String, dynamic> json) => AdminPuzzle(
        id: asInt(json['id']),
        type: asString(json['type']),
        difficulty: asString(json['difficulty']),
        prompt: asString(json['prompt']),
        hint: asStringOrNull(json['hint']),
        answer: asString(json['answer']),
        maxTries: asInt(json['max_tries'], 4),
        scheduledFor: asStringOrNull(json['scheduled_for']),
        languageId: asInt(json['language_id']),
        categoryId: asInt(json['category_id']),
        language: json['language'] is Map ? Language.fromJson(asMap(json['language'])) : null,
        category: json['category'] is Map ? PuzzleCategory.fromJson(asMap(json['category'])) : null,
        attemptsCount: asInt(json['attempts_count']),
      );
}

class AdminUser {
  const AdminUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.status,
    required this.isActive,
    this.schoolName,
  });

  final int id;
  final String username;
  final String email;
  final String role;
  final String status;
  final bool isActive;
  final String? schoolName;

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: asInt(json['id']),
        username: asString(json['username']),
        email: asString(json['email']),
        role: asString(json['role']),
        status: asString(json['status']),
        isActive: asBool(json['is_active'], true),
        schoolName: json['school'] is Map ? asString(asMap(json['school'])['name']) : null,
      );
}

class SchoolReport {
  const SchoolReport({
    required this.school,
    required this.verifiedStudents,
    required this.players,
    required this.attempts,
    required this.solved,
    required this.points,
  });

  final String school;
  final int verifiedStudents;
  final int players;
  final int attempts;
  final int solved;
  final int points;

  factory SchoolReport.fromJson(Map<String, dynamic> json) => SchoolReport(
        school: asString(json['school']),
        verifiedStudents: asInt(json['verified_students']),
        players: asInt(json['players']),
        attempts: asInt(json['attempts']),
        solved: asInt(json['solved']),
        points: asInt(json['points']),
      );
}

class TypeReport {
  const TypeReport({required this.type, required this.language, required this.attempts, required this.solved, required this.solveRate});

  final String type;
  final String language;
  final int attempts;
  final int solved;
  final double solveRate;

  factory TypeReport.fromJson(Map<String, dynamic> json) => TypeReport(
        type: asString(json['type']),
        language: asString(json['language']),
        attempts: asInt(json['attempts']),
        solved: asInt(json['solved']),
        solveRate: asDouble(json['solve_rate']),
      );
}

class AdminReport {
  const AdminReport({
    required this.verifiedStudents,
    required this.pendingVerifications,
    required this.players,
    required this.attempts,
    required this.solved,
    required this.solveRate,
    required this.points,
    required this.bySchool,
    required this.byType,
  });

  final int verifiedStudents;
  final int pendingVerifications;
  final int players;
  final int attempts;
  final int solved;
  final double solveRate;
  final int points;
  final List<SchoolReport> bySchool;
  final List<TypeReport> byType;

  factory AdminReport.fromJson(Map<String, dynamic> json) {
    final totals = asMap(json['totals']);
    return AdminReport(
      verifiedStudents: asInt(totals['verified_students']),
      pendingVerifications: asInt(totals['pending_verifications']),
      players: asInt(totals['players']),
      attempts: asInt(totals['attempts']),
      solved: asInt(totals['solved']),
      solveRate: asDouble(totals['solve_rate']),
      points: asInt(totals['points']),
      bySchool: asList(json['by_school']).map((e) => SchoolReport.fromJson(asMap(e))).toList(),
      byType: asList(json['by_type']).map((e) => TypeReport.fromJson(asMap(e))).toList(),
    );
  }
}
