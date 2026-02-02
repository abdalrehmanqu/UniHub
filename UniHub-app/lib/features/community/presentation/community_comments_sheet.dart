import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../auth/providers/auth_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/avatar_image.dart';
import '../../../core/providers/ui_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../domain/community_comment.dart';
import '../domain/community_post.dart';
import '../providers/community_providers.dart';

Future<void> showCommunityCommentsSheet({
  required BuildContext context,
  required CommunityPost post,
}) {
  final theme = Theme.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  container.read(bottomNavVisibleProvider.notifier).state = false;
  container.read(commentsScrimOpacityProvider.notifier).state = 0.0;
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.black26,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  final sheetController = DraggableScrollableController();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    useSafeArea: false,
    builder: (context) {
      return DraggableScrollableSheet(
        controller: sheetController,
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.7,
        maxChildSize: 0.95,
        snap: true,
        snapSizes: const [0.7, 0.95],
        builder: (context, scrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            child: Container(
              color: theme.colorScheme.background,
              child: _CommunityCommentsSheet(
                post: post,
                scrollController: scrollController,
                sheetController: sheetController,
              ),
            ),
          );
        },
      );
    },
  ).whenComplete(() {
    container.read(bottomNavVisibleProvider.notifier).state = true;
    container.read(commentsScrimOpacityProvider.notifier).state = 0.0;
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
  });
}

class _CommunityCommentsSheet extends ConsumerStatefulWidget {
  const _CommunityCommentsSheet({
    required this.post,
    required this.scrollController,
    required this.sheetController,
  });

  final CommunityPost post;
  final ScrollController scrollController;
  final DraggableScrollableController sheetController;

  @override
  ConsumerState<_CommunityCommentsSheet> createState() =>
      _CommunityCommentsSheetState();
}

