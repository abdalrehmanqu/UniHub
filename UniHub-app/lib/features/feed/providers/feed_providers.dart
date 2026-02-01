import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/feed_repository.dart';
import '../domain/campus_post.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(ref.watch(supabaseClientProvider));
});

class RealtimeFeedNotifier extends AutoDisposeAsyncNotifier<List<CampusPost>> {
  RealtimeChannel? _channel;

  @override
  Future<List<CampusPost>> build() async {
    final repo = ref.read(feedRepositoryProvider);
    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    _channel?.unsubscribe();
    _channel = repo.subscribeToCampusPosts(() {
      ref.invalidateSelf();
    });
    ref.onDispose(() {
      _channel?.unsubscribe();
    });
    return repo.fetchCampusPosts(currentUserId: userId);
  }
}

final campusFeedProvider =
    AutoDisposeAsyncNotifierProvider<RealtimeFeedNotifier, List<CampusPost>>(
      RealtimeFeedNotifier.new,
    );

class SavedCampusFeedNotifier
    extends AutoDisposeAsyncNotifier<List<CampusPost>> {
  @override
  Future<List<CampusPost>> build() async {
    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (userId == null) return [];
    final repo = ref.read(feedRepositoryProvider);
    return repo.fetchSavedCampusPosts(userId: userId);
  }
}

final savedCampusFeedProvider =
    AutoDisposeAsyncNotifierProvider<SavedCampusFeedNotifier, List<CampusPost>>(
      SavedCampusFeedNotifier.new,
    );
