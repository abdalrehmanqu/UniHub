import 'package:any_link_preview/any_link_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/providers/auth_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/avatar_image.dart';
import '../../../core/widgets/network_media_image.dart';
import '../../../core/widgets/network_video_player.dart';
import '../domain/campus_post.dart';
import '../providers/feed_providers.dart';

class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.post});

  final CampusPost post;

  static const _saveAction = 'save';
  static const _deleteAction = 'delete';

  _ParsedContent _parseContent(String content) {
    final lines = content.split('\n');
    final urlLineIndex = lines.indexWhere((line) => line.trim().isNotEmpty);
    if (urlLineIndex == -1) {
      return _ParsedContent(body: content.trimRight());
    }

    final candidate = lines[urlLineIndex].trim();
    final uri = Uri.tryParse(candidate);
    final isUrl =
        uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
    if (!isUrl) {
      return _ParsedContent(body: content.trimRight());
    }

    lines.removeAt(urlLineIndex);
    while (urlLineIndex < lines.length && lines[urlLineIndex].trim().isEmpty) {
      lines.removeAt(urlLineIndex);
    }
    final body = lines.join('\n').trimRight();
    return _ParsedContent(url: candidate, body: body);
  }

  String _displayUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url;
    final path = uri.path.isEmpty ? '' : uri.path;
    final query = uri.query.isEmpty ? '' : '?${uri.query}';
    final value = '${uri.host}$path$query';
    return value.isEmpty ? url : value;
  }

  Widget _buildLinkFallback(BuildContext context, String url) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.link_rounded,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _displayUrl(url),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 10,
                  width: 160,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 8,
                  width: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildLinkPreview(BuildContext context, String url) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(16);
    return AnyLinkPreview.builder(
      link: url,
      cache: const Duration(days: 7),
      placeholderWidget: _buildLinkPlaceholder(context),
      errorWidget: _buildLinkFallback(context, url),
      itemBuilder: (context, metadata, imageProvider, svg) {
        final title = metadata.title?.trim();
        final description = metadata.desc?.trim();
        final siteName = metadata.siteName?.trim();
        final displayHost = _displayUrl(url);
        final header = siteName?.isNotEmpty == true ? siteName! : displayHost;

        Widget media;
        if (imageProvider != null) {
          media = Image(image: imageProvider, fit: BoxFit.cover);
        } else if (svg != null) {
          media = svg;
        } else {
          media = Container(
            color: theme.colorScheme.surface,
            child: Icon(
              Icons.link_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
        }

        return Material(
          color: theme.colorScheme.background,
          borderRadius: borderRadius,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: () => _openLink(url),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.link_rounded,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                header,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title?.isNotEmpty == true ? title! : displayHost,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (description?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(width: 72, height: 72, child: media),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete post?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ref.read(feedRepositoryProvider).deleteCampusPost(postId: post.id);
      ref.invalidate(campusFeedProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post deleted')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete post: $error')),
        );
      }
    }
  }

  Future<void> _toggleSave(BuildContext context, WidgetRef ref) async {
    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sign in to save posts')));
      return;
    }

    try {
      final repo = ref.read(feedRepositoryProvider);
      if (post.isSaved) {
        await repo.unsaveCampusPost(userId: userId, postId: post.id);
      } else {
        await repo.saveCampusPost(userId: userId, postId: post.id);
      }
      ref.invalidate(campusFeedProvider);
      ref.invalidate(savedCampusFeedProvider);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save post: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUserId = ref
        .watch(supabaseClientProvider)
        .auth
        .currentUser
        ?.id;
    final canDelete = currentUserId != null && post.authorId == currentUserId;
    final hasMedia = post.mediaUrl != null && post.mediaUrl!.isNotEmpty;
    final mediaType = post.mediaType?.toLowerCase();
    final isVideo =
        mediaType?.startsWith('video/') == true ||
        (post.mediaUrl?.toLowerCase().contains('.mp4') ?? false) ||
        (post.mediaUrl?.toLowerCase().contains('.mov') ?? false) ||
        (post.mediaUrl?.toLowerCase().contains('.m4v') ?? false) ||
        (post.mediaUrl?.toLowerCase().contains('.webm') ?? false);
    final parsedContent = _parseContent(post.content);
    final linkUrl = parsedContent.url;
    final bodyText = parsedContent.body;

    return Container(
      color: theme.colorScheme.background,
      margin: EdgeInsets.zero,
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
                Icon(
                  Icons.verified_rounded,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 6),
                if (canDelete)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz_rounded),
                    tooltip: 'More',
                    onSelected: (value) {
                      switch (value) {
                        case _saveAction:
                          _toggleSave(context, ref);
                          break;
                        case _deleteAction:
                          _confirmDelete(context, ref);
                          break;
                      }
                    },
                    itemBuilder: (context) {
                      return [
                        PopupMenuItem<String>(
                          value: _saveAction,
                          child: Row(
                            children: [
                              Icon(
                                post.isSaved
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                size: 18,
                                color: theme.colorScheme.onSurface,
                              ),
                              const SizedBox(width: 8),
                              Text(post.isSaved ? 'Unsave' : 'Save'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: _deleteAction,
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                  )
                else
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
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              post.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (linkUrl != null) ...[
              const SizedBox(height: 8),
              _buildLinkPreview(context, linkUrl),
            ],
            if (bodyText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                bodyText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
            if (hasMedia) ...[
              const SizedBox(height: 12),
              isVideo
                  ? NetworkVideoPlayer(
                      url: post.mediaUrl!,
                      borderRadius: BorderRadius.circular(16),
                      fallbackAspectRatio: 9 / 16,
                    )
                  : NetworkMediaImage(
                      url: post.mediaUrl!,
                      borderRadius: BorderRadius.circular(16),
                      fallbackIcon: Icons.broken_image_outlined,
                      fallbackAspectRatio: 4 / 3,
                    ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ParsedContent {
  const _ParsedContent({this.url, required this.body});

  final String? url;
  final String body;
}
