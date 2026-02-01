import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/marketplace_listing.dart';

class MarketplaceRepository {
  MarketplaceRepository(this._client);

  final SupabaseClient _client;

  Future<List<MarketplaceListing>> fetchListings() async {
    final data = await _client
        .from('marketplace_listings')
        .select('*, profiles (username, display_name, avatar_url)')
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((item) => MarketplaceListing.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  RealtimeChannel subscribeToListings(void Function() onChange) {
    return _client
        .channel('public:marketplace_listings')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'marketplace_listings',
          callback: (_) => onChange(),
        )
        .subscribe();
  }
}
