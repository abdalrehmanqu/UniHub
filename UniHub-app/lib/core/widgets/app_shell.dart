import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/marketplace/providers/marketplace_providers.dart';
import '../../features/profile/providers/profile_providers.dart';
import '../providers/ui_providers.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child, required this.location});

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
    final isMarketplace = location.startsWith('/marketplace');
    final showAdd = (isAdmin && isCampus) || (isStudent && isCommunity);
    final showCommunityActions = isCommunity && !location.contains('/search');
    final showFeedActions = isCampus && !location.contains('/search');
    final viewMode = isMarketplace
        ? ref.watch(marketplaceViewModeProvider)
        : MarketplaceViewMode.grid;
    final bottomNavVisible = ref.watch(bottomNavVisibleProvider);
    final commentsScrimOpacity = ref.watch(commentsScrimOpacityProvider);
    final isGrid = viewMode == MarketplaceViewMode.grid;
    final toggleActiveColor = theme.colorScheme.primary;
    final toggleInactiveColor = theme.colorScheme.surfaceVariant;
    final toggleActiveIconColor = theme.colorScheme.onPrimary;
    final toggleInactiveIconColor = theme.colorScheme.onSurfaceVariant;
    const toggleWidth = 78.0;
    const toggleHeight = 34.0;
    const togglePadding = 3.0;
    const toggleIconSize = 18.0;
    final toggleSegmentWidth = (toggleWidth - (togglePadding * 2)) / 2;
    const toggleAnimation = Duration(milliseconds: 180);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: SizedBox(
                    height: 44,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 24,
                          child: Image.network(
                            'https://omrwuqfyiyixnpvvrywi.supabase.co/storage/v1/object/public/branding/unihub_icon_black_transparent.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 21,
                              color: theme.colorScheme.onBackground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isMarketplace ||
                            showAdd ||
                            showCommunityActions ||
                            showFeedActions)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showFeedActions)
                                Row(
                                  children: [
                                    IconButton(
                                      icon:
                                          const Icon(Icons.search_rounded),
                                      onPressed: () {
                                        context.push('/campus/search');
                                      },
                                      tooltip: 'Search',
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                ),
                              if (showCommunityActions)
                                Row(
                                  children: [
                                    IconButton(
                                      icon:
                                          const Icon(Icons.search_rounded),
                                      onPressed: () {
                                        context.push('/community/search');
                                      },
                                      tooltip: 'Search',
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                ),
                              if (isMarketplace)
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: GestureDetector(
                                    onTap: () {
                                      ref
                                          .read(
                                            marketplaceViewModeProvider.notifier,
                                          )
                                          .state = isGrid
                                          ? MarketplaceViewMode.list
                                          : MarketplaceViewMode.grid;
                                    },
                                    child: AnimatedContainer(
                                      duration: toggleAnimation,
                                      width: toggleWidth,
                                      height: toggleHeight,
                                      padding: const EdgeInsets.all(
                                        togglePadding,
                                      ),
                                      decoration: BoxDecoration(
                                        color: toggleInactiveColor,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Stack(
                                        children: [
                                          AnimatedAlign(
                                            duration: toggleAnimation,
                                            curve: Curves.easeInOut,
                                            alignment: isGrid
                                                ? Alignment.centerLeft
                                                : Alignment.centerRight,
                                            child: Container(
                                              width: toggleSegmentWidth,
                                              decoration: BoxDecoration(
                                                color: toggleActiveColor,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              SizedBox(
                                                width: toggleSegmentWidth,
                                                child: Center(
                                                  child: Icon(
                                                    Icons.grid_view_rounded,
                                                    size: toggleIconSize,
                                                    color: isGrid
                                                        ? toggleActiveIconColor
                                                        : toggleInactiveIconColor,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: toggleSegmentWidth,
                                                child: Center(
                                                  child: Icon(
                                                    Icons.view_list_rounded,
                                                    size: toggleIconSize,
                                                    color: isGrid
                                                        ? toggleInactiveIconColor
                                                        : toggleActiveIconColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              if (showAdd)
                                IconButton(
                                  icon:
                                      const Icon(Icons.add_rounded, size: 28),
                                  onPressed: () {
                                    if (isCampus) {
                                      context.push('/campus/create');
                                    } else if (isCommunity) {
                                      context.push('/community/create');
                                    }
                                  },
                                  tooltip: 'Create',
                                  color: theme.colorScheme.primary,
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
          if (commentsScrimOpacity > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Colors.black.withOpacity(commentsScrimOpacity),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: bottomNavVisible
          ? ColoredBox(
              color: theme.colorScheme.background,
              child: SafeArea(
                top: false,
                bottom: true,
                child: SizedBox(
                  height: 56,
                  child: NavigationBar(
                    height: 56,
                    selectedIndex: currentIndex,
                    onDestinationSelected: (index) =>
                        _onDestinationSelected(context, index),
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.home_filled),
                        label: 'Campus',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.forum_rounded),
                        label: 'Community',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.storefront_rounded),
                        label: 'Market',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person),
                        label: 'Profile',
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
