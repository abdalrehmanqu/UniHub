import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/campus_post.dart';

class FeedRepository {
  FeedRepository(this._client);

  final SupabaseClient _client;

  Future<List<CampusPost>> fetchCampusPosts({String? currentUserId}) async {
    final data = await _client
        .from('campus_posts')
        .select('*, profiles (username, display_name, avatar_url)')
        .order('created_at', ascending: false);

    final posts = (data as List<dynamic>)
        .map((item) => CampusPost.fromJson(item as Map<String, dynamic>))
        .toList();
    if (currentUserId == null) return posts;

    final savedData = await _client
        .from('campus_post_saves')
        .select('post_id')
        .eq('user_id', currentUserId);
    final savedIds = <String>{
      for (final row in (savedData as List<dynamic>))
        (row['post_id'] ?? '').toString(),
    };

    return [
      for (final post in posts)
        post.copyWith(isSaved: savedIds.contains(post.id)),
    ];
  }

  Future<void> createCampusPost({
    required String authorId,
    required String title,
    required String content,
    String? mediaUrl,
    String? mediaType,
  }) async {
    await _client.from('campus_posts').insert({
      'author_id': authorId,
      'title': title,
      'content': content,
      if (mediaUrl != null) 'media_url': mediaUrl,
      if (mediaType != null) 'media_type': mediaType,
    });
  }

  Future<void> deleteCampusPost({required String postId}) async {
    final result = await _client
        .from('campus_posts')
        .delete()
        .eq('id', postId)
        .select();
    if (result is List && result.isEmpty) {
      throw StateError('Delete failed. Check row policies for campus_posts.');
    }
  }

  Future<void> saveCampusPost({
    required String userId,
    required String postId,
  }) async {
    await _client.from('campus_post_saves').upsert({
      'user_id': userId,
      'post_id': postId,
    }, onConflict: 'user_id,post_id');
  }

  Future<void> unsaveCampusPost({
    required String userId,
    required String postId,
  }) async {
    await _client
        .from('campus_post_saves')
        .delete()
        .eq('user_id', userId)
        .eq('post_id', postId);
  }

  Future<List<CampusPost>> fetchSavedCampusPosts({
    required String userId,
  }) async {
    final data = await _client
        .from('campus_post_saves')
        .select(
          'campus_posts(*, profiles (username, display_name, avatar_url))',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((row) => row['campus_posts'] as Map<String, dynamic>?)
        .whereType<Map<String, dynamic>>()
        .map((item) => CampusPost.fromJson(item).copyWith(isSaved: true))
        .toList();
  }

  RealtimeChannel subscribeToCampusPosts(void Function() onChange) {
    return _client
        .channel('public:campus_posts')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'campus_posts',
          callback: (_) => onChange(),
        )
        .subscribe();
  }
}
