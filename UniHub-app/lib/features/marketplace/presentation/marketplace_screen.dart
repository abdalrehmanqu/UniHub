import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/marketplace_listing.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/listing_card.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  late final TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(marketplaceSearchQueryProvider),
    );
    _searchController.addListener(() {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 250), () {
        ref.read(marketplaceSearchQueryProvider.notifier).state =
            _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listings = ref.watch(marketplaceListingsProvider);
    final viewMode = ref.watch(marketplaceViewModeProvider);
    final isGrid = viewMode == MarketplaceViewMode.grid;
    final searchQuery = ref.watch(marketplaceSearchQueryProvider);
    final filters = ref.watch(marketplaceFiltersProvider);
    final sortMode = ref.watch(marketplaceSortProvider);

    List<MarketplaceListing> applyFilters(List<MarketplaceListing> items) {
      final query = searchQuery.trim().toLowerCase();
      final filtered = items.where((item) {
        if (query.isNotEmpty) {
          final haystack = [
            item.title,
            item.description,
            item.sellerName,
            item.location ?? '',
          ].join(' ').toLowerCase();
          if (!haystack.contains(query)) return false;
        }
        if (filters.onlyWithImages &&
            (item.imageUrl == null || item.imageUrl!.isEmpty)) {
          return false;
        }
        if (filters.minPrice != null && item.price < filters.minPrice!) {
          return false;
        }
        if (filters.maxPrice != null && item.price > filters.maxPrice!) {
          return false;
        }
        return true;
      }).toList();

      switch (sortMode) {
        case MarketplaceSort.newest:
          filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case MarketplaceSort.oldest:
          filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
        case MarketplaceSort.priceLowHigh:
          filtered.sort((a, b) => a.price.compareTo(b.price));
          break;
        case MarketplaceSort.priceHighLow:
          filtered.sort((a, b) => b.price.compareTo(a.price));
          break;
      }
      return filtered;
    }

    String sortLabel(MarketplaceSort sort) {
      switch (sort) {
        case MarketplaceSort.newest:
          return 'Newest';
        case MarketplaceSort.oldest:
          return 'Oldest';
        case MarketplaceSort.priceLowHigh:
          return 'Price: Low to High';
        case MarketplaceSort.priceHighLow:
          return 'Price: High to Low';
      }
    }

    Future<void> openSortSheet() async {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: theme.colorScheme.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Sort by',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (final option in MarketplaceSort.values)
                  RadioListTile<MarketplaceSort>(
                    value: option,
                    groupValue: sortMode,
                    onChanged: (value) {
                      if (value == null) return;
                      ref.read(marketplaceSortProvider.notifier).state = value;
                      Navigator.of(context).pop();
                    },
                    title: Text(sortLabel(option)),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      );
    }

    Future<void> openFilterSheet() async {
      var minText = filters.minPrice?.toStringAsFixed(0) ?? '';
      var maxText = filters.maxPrice?.toStringAsFixed(0) ?? '';
      var onlyWithImages = filters.onlyWithImages;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: theme.colorScheme.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 24),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Filters',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Price range',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: minText,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Min',
                              ),
                              onChanged: (value) {
                                minText = value;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              initialValue: maxText,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Max',
                              ),
                              onChanged: (value) {
                                maxText = value;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: onlyWithImages,
                        onChanged: (value) {
                          setState(() {
                            onlyWithImages = value;
                          });
                        },
                        title: const Text('Only listings with photos'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              ref.read(marketplaceFiltersProvider.notifier).state =
                                  const MarketplaceFilters();
                              Navigator.of(context).pop();
                            },
                            child: const Text('Clear'),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () {
                              final minValue = double.tryParse(minText.trim());
                              final maxValue = double.tryParse(maxText.trim());
                              ref.read(marketplaceFiltersProvider.notifier).state =
                                  MarketplaceFilters(
                                minPrice: minValue,
                                maxPrice: maxValue,
                                onlyWithImages: onlyWithImages,
                              );
                              Navigator.of(context).pop();
                            },
                            child: const Text('Apply'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      );
    }

    Widget buildControls() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search marketplace',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _searchFocusNode.requestFocus();
                          },
                        ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: openFilterSheet,
              tooltip: filters.isActive ? 'Filters (on)' : 'Filters',
              icon: Icon(
                Icons.tune_rounded,
                color: filters.isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            IconButton(
              onPressed: openSortSheet,
              tooltip: sortLabel(sortMode),
              icon: Icon(
                Icons.sort_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: listings.when(
          data: (items) {
            final filteredItems = applyFilters(items);
            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                final Widget content;
                if (filteredItems.isEmpty) {
                  content = _EmptyState(
                    title: items.isEmpty
                        ? 'Your campus market is quiet'
                        : 'No matching listings',
                    subtitle: items.isEmpty
                        ? 'Listings from students and clubs will show up here.'
                        : 'Try a different search or clear filters.',
                  );
                } else if (isGrid) {
                  final crossAxisCount = isWide ? 3 : 2;
                  content = GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) =>
                        ListingCard(listing: filteredItems[index]),
                  );
                } else {
                  content = ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        ListingCard(listing: filteredItems[index]),
                  );
                }
                return Column(
                  children: [
                    buildControls(),
                    Expanded(child: content),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _EmptyState(
            title: 'Unable to load marketplace',
            subtitle: error.toString(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        label: const Text('Sell item'),
        icon: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

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
            Icon(Icons.storefront_rounded, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
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
