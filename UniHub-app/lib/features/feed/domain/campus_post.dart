class CampusPost {
  const CampusPost({
    required this.id,
    required this.authorName,
    required this.title,
    required this.content,
    required this.createdAt,
    this.authorAvatarUrl,
    this.mediaUrl,
    this.mediaType,
    this.likeCount = 0,
  });

  final String id;
  final String authorName;
  final String? authorAvatarUrl;
  final String title;
  final String content;
  final String? mediaUrl;
  final String? mediaType;
  final int likeCount;
  final DateTime createdAt;

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
      authorName: displayName?.isNotEmpty == true
          ? displayName!
          : (username?.isNotEmpty == true ? username! : 'Campus Desk'),
      authorAvatarUrl: profile?['avatar_url']?.toString(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      mediaUrl: json['media_url']?.toString(),
      mediaType: json['media_type']?.toString(),
      likeCount: ((json['like_count'] ?? 0) as num).toInt(),
      createdAt: createdAt,
    );
  }
}
