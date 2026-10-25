import 'json.dart';

class Language {
  const Language({required this.id, required this.code, required this.name});

  final int id;
  final String code; // en | fil | pag
  final String name;

  factory Language.fromJson(Map<String, dynamic> json) => Language(
        id: asInt(json['id']),
        code: asString(json['code']),
        name: asString(json['name']),
      );
}

class PuzzleCategory {
  const PuzzleCategory({required this.id, required this.name});

  final int id;
  final String name;

  factory PuzzleCategory.fromJson(Map<String, dynamic> json) => PuzzleCategory(
        id: asInt(json['id']),
        name: asString(json['name']),
      );
}
