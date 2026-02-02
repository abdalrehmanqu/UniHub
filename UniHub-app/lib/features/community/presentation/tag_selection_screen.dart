import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


class TagSelectionScreen extends ConsumerStatefulWidget {
  const TagSelectionScreen({
    super.key,
    required this.allTags,
    required this.tagsProvider,
  });

  final List<String> allTags;
  final StateProvider<Set<String>> tagsProvider;

  @override
  ConsumerState<TagSelectionScreen> createState() => _TagSelectionScreenState();
}

class _TagSelectionScreenState extends ConsumerState<TagSelectionScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getFilteredTags() {
    if (_searchQuery.isEmpty) {
      return widget.allTags;
    }
    final query = _searchQuery.toLowerCase();
    return widget.allTags
        .where((tag) => tag.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedTags = ref.watch(widget.tagsProvider);
    final filteredTags = _getFilteredTags();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search tags...',
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
        child: Column(
          children: [
            if (selectedTags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${selectedTags.length} selected',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(widget.tagsProvider.notifier).state = {};
                      },
                      child: const Text('Clear all'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: filteredTags.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 56,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tags found',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try different keywords',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Wrap(
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
                                } else {
                                  newTags.add(tag);
                                }
                                ref.read(widget.tagsProvider.notifier).state =
                                    newTags;
                              },
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: () {
              context.pop();
            },
            child: const Text('Apply'),
          ),
        ),
      ),
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
        labelStyle: TextStyle(color: theme.colorScheme.onPrimaryContainer),
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
      labelStyle: TextStyle(color: theme.colorScheme.onSurface),
    );
  }
}
