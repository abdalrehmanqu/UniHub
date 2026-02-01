class CampusPost {
  const CampusPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.content,
    required this.createdAt,
    this.authorAvatarUrl,
    this.mediaUrl,
    this.mediaType,
    this.likeCount = 0,
    this.isSaved = false,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String title;
  final String content;
  final String? mediaUrl;
  final String? mediaType;
  final int likeCount;
  final bool isSaved;
  final DateTime createdAt;

  CampusPost copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatarUrl,
    String? title,
    String? content,
    String? mediaUrl,
    String? mediaType,
    int? likeCount,
    bool? isSaved,
    DateTime? createdAt,
  }) {
    return CampusPost(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      title: title ?? this.title,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      likeCount: likeCount ?? this.likeCount,
      isSaved: isSaved ?? this.isSaved,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory CampusPost.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final displayName = profile?['display_name']?.toString();
    final username = profile?['username']?.toString();

    final createdAtValue = json['created_at'];
    final createdAt = createdAtValue is String
        ? DateTime.parse(createdAtValue)
        : (createdAtValue as DateTime?) ?? DateTime.now();

    return CampusPost(
      id: (json['id'] ?? '').toString(),
      authorId: (json['author_id'] ?? '').toString(),
      authorName: displayName?.isNotEmpty == true
          ? displayName!
          : (username?.isNotEmpty == true ? username! : 'Campus Desk'),
      authorAvatarUrl: profile?['avatar_url']?.toString(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      mediaUrl: json['media_url']?.toString(),
      mediaType: json['media_type']?.toString(),
      likeCount: ((json['like_count'] ?? 0) as num).toInt(),
      isSaved: false,
      createdAt: createdAt,
    );
  }
}
