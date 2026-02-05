import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/avatar_image.dart';
import '../../profile/providers/profile_providers.dart';
import '../domain/community_comment.dart';
import '../domain/community_post.dart';
import '../providers/community_providers.dart';

class CommunityCommentsPage extends ConsumerStatefulWidget {
  const CommunityCommentsPage({super.key, required this.post});

  final CommunityPost post;

  @override
  ConsumerState<CommunityCommentsPage> createState() =>
      _CommunityCommentsPageState();
}

class _CommunityCommentsPageState extends ConsumerState<CommunityCommentsPage> {
  final _controller = TextEditingController();
  final _inputFocus = FocusNode();
  final _scrollController = ScrollController();
  CommunityComment? _replyingTo;
  bool _submitting = false;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final container = ProviderScope.containerOf(context, listen: false);
      container.read(bottomNavVisibleProvider.notifier).state = false;
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      );
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _inputFocus.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final next = _scrollController.hasClients && _scrollController.offset > 24;
    if (next != _isScrolled && mounted) {
      setState(() => _isScrolled = next);
    }
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
      await ref
          .read(communityRepositoryProvider)
          .addCommunityComment(
            postId: widget.post.id,
            authorId: userId,
            content: text,
            parentId: _replyingTo?.id,
          );
      _controller.clear();
      setState(() {
        _replyingTo = null;
      });
      ref.invalidate(communityCommentsProvider(widget.post.id));
      ref.invalidate(communityFeedProvider);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
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
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.asData?.value;
    final displayName = (profile?.displayName?.trim().isNotEmpty == true)
        ? profile!.displayName!
        : (profile?.username ?? 'You');
    final avatarUrl = profile?.avatarUrl;

    final commentsAsync = ref.watch(communityCommentsProvider(widget.post.id));

    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) {
          ref.read(bottomNavVisibleProvider.notifier).state = true;
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          backgroundColor: _isScrolled
              ? theme.colorScheme.surfaceVariant
              : theme.colorScheme.background,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          titleSpacing: 0,
          title: Text(
            'Comments',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 21,
              color: theme.colorScheme.onBackground,
            ),
          ),
          actions: const [SizedBox(width: 4)],
          bottom: _isScrolled
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: theme.colorScheme.outlineVariant.withOpacity(0.7),
                  ),
                )
              : null,
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: commentsAsync.when(
                  data: (comments) {
                    final grouped = _buildCommentTree(comments);
                    return ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                      children: [
                        _PostHeader(post: widget.post),
                        const SizedBox(height: 12),
                        if (comments.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Center(
                              child: Text(
                                'No comments yet',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        else
                          for (final item in grouped)
                            _CommentThread(
                              node: item,
                              depth: 0,
                              onReply: (target) {
                                final mention = '@${target.authorName} ';
                                setState(() {
                                  _replyingTo = target;
                                });
                                if (!_controller.text.startsWith(mention)) {
                                  _controller.text = mention;
                                  _controller.selection =
                                      TextSelection.fromPosition(
                                        TextPosition(
                                          offset: _controller.text.length,
                                        ),
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
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.7),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Replying to ${_replyingTo!.authorName}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _replyingTo = null),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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
                      top: 10,
                    ),
                    child: Row(
                      children: [
                        AvatarImage(
                          name: displayName,
                          imageUrl: avatarUrl,
                          radius: 18,
                          backgroundColor: theme.colorScheme.primaryContainer,
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
                                  hintText: 'Join the conversation',
                                  filled: true,
                                  isDense: true,
                                  fillColor: theme.colorScheme.surfaceVariant
                                      .withOpacity(0.25),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  suffixIcon: hasText
                                      ? GestureDetector(
                                          onTap: _submitting ? null : _submit,
                                          child: Container(
                                            width: 34,
                                            height: 34,
                                            margin: const EdgeInsets.only(
                                              right: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: const Icon(
                                              Icons.arrow_upward_rounded,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                      : null,
                                  suffixIconConstraints:
                                      const BoxConstraints.tightFor(
                                        width: 40,
                                        height: 34,
                                      ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeLabel = formatTimeAgo(post.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          post.title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (post.content.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(post.content, style: theme.textTheme.bodyMedium),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            AvatarImage(
              name: post.authorName,
              imageUrl: post.authorAvatarUrl,
              radius: 14,
              backgroundColor: theme.colorScheme.secondaryContainer,
              textStyle: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${post.authorName} • $timeLabel',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${post.commentCount} comments',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: theme.colorScheme.outlineVariant.withOpacity(0.6)),
      ],
    );
  }
}

class _CommentThread extends StatefulWidget {
  const _CommentThread({
    required this.node,
    required this.depth,
    required this.onReply,
    this.replyToName,
  });

  final _CommentNode node;
  final int depth;
  final ValueChanged<CommunityComment> onReply;
  final String? replyToName;

  @override
  State<_CommentThread> createState() => _CommentThreadState();
}

class _CommentThreadState extends State<_CommentThread> {
  bool _showReplies = false;

  @override
  Widget build(BuildContext context) {
    final replies = widget.node.replies;
    final hasReplies = replies.isNotEmpty;

    return Stack(
      children: [
        if (widget.depth > 0)
          const Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: _ThreadIndentGuides(depth: 1),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.depth > 0) const SizedBox(width: _threadIndent),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CommentRow(
                      comment: widget.node.comment,
                      onReply: () => widget.onReply(widget.node.comment),
                      isReply: widget.depth > 0,
                      replyToName: widget.replyToName,
                    ),
                    if (hasReplies && !_showReplies)
                      _RepliesToggle(
                        label: _replyCountLabel(replies.length),
                        onPressed: () => setState(() => _showReplies = true),
                        depth: widget.depth,
                      ),
                    if (hasReplies && _showReplies)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          children: [
                            for (final reply in replies)
                              _CommentThread(
                                node: reply,
                                depth: widget.depth + 1,
                                onReply: widget.onReply,
                                replyToName: widget.node.comment.authorName,
                              ),
                          ],
                        ),
                      ),
                    if (hasReplies && _showReplies)
                      _RepliesToggle(
                        label: 'Hide replies',
                        onPressed: () => setState(() => _showReplies = false),
                        depth: widget.depth,
                        icon: Icons.keyboard_arrow_up_rounded,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RepliesToggle extends StatelessWidget {
  const _RepliesToggle({
    required this.label,
    required this.onPressed,
    required this.depth,
    this.icon = Icons.keyboard_arrow_down_rounded,
  });

  final String label;
  final VoidCallback onPressed;
  final int depth;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: _commentContentOffset + _threadIndent,
        top: 2,
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _ThreadIndentGuides extends StatelessWidget {
  const _ThreadIndentGuides({required this.depth});

  final int depth;

  @override
  Widget build(BuildContext context) {
    if (depth <= 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final lineColor = theme.colorScheme.outlineVariant.withOpacity(0.7);
    return SizedBox(
      width: _threadIndent,
      child: Align(
        alignment: Alignment.center,
        child: Container(width: 2, height: double.infinity, color: lineColor),
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
    final timeLabel = formatTimeAgo(comment.createdAt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.authorName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                    const SizedBox(width: 6),
                    Text(
                      '• $timeLabel',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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
            Text(comment.content, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: _ReplyAction(onTap: onReply),
          ),
        ],
      ),
    );
  }
}

class _ReplyAction extends StatelessWidget {
  const _ReplyAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant.withOpacity(0.7);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          'Reply',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _CommentNode {
  _CommentNode({required this.comment}) : replies = [];

  final CommunityComment comment;
  final List<_CommentNode> replies;
}

List<_CommentNode> _buildCommentTree(List<CommunityComment> comments) {
  final nodesById = <String, _CommentNode>{};
  for (final comment in comments) {
    nodesById[comment.id] = _CommentNode(comment: comment);
  }

  final roots = <_CommentNode>[];
  for (final comment in comments) {
    final node = nodesById[comment.id]!;
    final parentId = comment.parentId;
    final parentNode = parentId == null ? null : nodesById[parentId];
    if (parentNode == null) {
      roots.add(node);
    } else {
      parentNode.replies.add(node);
    }
  }
  return roots;
}

String _replyCountLabel(int count) {
  if (count == 1) return '1 more reply';
  return '$count more replies';
}

const double _threadIndent = 12;
const double _commentContentOffset = 42;
