import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/database/entites/user.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

final authUserProvider = StreamProvider<User?>((ref) async* {
  final client = ref.watch(supabaseClientProvider);
  yield client.auth.currentUser;
  await for (final event in client.auth.onAuthStateChange) {
    yield event.session?.user;
  }
});

final profileProvider = FutureProvider<UserEntity?>((ref) async {
  final user = await ref.watch(authUserProvider.future);
  if (user == null) return null;
  final repo = ref.watch(profileRepositoryProvider);
  return repo.fetchProfile(user.id);
});
