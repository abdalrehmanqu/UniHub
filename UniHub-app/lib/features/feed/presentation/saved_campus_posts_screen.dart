import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../community/providers/community_providers.dart';
import '../../community/widgets/community_post_card.dart';
import '../providers/feed_providers.dart';
import '../widgets/post_card.dart';

class SavedCampusPostsScreen extends ConsumerWidget {
  const SavedCampusPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Saved posts'),
          centerTitle: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Campus'),
              Tab(text: 'Community'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              const _SavedCampusTab(),
              const _SavedCommunityTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedCampusTab extends ConsumerWidget {
  const _SavedCampusTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(savedCampusFeedProvider);
    return feed.when(
      data: (posts) {
        if (posts.isEmpty) {
          return _EmptyState(
            title: 'No saved campus posts yet',
            subtitle: 'Bookmark campus posts to find them here.',
          );
        }
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [for (final post in posts) PostCard(post: post)],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _EmptyState(
        title: 'Unable to load saved posts',
        subtitle: error.toString(),
      ),
    );
  }
}

class _SavedCommunityTab extends ConsumerWidget {
  const _SavedCommunityTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(savedCommunityFeedProvider);
    return feed.when(
      data: (posts) {
        if (posts.isEmpty) {
          return _EmptyState(
            title: 'No saved community posts yet',
            subtitle: 'Bookmark community posts to find them here.',
          );
        }
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            for (final post in posts) CommunityPostCard(post: post),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _EmptyState(
        title: 'Unable to load saved posts',
        subtitle: error.toString(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
