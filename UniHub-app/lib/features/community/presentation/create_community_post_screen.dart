import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../../feed/presentation/create_campus_post_screen.dart';
import '../providers/community_providers.dart';
import 'widgets/tag_selection_sheet.dart';

class CreateCommunityPostScreen extends ConsumerStatefulWidget {
  const CreateCommunityPostScreen({super.key});

  @override
  ConsumerState<CreateCommunityPostScreen> createState() =>
      _CreateCommunityPostScreenState();
}

class _CreateCommunityPostScreenState
    extends ConsumerState<CreateCommunityPostScreen> {
  Future<void> _openTagSelectionSheet(
    BuildContext context,
    List<String> allTags,
  ) async {
    final result = await showTagSelectionSheet(
      context: context,
      allTags: allTags,
      initialSelected: ref.read(communityCreateTagsProvider),
      title: 'Tags (optional)',
    );
    if (result != null) {
      ref.read(communityCreateTagsProvider.notifier).state = result;
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(communityFeedProvider);
    final allTags = feed.maybeWhen(
      data: (posts) {
        final tags = <String>{};
        for (final post in posts) {
          tags.addAll(post.tags);
        }
        final sorted = tags.toList()..sort();
        return sorted;
      },
      orElse: () => <String>[],
    );

    return CreatePostPage(
      appBarTitle: 'Create Post',
      contextLabel: 'Posting to Community',
      postButtonLabel: 'Post',
      mediaBucket: 'post-media',
      successMessage: 'Community post created',
      contentPadding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
      extraFieldsBuilder: (context, ref) {
        final theme = Theme.of(context);
        final selectedTags = ref.watch(communityCreateTagsProvider);
        final previewTags = allTags.take(6).toList();
        final displayTags = <String>[];
        displayTags.addAll(selectedTags);
        for (final tag in previewTags) {
          if (!selectedTags.contains(tag)) {
            displayTags.add(tag);
          }
        }
        return [
          Row(
            children: [
              Text(
                'Tags (optional)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (displayTags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in displayTags)
                  _TagChip(
                    tag: tag,
                    isSelected: selectedTags.contains(tag),
                    onTap: () {
                      final newTags = Set<String>.from(selectedTags);
                      if (selectedTags.contains(tag)) {
                        newTags.remove(tag);
                      } else {
                        newTags.add(tag);
                      }
                      ref.read(communityCreateTagsProvider.notifier).state =
                          newTags;
                    },
                  ),
                ActionChip(
                  label: const Icon(Icons.add, size: 18),
                  onPressed: allTags.isEmpty
                      ? null
                      : () => _openTagSelectionSheet(context, allTags),
                  side: BorderSide(color: theme.colorScheme.outline),
                  backgroundColor: theme.colorScheme.surface,
                ),
              ],
            )
          else
            ActionChip(
              label: const Icon(Icons.add, size: 18),
              onPressed: allTags.isEmpty
                  ? null
                  : () => _openTagSelectionSheet(context, allTags),
              side: BorderSide(color: theme.colorScheme.outline),
              backgroundColor: theme.colorScheme.surface,
            ),
          const SizedBox(height: 4),
        ];
      },
      onSubmit: (payload) async {
        final client = ref.read(supabaseClientProvider);
        final userId = client.auth.currentUser?.id;
        if (userId == null) {
          throw StateError('You must be signed in to create a post.');
        }
        final repo = ref.read(communityRepositoryProvider);
        final content = payload.linkUrl == null || payload.linkUrl!.isEmpty
            ? payload.contentMarkdown
            : payload.contentMarkdown.isEmpty
            ? payload.linkUrl!
            : '${payload.linkUrl}\n\n${payload.contentMarkdown}';
        final tags = ref.read(communityCreateTagsProvider).toList();
        await repo.createCommunityPost(
          authorId: userId,
          title: payload.title,
          content: content,
          tags: tags,
          mediaUrl: payload.mediaUrl,
        );
        ref.read(communityCreateTagsProvider.notifier).state = {};
      },
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.tag,
    required this.isSelected,
    required this.onTap,
    this.compact = false,
  });

  final String tag;
  final bool isSelected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelBaseStyle =
        (compact ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium) ??
        theme.textTheme.bodyMedium ??
        const TextStyle();
    final chipDensity = compact ? VisualDensity.compact : VisualDensity.standard;
    final tapTarget = compact
        ? MaterialTapTargetSize.shrinkWrap
        : MaterialTapTargetSize.padded;
    final chipPadding = compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
        : null;

    if (isSelected) {
      return FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tag),
            const SizedBox(width: 4),
            Icon(Icons.close, size: compact ? 14 : 16),
          ],
        ),
        selected: true,
        onSelected: (_) => onTap(),
        backgroundColor: theme.colorScheme.primaryContainer,
        selectedColor: theme.colorScheme.primaryContainer,
        side: BorderSide(color: theme.colorScheme.primary),
        labelStyle: labelBaseStyle.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
        checkmarkColor: theme.colorScheme.onPrimaryContainer,
        showCheckmark: false,
        materialTapTargetSize: tapTarget,
        visualDensity: chipDensity,
        padding: chipPadding,
      );
    }

    return FilterChip(
      label: Text(tag),
      selected: false,
      onSelected: (_) => onTap(),
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(color: theme.colorScheme.outline),
      labelStyle: labelBaseStyle.copyWith(color: theme.colorScheme.onSurface),
      materialTapTargetSize: tapTarget,
      visualDensity: chipDensity,
      padding: chipPadding,
    );
  }
}
