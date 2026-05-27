import 'resource_item.dart';

class PagedResourceResult {
  const PagedResourceResult({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
  });

  final List<ResourceItem> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;

  factory PagedResourceResult.fromJson(Map<String, dynamic> json) {
    return PagedResourceResult(
      items: (json['items'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic item) => ResourceItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int? ?? 0,
      size: json['size'] as int? ?? 0,
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      first: json['first'] as bool? ?? true,
      last: json['last'] as bool? ?? true,
    );
  }
}
