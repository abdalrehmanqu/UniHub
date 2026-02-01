import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/campus_post.dart';

class FeedRepository {
  FeedRepository(this._client);

  final SupabaseClient _client;

  Future<List<CampusPost>> fetchCampusPosts() async {
    final data = await _client
        .from('campus_posts')
        .select('*, profiles (username, display_name, avatar_url)')
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((item) => CampusPost.fromJson(item as Map<String, dynamic>))
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
