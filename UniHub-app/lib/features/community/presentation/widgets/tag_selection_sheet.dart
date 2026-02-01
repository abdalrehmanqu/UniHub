import 'package:flutter/material.dart';

Future<Set<String>?> showTagSelectionSheet({
  required BuildContext context,
  required List<String> allTags,
  required Set<String> initialSelected,
  required String title,
}) {
  final theme = Theme.of(context);
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.colorScheme.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return _TagSelectionSheetContent(
        title: title,
        allTags: allTags,
        initialSelected: initialSelected,
      );
    },
  );
}

class _TagSelectionSheetContent extends StatefulWidget {
  const _TagSelectionSheetContent({
    required this.title,
    required this.allTags,
    required this.initialSelected,
  });

  final String title;
  final List<String> allTags;
  final Set<String> initialSelected;

  @override
  State<_TagSelectionSheetContent> createState() =>
      _TagSelectionSheetContentState();
}

class _TagSelectionSheetContentState extends State<_TagSelectionSheetContent> {
  final _searchController = TextEditingController();
  var _searchQuery = '';
  var _isSearchExpanded = false;
  late Set<String> _tempTags;

  @override
  void initState() {
    super.initState();
    _tempTags = Set<String>.from(widget.initialSelected);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredTags = _searchQuery.isEmpty
        ? widget.allTags
        : widget.allTags
              .where(
                (tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();
    final orderedTags = [
      ...filteredTags.where((tag) => _tempTags.contains(tag)),
      ...filteredTags.where((tag) => !_tempTags.contains(tag)),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.42,
      minChildSize: 0.32,
      maxChildSize: 0.55,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  if (!_isSearchExpanded)
                    Expanded(
                      child: Text(
                        widget.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (_isSearchExpanded)
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search tags...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  IconButton(
                    icon: Icon(
                      _isSearchExpanded ? Icons.close : Icons.search,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_isSearchExpanded) {
                          _isSearchExpanded = false;
                          _searchController.clear();
                          _searchQuery = '';
                        } else {
                          _isSearchExpanded = true;
                        }
                      });
                    },
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
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final tag in orderedTags)
                            _SheetTagChip(
                              tag: tag,
                              isSelected: _tempTags.contains(tag),
                              onTap: () {
                                setState(() {
                                  if (_tempTags.contains(tag)) {
                                    _tempTags.remove(tag);
                                  } else {
                                    _tempTags.add(tag);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _tempTags = {};
                        });
                      },
                      child: const Text('Clear'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop(_tempTags);
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SheetTagChip extends StatelessWidget {
  const _SheetTagChip({
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
