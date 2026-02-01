import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

class SupabaseClientProvider {
  SupabaseClientProvider._();

  static Future<void> initialize() async {
    SupabaseConfig.validate();
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      debug: true,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
