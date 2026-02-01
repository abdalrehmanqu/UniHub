import 'package:flutter/material.dart';

class SearchScreen<T> extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.title,
    required this.items,
    required this.onSearch,
    required this.itemBuilder,
    this.isLoading = false,
    this.error,
  });

  final String title;
  final List<T> items;
  final bool Function(T item, String query) onSearch;
  final Widget Function(T item) itemBuilder;
  final bool isLoading;
  final String? error;

  @override
  State<SearchScreen<T>> createState() => _SearchScreenState<T>();
}

class _SearchScreenState<T> extends State<SearchScreen<T>> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<T> _filterItems() {
    if (_searchQuery.isEmpty) {
      return [];
    }

    return widget.items.where((item) {
      return widget.onSearch(item, _searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: _EmptySearchState(
          icon: Icons.error_outline,
          title: 'Unable to search',
          subtitle: widget.error!,
        ),
      );
    }

    final filteredItems = _filterItems();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: widget.title,
            border: InputBorder.none,
            hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          style: theme.textTheme.bodyLarge,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
            ),
        ],
      ),
      body: SafeArea(
        child: _searchQuery.isEmpty
            ? _EmptySearchState(
                icon: Icons.search,
                title: 'Search ${widget.title.toLowerCase()}',
                subtitle: 'Enter keywords to find what you\'re looking for',
              )
            : filteredItems.isEmpty
            ? _EmptySearchState(
                icon: Icons.search_off,
                title: 'No results found',
                subtitle: 'Try different keywords or check your spelling',
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${filteredItems.length} result${filteredItems.length == 1 ? '' : 's'} found',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        return widget.itemBuilder(filteredItems[index]);
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
