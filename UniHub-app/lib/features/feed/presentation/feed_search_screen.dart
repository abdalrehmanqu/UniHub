import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/search_screen.dart';
import '../providers/feed_providers.dart';
import '../widgets/post_card.dart';

class FeedSearchScreen extends ConsumerWidget {
  const FeedSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campusFeed = ref.watch(campusFeedProvider);

    return campusFeed.when(
      data: (posts) => SearchScreen(
        title: 'Campus feed',
        items: posts,
        onSearch: (post, query) {
          return post.title.toLowerCase().contains(query) ||
              post.content.toLowerCase().contains(query) ||
              post.authorName.toLowerCase().contains(query);
        },
        itemBuilder: (post) => PostCard(post: post),
      ),
      loading: () => const SearchScreen(
        title: 'Campus feed',
        items: [],
        onSearch: _dummySearch,
        itemBuilder: _dummyBuilder,
        isLoading: true,
      ),
      error: (error, _) => SearchScreen(
        title: 'Campus feed',
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
