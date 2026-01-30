import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/profile/providers/profile_providers.dart';
import 'unihub_logo.dart';

class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.location,
  });

  final Widget child;
  final String location;

  int _indexFromLocation() {
    if (location.startsWith('/campus')) return 0;
    if (location.startsWith('/community')) return 1;
    if (location.startsWith('/marketplace')) return 2;
    return 3;
  }

  String _titleFromLocation() {
    if (location.startsWith('/campus')) return 'Campus Feed';
    if (location.startsWith('/community')) return 'Community';
    if (location.startsWith('/marketplace')) return 'Marketplace';
    return 'Profile';
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/campus');
        return;
      case 1:
        context.go('/community');
        return;
      case 2:
        context.go('/marketplace');
        return;
      case 3:
        context.go('/profile');
        return;
      default:
        context.go('/campus');
        return;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentIndex = _indexFromLocation();
    final title = _titleFromLocation();
    final profileAsync = ref.watch(profileProvider);
    final role = profileAsync.maybeWhen(
      data: (user) => user?.role,
      orElse: () => null,
    );
    final roleValue = role?.toLowerCase();
    final isAdmin = roleValue == 'admin';
    final isStudent = roleValue == 'student';
    final isCampus = location.startsWith('/campus');
    final isCommunity = location.startsWith('/community');
    final showAdd = (isAdmin && isCampus) || (isStudent && isCommunity);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OverflowBox(
                        alignment: Alignment.centerLeft,
                        maxHeight: 120,
                        child: const UniHubLogo(
                          variant: UniHubLogoVariant.horizontal,
                          height: 82,
                        ),
                      ),
                    ),
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                    if (showAdd)
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.add_rounded, size: 28),
                          onPressed: () {},
                          tooltip: 'Create',
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        bottom: false,
        child: SizedBox(
          height: 80,
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) => _onDestinationSelected(context, index),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_filled), label: 'Campus'),
              NavigationDestination(icon: Icon(Icons.forum_rounded), label: 'Community'),
              NavigationDestination(
                icon: Icon(Icons.storefront_rounded),
                label: 'Market',
              ),
              NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}
