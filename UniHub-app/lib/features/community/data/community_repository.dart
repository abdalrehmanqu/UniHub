import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/community_post.dart';

class CommunityRepository {
  CommunityRepository(this._client);

  final SupabaseClient _client;

  Future<List<CommunityPost>> fetchCommunityPosts() async {
    final data = await _client
        .from('community_posts')
        .select('*, profiles (username, display_name, avatar_url)')
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((item) => CommunityPost.fromJson(item as Map<String, dynamic>))
        .toList();
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
