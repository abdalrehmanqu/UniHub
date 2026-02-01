import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/community_post.dart';

class CommunityRepository {
  CommunityRepository(this._client);

  final SupabaseClient _client;

  Future<List<CommunityPost>> fetchCommunityPosts({
    String? currentUserId,
  }) async {
    final data = await _client
        .from('community_posts')
        .select('*, profiles (username, display_name, avatar_url)')
        .order('created_at', ascending: false);

    final posts =
        (data as List<dynamic>)
        .map((item) => CommunityPost.fromJson(item as Map<String, dynamic>))
        .toList();

    if (currentUserId == null) {
      return posts;
    }

    final savedData = await _client
        .from('community_post_saves')
        .select('post_id')
        .eq('user_id', currentUserId);
    final savedIds = <String>{
      for (final row in (savedData as List<dynamic>))
        (row as Map<String, dynamic>)['post_id'].toString(),
    };

    return [
      for (final post in posts)
        post.copyWith(isSaved: savedIds.contains(post.id)),
    ];
  }

  Future<void> createCommunityPost({
    required String authorId,
    required String title,
    required String content,
    List<String> tags = const [],
    String? mediaUrl,
  }) async {
    await _client.from('community_posts').insert({
      'author_id': authorId,
      'title': title,
      'content': content,
      'tags': tags,
      if (mediaUrl != null) 'media_url': mediaUrl,
    });
  }

  Future<List<CommunityPost>> fetchSavedCommunityPosts({
    required String userId,
  }) async {
    final data = await _client
        .from('community_post_saves')
        .select(
          'community_posts ( *, profiles (username, display_name, avatar_url) )',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((row) => (row as Map<String, dynamic>)['community_posts'])
        .where((post) => post != null)
        .map(
          (post) => CommunityPost.fromJson(post as Map<String, dynamic>)
              .copyWith(isSaved: true),
        )
        .toList();
  }

  Future<void> saveCommunityPost({
    required String userId,
    required String postId,
  }) async {
    await _client.from('community_post_saves').upsert({
      'user_id': userId,
      'post_id': postId,
    });
  }

  Future<void> unsaveCommunityPost({
    required String userId,
    required String postId,
  }) async {
    await _client
        .from('community_post_saves')
        .delete()
        .eq('user_id', userId)
        .eq('post_id', postId);
  }

  Future<void> deleteCommunityPost({required String postId}) async {
    final data = await _client
        .from('community_posts')
        .delete()
        .eq('id', postId)
        .select('id');
    if (data is List && data.isEmpty) {
      throw StateError('Delete failed. Check row policies for community_posts.');
    }
  }

  RealtimeChannel subscribeToCommunityPosts(void Function() onChange) {
    return _client
        .channel('public:community_posts')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'community_posts',
          callback: (_) => onChange(),
        )
        .subscribe();
  }
}
