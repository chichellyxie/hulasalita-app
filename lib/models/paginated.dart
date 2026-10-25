import 'json.dart';

/// Laravel paginated response: { data: [...], meta: { current_page, last_page, total } }
class Paginated<T> {
  const Paginated({required this.items, required this.currentPage, required this.lastPage, required this.total});

  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory Paginated.fromJson(dynamic json, T Function(Map<String, dynamic>) parse) {
    final map = asMap(json);
    final meta = asMap(map['meta']);
    return Paginated(
      items: asList(map['data']).map((e) => parse(asMap(e))).toList(),
      currentPage: asInt(meta['current_page'], 1),
      lastPage: asInt(meta['last_page'], 1),
      total: asInt(meta['total']),
    );
  }
}
