import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/community_post.dart';
import '../providers/community_providers.dart';
import '../widgets/community_post_card.dart';

final selectedTagsProvider = StateProvider<Set<String>>((ref) => {});

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
      List<CommunityPost> posts, Set<String> selectedTags) {
    if (selectedTags.isEmpty) return posts;
    return posts
        .where((post) => post.tags.any((tag) => selectedTags.contains(tag)))
        .toList();
  }

  Future<void> _openTagSelectionSheet(
      BuildContext context, List<String> allTags) async {
    final theme = Theme.of(context);
    final searchController = TextEditingController();
    var searchQuery = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.75,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                final selectedTags = ref.watch(selectedTagsProvider);
                final filteredTags = searchQuery.isEmpty
                    ? allTags
                    : allTags
                        .where((tag) =>
                            tag.toLowerCase().contains(searchQuery.toLowerCase()))
                        .toList();

                return Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search tags...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    searchController.clear();
                                    setModalState(() => searchQuery = '');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setModalState(() => searchQuery = value);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (selectedTags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${selectedTags.length} selected',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filteredTags.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 56,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No tags found',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Try different keywords',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                              child: Consumer(
                                builder: (context, ref, _) {
                                  final currentSelected = ref.watch(selectedTagsProvider);
                                  
                                  // Sort tags: selected first, then unselected
                                  final sortedTags = <String>[];
                                  sortedTags.addAll(
                                    filteredTags.where((tag) => currentSelected.contains(tag))
                                  );
                                  sortedTags.addAll(
                                    filteredTags.where((tag) => !currentSelected.contains(tag))
                                  );
                                  
                                  return Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final tag in sortedTags)
                                        _ModalTagChip(
                                          tag: tag,
                                          isSelected: currentSelected.contains(tag),
                                          onTap: () {
                                            final newTags =
                                                Set<String>.from(currentSelected);
                                            if (currentSelected.contains(tag)) {
                                              newTags.remove(tag);
                                            } else {
                                              newTags.add(tag);
                                            }
                                            ref
                                                .read(selectedTagsProvider.notifier)
                                                .state = newTags;
                                          },
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                ref.read(selectedTagsProvider.notifier).state = {};
                              },
                              child: const Text('Clear'),
                            ),
                            const Spacer(),
                            FilledButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Apply'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      children: [
                        for (final post in filteredPosts)
                          CommunityPostCard(post: post)
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
            Icon(Icons.close, size: 16),
            const SizedBox(width: 4),
            Text(tag),
          ],
        ),
        selected: true,
        onSelected: (_) => onTap(),
        backgroundColor: theme.colorScheme.primaryContainer,
        selectedColor: theme.colorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
        ),
        checkmarkColor: theme.colorScheme.onPrimaryContainer,
        showCheckmark: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    return FilterChip(
      label: Text(tag),
      selected: false,
      onSelected: (_) => onTap(),
      side: BorderSide(color: theme.colorScheme.outline),
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _ModalTagChip extends StatelessWidget {
  const _ModalTagChip({
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
            const Icon(Icons.close, size: 16),
            const SizedBox(width: 4),
            Text(tag),
          ],
        ),
        selected: true,
        onSelected: (_) => onTap(),
        backgroundColor: theme.colorScheme.primaryContainer,
        selectedColor: theme.colorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
        ),
        checkmarkColor: theme.colorScheme.onPrimaryContainer,
        showCheckmark: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    return FilterChip(
      label: Text(tag),
      selected: false,
      onSelected: (_) => onTap(),
      side: BorderSide(color: theme.colorScheme.outline),
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
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
