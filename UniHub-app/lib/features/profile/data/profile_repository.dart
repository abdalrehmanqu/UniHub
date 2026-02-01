import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/database/entites/user.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<UserEntity?> fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return UserEntity.fromJson(data);
  }

  Future<UserEntity> upsertProfile(UserEntity profile) async {
    final data = await _client
        .from('profiles')
        .upsert(profile.toJson())
        .select()
        .single();

    return UserEntity.fromJson(data);
  }
}
