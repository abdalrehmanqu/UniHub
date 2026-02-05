import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/avatar_image.dart';
import '../../auth/providers/auth_providers.dart';
import '../presentation/community_comments_sheet.dart';
import '../domain/community_post.dart';
import '../providers/community_providers.dart';

class CommunityPostCard extends ConsumerWidget {
  const CommunityPostCard({super.key, required this.post});

  final CommunityPost post;

  static const _deleteAction = 'delete';

  Future<void> _toggleSave(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (userId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sign in to save posts')),
      );
      return;
    }

    final repo = ref.read(communityRepositoryProvider);
    try {
      if (post.isSaved) {
        await repo.unsaveCommunityPost(userId: userId, postId: post.id);
      } else {
        await repo.saveCommunityPost(userId: userId, postId: post.id);
      }
      ref.invalidate(communityFeedProvider);
      ref.invalidate(savedCommunityFeedProvider);
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save post: $error')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete post?'),
          content: const Text('This will permanently remove your post.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    final repo = ref.read(communityRepositoryProvider);
    try {
      await repo.deleteCommunityPost(postId: post.id);
      ref.invalidate(communityFeedProvider);
      ref.invalidate(savedCommunityFeedProvider);
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete post: $error')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    final canDelete = userId != null && userId == post.authorId;
    return Container(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.background,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AvatarImage(
                  name: post.authorName,
                  imageUrl: post.authorAvatarUrl,
                  radius: 20,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  textStyle: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        formatTimeAgo(post.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canDelete)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz_rounded),
                    tooltip: 'More',
                    onSelected: (value) {
                      if (value == _deleteAction) {
                        _confirmDelete(context, ref);
                      }
                    },
                    itemBuilder: (context) {
                      return [
                        PopupMenuItem<String>(
                          value: _deleteAction,
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              const Text('Delete'),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              post.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (post.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  for (final tag in post.tags.take(3))
                    Text(
                      '#$tag',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  if (post.tags.length > 3)
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet<void>(
                          context: context,
                          backgroundColor: theme.colorScheme.background,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (context) {
                            return SafeArea(
                              top: false,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  20,
                                  24,
                                ),
                                child: Wrap(
                                  spacing: 10,
                                  runSpacing: 8,
                                  children: [
                                    for (final tag in post.tags)
                                      Text(
                                        '#$tag',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: Text(
                        'more',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CommunityCommentsPage(post: post),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 24,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.commentCount}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _toggleSave(context, ref),
                  icon: Icon(
                    post.isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                  ),
                  color: post.isSaved
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  tooltip: post.isSaved ? 'Unsave post' : 'Save post',
                  iconSize: 24,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  visualDensity: VisualDensity.compact,
                  splashRadius: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
