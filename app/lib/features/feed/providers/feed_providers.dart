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
    _channel?.unsubscribe();
    _channel = repo.subscribeToCampusPosts(() {
      ref.invalidateSelf();
    });
    ref.onDispose(() {
      _channel?.unsubscribe();
    });
    return repo.fetchCampusPosts();
  }
}

final campusFeedProvider =
    AutoDisposeAsyncNotifierProvider<RealtimeFeedNotifier, List<CampusPost>>(
  RealtimeFeedNotifier.new,
);
