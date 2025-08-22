class ProfileBlogModel {
  final int id;
  final String fullName;
  final String? photoPath;
  final String? description;
  final int postsCount;
  final int commentsCount;
  final int likesCount;

  ProfileBlogModel({
    required this.id,
    required this.fullName,
    required this.photoPath,
    required this.description,
    required this.postsCount,
    required this.commentsCount,
    required this.likesCount,
  });

  factory ProfileBlogModel.fromJson(Map<String, dynamic> json) {
    return ProfileBlogModel(
      id: json['id'] as int,
      fullName: json['fullName'] as String,
      photoPath: json['photoPath'] as String?,
      description: json['description'] as String?,
      postsCount: json['postsCount'] as int,
      commentsCount: json['commentsCount'] as int,
      likesCount: json['likesCount'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'photoPath': photoPath,
    'description': description,
    'postsCount': postsCount,
    'commentsCount': commentsCount,
    'likesCount': likesCount,
  };
}
