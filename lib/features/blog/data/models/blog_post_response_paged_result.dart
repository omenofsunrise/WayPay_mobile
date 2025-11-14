import 'package:waypay_mobile/features/blog/data/models/blog_post_response.dart';

class BlogPostResponsePagedResult {
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final List<BlogPostResponse>? items;

  BlogPostResponsePagedResult({
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    this.items,
  });

  factory BlogPostResponsePagedResult.fromJson(Map<String, dynamic> json) {
    return BlogPostResponsePagedResult(
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      totalCount: json['totalCount'] as int,
      totalPages: json['totalPages'] as int,
      items: json['items'] != null
          ? (json['items'] as List)
                .map((e) => BlogPostResponse.fromJson(e))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'pageSize': pageSize,
      'totalCount': totalCount,
      'totalPages': totalPages,
      'items': items?.map((e) => e.toJson()).toList(),
    };
  }

  BlogPostResponsePagedResult copyWith({
    int? page,
    int? pageSize,
    int? totalCount,
    int? totalPages,
    List<BlogPostResponse>? items,
  }) {
    return BlogPostResponsePagedResult(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      totalPages: totalPages ?? this.totalPages,
      items: items ?? this.items,
    );
  }
}