class _CommunityCommentsSheetState
    extends ConsumerState<_CommunityCommentsSheet> {
  final _controller = TextEditingController();
  final _inputFocus = FocusNode();
  CommunityComment? _replyingTo;
  bool _submitting = false;

  @override
  void dispose() {
    _inputFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    var text = _controller.text.trim();
    if (text.isEmpty) return;
    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (userId == null) return;

    if (_replyingTo != null) {
      final mention = '@${_replyingTo!.authorName}';
      while (text.startsWith(mention)) {
        text = text.substring(mention.length).trimLeft();
      }
    }

    setState(() => _submitting = true);
    try {
      await ref.read(communityRepositoryProvider).addCommunityComment(
            postId: widget.post.id,
            authorId: userId,
            content: text,
            parentId: _replyingTo?.parentId ?? _replyingTo?.id,
          );
      _controller.clear();
      setState(() {
        _replyingTo = null;
      });
      ref.invalidate(communityCommentsProvider(widget.post.id));
      ref.invalidate(communityFeedProvider);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          widget.scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sheetMin = 0.6;
    final sheetMax = 0.95;
    final screenHeight = MediaQuery.of(context).size.height;
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.asData?.value;
    final displayName = (profile?.displayName?.trim().isNotEmpty == true)
        ? profile!.displayName!
        : (profile?.username ?? 'You');
    final avatarUrl = profile?.avatarUrl;

    final commentsAsync = ref.watch(communityCommentsProvider(widget.post.id));

    final firstName = _shortName(widget.post.authorName);

    return SafeArea(
      top: false,
      child: Column(
            children: [
              const SizedBox(height: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  final delta = details.primaryDelta ?? 0;
                  final nextSize =
                      (widget.sheetController.size - delta / screenHeight)
                          .clamp(sheetMin, sheetMax);
                  widget.sheetController.jumpTo(nextSize);
                },
                onVerticalDragEnd: (_) {
                  final midpoint = (sheetMin + sheetMax) / 2;
                  final target =
                      widget.sheetController.size < midpoint ? sheetMin : sheetMax;
                  widget.sheetController.animateTo(
                    target,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                  );
                },
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Comments',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: commentsAsync.when(
                  data: (comments) {
                    if (comments.isEmpty) {
                      return Center(
                        child: Text(
                          'No comments yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }
                    final grouped = _buildCommentTree(comments);
                    return ListView(
                      controller: widget.scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                      children: [
                        for (final item in grouped)
                          _CommentItem(
                            comment: item.comment,
                            replies: item.replies,
                            onReply: (target) {
                              final mention = '@${target.authorName} ';
                              setState(() {
                                _replyingTo = target;
                              });
                              if (!_controller.text.startsWith(mention)) {
                                _controller.text = mention;
                                _controller.selection =
                                    TextSelection.fromPosition(
                                  TextPosition(offset: _controller.text.length),
                                );
                              }
                              _inputFocus.requestFocus();
                            },
                          ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text(
                      'Failed to load comments',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ),
              if (_replyingTo != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Replying to ${_replyingTo!.authorName}',
                          style: theme.textTheme.labelMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => setState(() => _replyingTo = null),
                      ),
                    ],
                  ),
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 1,
                    color: theme.colorScheme.outlineVariant.withOpacity(0.6),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 44,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (final emoji in const [
                                '❤️',
                                '🙌',
                                '🔥',
                                '👏',
                                '😢',
                                '😍',
                                '😮',
                                '😂',
                              ])
                                InkWell(
                                  onTap: () {
                                    _controller.text += emoji;
                                    _controller.selection = TextSelection.fromPosition(
                                      TextPosition(offset: _controller.text.length),
                                    );
                                  },
                                  child: Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            AvatarImage(
                              name: displayName,
                              imageUrl: avatarUrl,
                              radius: 20,
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              textStyle: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _controller,
                                builder: (context, value, _) {
                                  final hasText = value.text.trim().isNotEmpty;
                                  return TextField(
                                    controller: _controller,
                                    focusNode: _inputFocus,
                                    minLines: 1,
                                    maxLines: 2,
                                    textInputAction: TextInputAction.newline,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 16,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Add a comment to $firstName',
                                      filled: true,
                                      isDense: true,
                                      fillColor: theme.colorScheme.surfaceVariant
                                          .withOpacity(0.35),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      suffixIcon: hasText
                                          ? GestureDetector(
                                              onTap:
                                                  _submitting ? null : _submit,
                                              child: Container(
                                                width: 36,
                                                height: 36,
                                                margin:
                                                    const EdgeInsets.only(right: 6),
                                                decoration: BoxDecoration(
                                                  color:
                                                      theme.colorScheme.primary,
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                    Radius.circular(12),
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.arrow_upward_rounded,
                                                  size: 20,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            )
                                          : null,
                                      suffixIconConstraints:
                                          const BoxConstraints.tightFor(
                                        width: 42,
                                        height: 36,
                                      ),
                                      border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(18),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }
}

String _shortName(String name, {int max = 16}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'user';
  final first = trimmed.split(' ').first;
  if (first.length <= max) return first;
  return '${first.substring(0, max - 1)}…';
}

class _CommentItem extends StatefulWidget {
  const _CommentItem({
    required this.comment,
    required this.replies,
    required this.onReply,
  });

  final CommunityComment comment;
  final List<CommunityComment> replies;
  final ValueChanged<CommunityComment> onReply;

  @override
  State<_CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<_CommentItem> {
  bool _showReplies = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommentRow(
            comment: widget.comment,
            onReply: () => widget.onReply(widget.comment),
          ),
          if (!_showReplies && widget.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 2),
              child: TextButton(
                onPressed: () =>
                    setState(() => _showReplies = !_showReplies),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 1,
                      margin: const EdgeInsets.only(right: 8),
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.5),
                    ),
                    Text(
                      'View ${widget.replies.length} more replies',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          if (_showReplies && widget.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 6),
              child: Column(
                children: [
                  for (final reply in widget.replies)
                    _CommentRow(
                      comment: reply,
                      onReply: () => widget.onReply(reply),
                      isReply: true,
                      replyToName: widget.comment.authorName,
                    ),
                ],
              ),
            ),
          if (_showReplies && widget.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 4),
              child: TextButton(
                onPressed: () =>
                    setState(() => _showReplies = !_showReplies),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 1,
                      margin: const EdgeInsets.only(right: 8),
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.5),
                    ),
                    Text(
                      'Hide replies',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({
    required this.comment,
    required this.onReply,
    this.isReply = false,
    this.replyToName,
  });

  final CommunityComment comment;
  final VoidCallback onReply;
  final bool isReply;
  final String? replyToName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdmin = comment.authorRole?.toLowerCase() == 'admin';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvatarImage(
          name: comment.authorName,
          imageUrl: comment.authorAvatarUrl,
          radius: isReply ? 14 : 16,
          backgroundColor: theme.colorScheme.secondaryContainer,
          textStyle: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.authorName,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.verified_rounded,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                  const SizedBox(width: 8),
                  Text(
                    formatTimeAgo(comment.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (isReply && replyToName != null)
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: '@${replyToName!} ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(text: comment.content),
                    ],
                  ),
                )
              else
                Text(
                  comment.content,
                  style: theme.textTheme.bodyMedium,
                ),
              TextButton(
                onPressed: onReply,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Reply',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentGroup {
  const _CommentGroup({required this.comment, required this.replies});

  final CommunityComment comment;
  final List<CommunityComment> replies;
}

List<_CommentGroup> _buildCommentTree(List<CommunityComment> comments) {
  final roots = <CommunityComment>[];
  final replies = <String, List<CommunityComment>>{};

  for (final comment in comments) {
    final parentId = comment.parentId;
    if (parentId == null) {
      roots.add(comment);
    } else {
      replies.putIfAbsent(parentId, () => []).add(comment);
    }
  }

  return [
    for (final root in roots)
      _CommentGroup(
        comment: root,
        replies: replies[root.id] ?? [],
      ),
  ];
}
