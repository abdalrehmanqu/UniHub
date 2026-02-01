import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/community_repository.dart';
import '../domain/community_post.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(ref.watch(supabaseClientProvider));
});

final selectedTagsProvider = StateProvider<Set<String>>((ref) => {});

final communityCreateTagsProvider = StateProvider.autoDispose<Set<String>>(
  (ref) => {},
);

class RealtimeCommunityNotifier
    extends AutoDisposeAsyncNotifier<List<CommunityPost>> {
  RealtimeChannel? _channel;

  @override
  Future<List<CommunityPost>> build() async {
    final repo = ref.read(communityRepositoryProvider);
    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    _channel?.unsubscribe();
    _channel = repo.subscribeToCommunityPosts(() {
      ref.invalidateSelf();
    });
    ref.onDispose(() {
      _channel?.unsubscribe();
    });
    return repo.fetchCommunityPosts(currentUserId: userId);
  }
}

final communityFeedProvider =
    AutoDisposeAsyncNotifierProvider<
      RealtimeCommunityNotifier,
      List<CommunityPost>
    >(RealtimeCommunityNotifier.new);

class SavedCommunityFeedNotifier
    extends AutoDisposeAsyncNotifier<List<CommunityPost>> {
  @override
  Future<List<CommunityPost>> build() async {
    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (userId == null) return [];
    final repo = ref.read(communityRepositoryProvider);
    return repo.fetchSavedCommunityPosts(userId: userId);
  }
}

final savedCommunityFeedProvider =
    AutoDisposeAsyncNotifierProvider<
      SavedCommunityFeedNotifier,
      List<CommunityPost>
    >(SavedCommunityFeedNotifier.new);
