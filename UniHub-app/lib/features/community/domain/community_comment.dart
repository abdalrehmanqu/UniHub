class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.score = 0,
    this.authorAvatarUrl,
    this.authorRole,
    this.parentId,
  });

  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final int score;
  final String? authorAvatarUrl;
  final String? authorRole;
  final String? parentId;

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final displayName = profile?['display_name']?.toString();
    final username = profile?['username']?.toString();

    final createdAtValue = json['created_at'];
    final createdAt = createdAtValue is String
        ? DateTime.parse(createdAtValue)
        : (createdAtValue as DateTime?) ?? DateTime.now();

    final scoreValue = json['score'] ?? json['upvotes'] ?? json['vote_count'];
    final score = scoreValue is num
        ? scoreValue.toInt()
        : int.tryParse(scoreValue?.toString() ?? '') ?? 0;

    return CommunityComment(
      id: (json['id'] ?? '').toString(),
      postId: (json['post_id'] ?? '').toString(),
      authorId: (json['author_id'] ?? '').toString(),
      parentId: json['parent_id']?.toString(),
      authorName: displayName?.isNotEmpty == true
          ? displayName!
          : (username?.isNotEmpty == true ? username! : 'Student'),
      authorAvatarUrl: profile?['avatar_url']?.toString(),
      authorRole: profile?['role']?.toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: createdAt,
      score: score,
    );
  }
}
