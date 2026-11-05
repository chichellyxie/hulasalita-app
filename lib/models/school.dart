import 'json.dart';

class School {
  const School({required this.id, required this.name, this.barangay, this.type = 'secondary', this.isActive = true, this.usersCount});

  final int id;
  final String name;
  final String? barangay;
  final String type; // elementary | secondary | integrated

  /// Integrated schools have both levels, so they appear under both filters.
  bool get hasElementary => type == 'elementary' || type == 'integrated';
  bool get hasHighSchool => type == 'secondary' || type == 'integrated';

  static String typeLabel(String type) => switch (type) {
        'elementary' => 'Elementary',
        'integrated' => 'Integrated (Elementary + High school)',
        _ => 'High school',
      };
  final bool isActive;
  final int? usersCount;

  factory School.fromJson(Map<String, dynamic> json) => School(
        id: asInt(json['id']),
        name: asString(json['name']),
        barangay: asStringOrNull(json['barangay']),
        type: asString(json['type'], 'secondary'),
        isActive: asBool(json['is_active'], true),
        usersCount: json['users_count'] == null ? null : asInt(json['users_count']),
      );
}
