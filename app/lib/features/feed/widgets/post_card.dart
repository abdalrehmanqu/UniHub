import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/avatar_image.dart';
import '../../../core/widgets/network_image_fallback.dart';
import '../domain/campus_post.dart';

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post});

  final CampusPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMedia = post.mediaUrl != null && post.mediaUrl!.isNotEmpty;
    final borderColor = theme.colorScheme.outlineVariant.withOpacity(0.55);

    return Card(
      color: theme.colorScheme.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
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
                  radius: 22,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  textStyle: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
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
                Icon(Icons.verified_rounded, color: theme.colorScheme.secondary),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              post.title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              post.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (hasMedia) ...[
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: NetworkImageFallback(
                  url: post.mediaUrl!,
                  borderRadius: BorderRadius.circular(16),
                  fallbackIcon: Icons.broken_image_outlined,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.favorite, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  '${post.likeCount} likes',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chat_bubble_outline, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Discuss',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
