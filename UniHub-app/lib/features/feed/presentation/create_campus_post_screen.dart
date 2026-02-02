import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../providers/feed_providers.dart';
import '../../../core/widgets/create_post_page.dart';

class CreateCampusPostScreen extends ConsumerWidget {
  const CreateCampusPostScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CreatePostPage(
      appBarTitle: 'Create Post',
      contextLabel: 'Posting to Campus feed',
      postButtonLabel: 'Post',
      mediaBucket: 'post-media',
      successMessage: 'Post created successfully',
      onSubmit: (payload) async {
        final client = ref.read(supabaseClientProvider);
        final userId = client.auth.currentUser?.id;
        if (userId == null) {
          throw StateError('You must be signed in to create a post.');
        }
        final repo = ref.read(feedRepositoryProvider);
        final content = payload.linkUrl == null || payload.linkUrl!.isEmpty
            ? payload.contentMarkdown
            : payload.contentMarkdown.isEmpty
                ? payload.linkUrl!
                : '${payload.linkUrl}\n\n${payload.contentMarkdown}';
        await repo.createCampusPost(
          authorId: userId,
          title: payload.title,
          content: content,
          mediaUrl: payload.mediaUrl,
          mediaType: payload.mediaType,
        );
      },
    );
  }
}
