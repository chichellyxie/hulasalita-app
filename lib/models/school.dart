import 'json.dart';

class School {
  const School({required this.id, required this.name, this.barangay, this.isActive = true, this.usersCount});

  final int id;
  final String name;
  final String? barangay;
  final bool isActive;
  final int? usersCount;

  factory School.fromJson(Map<String, dynamic> json) => School(
        id: asInt(json['id']),
        name: asString(json['name']),
        barangay: asStringOrNull(json['barangay']),
        isActive: asBool(json['is_active'], true),
        usersCount: json['users_count'] == null ? null : asInt(json['users_count']),
      );
}
