import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/marketplace_repository.dart';
import '../domain/marketplace_listing.dart';

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return MarketplaceRepository(ref.watch(supabaseClientProvider));
});

class RealtimeMarketplaceNotifier
    extends AutoDisposeAsyncNotifier<List<MarketplaceListing>> {
  RealtimeChannel? _channel;

  @override
  Future<List<MarketplaceListing>> build() async {
    final repo = ref.read(marketplaceRepositoryProvider);
    _channel?.unsubscribe();
    _channel = repo.subscribeToListings(() {
      ref.invalidateSelf();
    });
    ref.onDispose(() {
      _channel?.unsubscribe();
    });
    return repo.fetchListings();
  }
}

final marketplaceListingsProvider = AutoDisposeAsyncNotifierProvider<
    RealtimeMarketplaceNotifier,
    List<MarketplaceListing>>(
  RealtimeMarketplaceNotifier.new,
);

enum MarketplaceViewMode { grid, list }

final marketplaceViewModeProvider = StateProvider<MarketplaceViewMode>((ref) {
  return MarketplaceViewMode.grid;
});
