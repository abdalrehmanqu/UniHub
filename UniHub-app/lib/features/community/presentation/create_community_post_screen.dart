import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/rendering.dart';

import '../../auth/providers/auth_providers.dart';
import 'package:unihub/core/widgets/create_post_page.dart';
import '../providers/community_providers.dart';

class CreateCommunityPostScreen extends ConsumerStatefulWidget {
  const CreateCommunityPostScreen({super.key});

  @override
  ConsumerState<CreateCommunityPostScreen> createState() =>
      _CreateCommunityPostScreenState();
}

class _CreateCommunityPostScreenState
    extends ConsumerState<CreateCommunityPostScreen> {
  final _tagSearchController = TextEditingController();
  final _tagSearchFocusNode = FocusNode();
  final _tagsSectionKey = GlobalKey();
  final _contentScrollController = ScrollController();
  final Set<String> _customTags = {};
  bool _isTagSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _tagSearchFocusNode.addListener(() {
      if (_tagSearchFocusNode.hasFocus) {
        _ensureTagsVisible();
      }
    });
  }

  @override
  void dispose() {
    _tagSearchController.dispose();
    _tagSearchFocusNode.dispose();
    _contentScrollController.dispose();
    super.dispose();
  }

  String _normalizeTag(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return '';
    final withoutHash = trimmed.startsWith('#')
        ? trimmed.substring(1)
        : trimmed;
    return withoutHash.replaceAll(RegExp(r'\\s+'), '-');
  }

  void _ensureTagsVisible() {
    final context = _tagsSectionKey.currentContext;
    if (context == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderObject = context.findRenderObject();
      if (renderObject is RenderBox) {
        final viewport = RenderAbstractViewport.of(renderObject);
        final offset = viewport.getOffsetToReveal(renderObject, 0.1).offset;
        if (_contentScrollController.hasClients) {
          _contentScrollController.animateTo(
            offset,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
          return;
        }
      }
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: 0.1,
      );
    });
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
    final availableTags = {...allTags, ..._customTags}.toList()..sort();

    return CreatePostPage(
      appBarTitle: 'Create Post',
      contextLabel: 'Posting to Community',
      postButtonLabel: 'Post',
      mediaBucket: 'post-media',
      successMessage: 'Community post created',
      contentPadding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
      scrollController: _contentScrollController,
      extraFieldsBuilder: (context, ref) {
        final theme = Theme.of(context);
        final selectedTags = ref.watch(communityCreateTagsProvider);
        final previewTags = availableTags.take(6).toList();
        final displayTags = <String>[];
        displayTags.addAll(selectedTags);
        for (final tag in previewTags) {
          if (!selectedTags.contains(tag)) {
            displayTags.add(tag);
          }
        }
        final tagQuery = _normalizeTag(_tagSearchController.text);
        final filteredTags = tagQuery.isEmpty
            ? displayTags
            : displayTags
                .where((tag) => tag.toLowerCase().contains(tagQuery))
                .toList();
        final canAddTag =
            tagQuery.isNotEmpty &&
            !availableTags.map((t) => t.toLowerCase()).contains(tagQuery);
        return [
          Row(
            key: _tagsSectionKey,
            children: [
              Text(
                'Tags (optional)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                alignment: Alignment.centerLeft,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _isTagSearchExpanded
                      ? SizedBox(
                          key: const ValueKey('tag-search'),
                          width: 200,
                          height: 35,
                          child: TextField(
                            controller: _tagSearchController,
                            focusNode: _tagSearchFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Search/add tag',
                              prefixIcon: const Icon(Icons.search, size: 16),
                              suffixIcon: _tagSearchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        setState(() {
                                          _tagSearchController.clear();
                                        });
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        )
                      : const SizedBox(
                          key: ValueKey('tag-search-collapsed'),
                          width: 0,
                          height: 0,
                        ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _isTagSearchExpanded ? Icons.close : Icons.search,
                ),
                onPressed: () {
                  setState(() {
                    _isTagSearchExpanded = !_isTagSearchExpanded;
                    if (!_isTagSearchExpanded) {
                      _tagSearchController.clear();
                      _tagSearchFocusNode.unfocus();
                    } else {
                      _tagSearchFocusNode.requestFocus();
                    }
                  });
                  if (_isTagSearchExpanded) {
                    _ensureTagsVisible();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom:
                  _isTagSearchExpanded ? MediaQuery.of(context).viewInsets.bottom : 0,
            ),
            child: filteredTags.isNotEmpty
                ? Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in filteredTags)
                        _TagChip(
                          tag: tag,
                          isSelected: selectedTags.contains(tag),
                          onTap: () {
                            final newTags = Set<String>.from(selectedTags);
                            if (selectedTags.contains(tag)) {
                              newTags.remove(tag);
                              if (_customTags.contains(tag) &&
                                  !allTags.contains(tag)) {
                                setState(() {
                                  _customTags.remove(tag);
                                });
                              }
                            } else {
                              newTags.add(tag);
                            }
                            ref.read(communityCreateTagsProvider.notifier).state =
                                newTags;
                          },
                        ),
                      ActionChip(
                        label: const Icon(Icons.add, size: 18),
                        onPressed: canAddTag
                            ? () {
                                final newTag = _normalizeTag(
                                  _tagSearchController.text,
                                );
                                if (newTag.isEmpty) return;
                                setState(() {
                                  _customTags.add(newTag);
                                  _tagSearchController.clear();
                                });
                                final newTags = Set<String>.from(selectedTags)
                                  ..add(newTag);
                                ref
                                        .read(
                                          communityCreateTagsProvider.notifier,
                                        )
                                        .state =
                                    newTags;
                              }
                            : null,
                        side: BorderSide(color: theme.colorScheme.outline),
                        backgroundColor: theme.colorScheme.surface,
                      ),
                    ],
                  )
                : ActionChip(
                    label: const Icon(Icons.add, size: 18),
                    onPressed: canAddTag
                        ? () {
                            final newTag = _normalizeTag(
                              _tagSearchController.text,
                            );
                            if (newTag.isEmpty) return;
                            setState(() {
                              _customTags.add(newTag);
                              _tagSearchController.clear();
                            });
                            final newTags = Set<String>.from(selectedTags)
                              ..add(newTag);
                            ref
                                    .read(
                                      communityCreateTagsProvider.notifier,
                                    )
                                    .state =
                                newTags;
                          }
                        : null,
                    side: BorderSide(color: theme.colorScheme.outline),
                    backgroundColor: theme.colorScheme.surface,
                  ),
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
        setState(() {
          _customTags.clear();
          _tagSearchController.clear();
          _isTagSearchExpanded = false;
        });
      },
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
    final labelBaseStyle =
        theme.textTheme.bodyMedium ?? theme.textTheme.bodySmall ?? const TextStyle();

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
        labelStyle: labelBaseStyle.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
        checkmarkColor: theme.colorScheme.onPrimaryContainer,
        showCheckmark: false,
      );
    }

    return FilterChip(
      label: Text(tag),
      selected: false,
      onSelected: (_) => onTap(),
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(color: theme.colorScheme.outline),
      labelStyle: labelBaseStyle.copyWith(color: theme.colorScheme.onSurface),
    );
  }
}
