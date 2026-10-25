import 'json.dart';
import 'school.dart';

class VerificationInfo {
  const VerificationInfo({required this.status, required this.hasDocument, this.submittedAt, this.reviewedAt});

  final String status;
  final bool hasDocument;
  final String? submittedAt;
  final String? reviewedAt;

  factory VerificationInfo.fromJson(Map<String, dynamic> json) => VerificationInfo(
        status: asString(json['status'], 'pending'),
        hasDocument: asBool(json['has_document']),
        submittedAt: asStringOrNull(json['submitted_at']),
        reviewedAt: asStringOrNull(json['reviewed_at']),
      );
}

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.status,
    required this.isActive,
    this.school,
    this.currentStreak = 0,
    this.lastPlayedOn,
    this.verification,
  });

  final int id;
  final String username;
  final String email;
  final String role; // student | admin
  final String status; // pending | approved | rejected
  final bool isActive;
  final School? school;
  final int currentStreak;
  final String? lastPlayedOn;
  final VerificationInfo? verification;

  bool get isAdmin => role == 'admin';
  bool get isVerifiedStudent => role == 'student' && status == 'approved' && isActive;
  bool get isRejected => status == 'rejected';
  bool get hasUploadedId => verification?.hasDocument ?? false;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: asInt(json['id']),
        username: asString(json['username']),
        email: asString(json['email']),
        role: asString(json['role'], 'student'),
        status: asString(json['status'], 'pending'),
        isActive: asBool(json['is_active'], true),
        school: json['school'] is Map ? School.fromJson(asMap(json['school'])) : null,
        currentStreak: asInt(json['current_streak']),
        lastPlayedOn: asStringOrNull(json['last_played_on']),
        verification: json['verification'] is Map ? VerificationInfo.fromJson(asMap(json['verification'])) : null,
      );

  AppUser copyWith({String? status}) => AppUser(
        id: id,
        username: username,
        email: email,
        role: role,
        status: status ?? this.status,
        isActive: isActive,
        school: school,
        currentStreak: currentStreak,
        lastPlayedOn: lastPlayedOn,
        verification: verification,
      );
}
