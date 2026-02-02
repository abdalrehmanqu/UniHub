import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/community_post.dart';
import '../providers/community_providers.dart';
import '../widgets/community_post_card.dart';
import 'widgets/tag_selection_sheet.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  List<String> _getMostPopularTags(List<CommunityPost> posts, int limit) {
    final tagCounts = <String, int>{};
    for (final post in posts) {
      for (final tag in post.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedTags.take(limit).map((e) => e.key).toList();
  }

  List<String> _getAllTags(List<CommunityPost> posts) {
    final allTags = <String>{};
    for (final post in posts) {
      allTags.addAll(post.tags);
    }
    final sortedTags = allTags.toList()..sort();
    return sortedTags;
  }

  List<CommunityPost> _filterPosts(
    List<CommunityPost> posts,
    Set<String> selectedTags,
  ) {
    if (selectedTags.isEmpty) return posts;
    return posts
        .where((post) => post.tags.any((tag) => selectedTags.contains(tag)))
        .toList();
  }

  Future<void> _openTagSelectionSheet(
    BuildContext context,
    List<String> allTags,
  ) async {
    final result = await showTagSelectionSheet(
      context: context,
      allTags: allTags,
      initialSelected: ref.read(selectedTagsProvider),
      title: 'Filters',
    );
    if (result != null) {
      ref.read(selectedTagsProvider.notifier).state = result;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final communityFeed = ref.watch(communityFeedProvider);
    final selectedTags = ref.watch(selectedTagsProvider);

    return communityFeed.when(
      data: (posts) {
        if (posts.isEmpty) {
          return _EmptyState(
            title: 'Start the conversation',
            subtitle: 'Student posts and campus chatter will appear here.',
          );
        }

        final popularTags = _getMostPopularTags(posts, 5);
        final allTags = _getAllTags(posts);
        final filteredPosts = _filterPosts(posts, selectedTags);

        // Organize tags: selected first, then popular unselected, then show all
        final displayTags = <String>[];
        displayTags.addAll(selectedTags);
        for (final tag in popularTags) {
          if (!selectedTags.contains(tag)) {
            displayTags.add(tag);
          }
        }

        return Column(
          children: [
            if (allTags.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final tag in displayTags)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _TagChip(
                            tag: tag,
                            isSelected: selectedTags.contains(tag),
                            onTap: () {
                              final newTags = Set<String>.from(selectedTags);
                              if (selectedTags.contains(tag)) {
                                newTags.remove(tag);
                              } else {
                                newTags.add(tag);
                              }
                              ref.read(selectedTagsProvider.notifier).state =
                                  newTags;
                            },
                          ),
                        ),
                      ActionChip(
                        label: const Icon(Icons.add, size: 18),
                        onPressed: () {
                          _openTagSelectionSheet(context, allTags);
                        },
                        side: BorderSide(color: theme.colorScheme.outline),
                        backgroundColor: theme.colorScheme.surface,
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: filteredPosts.isEmpty
                  ? _EmptyState(
                      title: 'No posts found',
                      subtitle: 'Try selecting different tags',
                    )
                  : ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        for (final post in filteredPosts)
                          Column(
                            children: [
                              CommunityPostCard(post: post),
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: theme.colorScheme.outlineVariant
                                    .withOpacity(0.4),
                              ),
                            ],
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _EmptyState(
        title: 'Unable to load community posts',
        subtitle: error.toString(),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.tag,
    required this.isSelected,
    required this.onTap,
  });

  final String tag;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isSelected) {
      return FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tag),
            const SizedBox(width: 4),
            const Icon(Icons.close, size: 16),
          ],
        ),
        selected: true,
        onSelected: (_) => onTap(),
        backgroundColor: theme.colorScheme.primaryContainer,
        selectedColor: theme.colorScheme.primaryContainer,
        side: BorderSide(color: theme.colorScheme.primary),
        labelStyle: TextStyle(color: theme.colorScheme.onPrimaryContainer),
        checkmarkColor: theme.colorScheme.onPrimaryContainer,
        showCheckmark: false,
      );
    }

    return FilterChip(
      label: Text(tag),
      selected: false,
      onSelected: (_) => onTap(),
      side: BorderSide(color: theme.colorScheme.outline),
      backgroundColor: theme.colorScheme.surface,
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
              Icons.forum_rounded,
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
