import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/community_repository.dart';
import '../domain/community_post.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(ref.watch(supabaseClientProvider));
});

class RealtimeCommunityNotifier
    extends AutoDisposeAsyncNotifier<List<CommunityPost>> {
  RealtimeChannel? _channel;

  @override
  Future<List<CommunityPost>> build() async {
    final repo = ref.read(communityRepositoryProvider);
    _channel?.unsubscribe();
    _channel = repo.subscribeToCommunityPosts(() {
      ref.invalidateSelf();
    });
    ref.onDispose(() {
      _channel?.unsubscribe();
    });
    return repo.fetchCommunityPosts();
  }
}

final communityFeedProvider = AutoDisposeAsyncNotifierProvider<
    RealtimeCommunityNotifier,
    List<CommunityPost>>(
  RealtimeCommunityNotifier.new,
);
