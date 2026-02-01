import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/supabase/supabase_client.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    HttpOverrides.global = _PreviewHttpOverrides();
  }
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  try {
    await SupabaseClientProvider.initialize();
  } catch (error) {
    runApp(ErrorApp(message: error.toString()));
    return;
  }

  runApp(const ProviderScope(child: UniHubApp()));
}

class _PreviewHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (cert, host, port) {
      return host == 'qu.edu.qa' || host.endsWith('.qu.edu.qa');
    };
    return client;
  }
}

class UniHubApp extends ConsumerWidget {
  const UniHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'UniHub',
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.light();
    return MaterialApp(
      title: 'UniHub',
      theme: theme,
      home: Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_rounded,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Startup error',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Check your .env values for SUPABASE_URL and SUPABASE_ANON_KEY.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
