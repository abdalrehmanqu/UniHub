class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorName,
    required this.title,
    required this.content,
    required this.createdAt,
    this.authorAvatarUrl,
    this.mediaUrl,
    this.tags = const [],
    this.upvotes = 0,
    this.commentCount = 0,
  });

  final String id;
  final String authorName;
  final String? authorAvatarUrl;
  final String title;
  final String content;
  final String? mediaUrl;
  final List<String> tags;
  final int upvotes;
  final int commentCount;
  final DateTime createdAt;

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final displayName = profile?['display_name']?.toString();
    final username = profile?['username']?.toString();

    final createdAtValue = json['created_at'];
    final createdAt = createdAtValue is String
        ? DateTime.parse(createdAtValue)
        : (createdAtValue as DateTime?) ?? DateTime.now();

    return CommunityPost(
      id: (json['id'] ?? '').toString(),
      authorName: displayName?.isNotEmpty == true
          ? displayName!
          : (username?.isNotEmpty == true ? username! : 'Student'),
      authorAvatarUrl: profile?['avatar_url']?.toString(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      mediaUrl: json['media_url']?.toString(),
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((tag) => tag.toString())
          .toList(),
      upvotes: ((json['upvotes'] ?? 0) as num).toInt(),
      commentCount: ((json['comment_count'] ?? 0) as num).toInt(),
      createdAt: createdAt,
    );
  }
}
