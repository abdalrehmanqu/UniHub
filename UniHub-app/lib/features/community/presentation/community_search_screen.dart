import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/search_screen.dart';
import '../providers/community_providers.dart';
import '../widgets/community_post_card.dart';

class CommunitySearchScreen extends ConsumerWidget {
  const CommunitySearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityFeed = ref.watch(communityFeedProvider);

    return communityFeed.when(
      data: (posts) => SearchScreen(
        title: 'Community posts',
        items: posts,
        onSearch: (post, query) {
          return post.title.toLowerCase().contains(query) ||
              post.content.toLowerCase().contains(query) ||
              post.authorName.toLowerCase().contains(query) ||
              post.tags.any((tag) => tag.toLowerCase().contains(query));
        },
        itemBuilder: (post) => CommunityPostCard(post: post),
      ),
      loading: () => const SearchScreen(
        title: 'Community posts',
        items: [],
        onSearch: _dummySearch,
        itemBuilder: _dummyBuilder,
        isLoading: true,
      ),
      error: (error, _) => SearchScreen(
        title: 'Community posts',
        items: const [],
        onSearch: _dummySearch,
        itemBuilder: _dummyBuilder,
        error: error.toString(),
      ),
    );
  }

  static bool _dummySearch(dynamic item, String query) => false;
  static Widget _dummyBuilder(dynamic item) => const SizedBox.shrink();
}
