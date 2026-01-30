import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  const SupabaseConfig._();

  static String get url =>
      dotenv.maybeGet('SUPABASE_URL') ??
      const String.fromEnvironment('SUPABASE_URL', defaultValue: '');

  static String get anonKey =>
      dotenv.maybeGet('SUPABASE_ANON_KEY') ??
      const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static void validate() {
    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'Supabase config missing. Provide SUPABASE_URL and SUPABASE_ANON_KEY '
        'using --dart-define or a build configuration.',
      );
    }
  }
}
