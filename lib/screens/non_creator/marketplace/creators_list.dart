
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/screens/non_creator/marketplace/creator.dart';
import 'package:soundhive2/lib/dashboard_provider/creatorProvider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/utils.dart';

class CreatorsList extends ConsumerStatefulWidget {
  final String? initialJobTitleFilter;

  const CreatorsList({
    super.key,
    this.initialJobTitleFilter,  // Add this
  });

  @override
  ConsumerState<CreatorsList> createState() => _CreatorsListState();
}

class _CreatorsListState extends ConsumerState<CreatorsList> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load creators when widget initializes
    if (widget.initialJobTitleFilter != null) {
      _searchController.text = widget.initialJobTitleFilter!;
    }

    // Load creators when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialJobTitleFilter != null) {
        // If we have initial filter, perform search
        ref.read(creatorProvider.notifier).searchCreators(widget.initialJobTitleFilter!);
      } else {
        // Otherwise load all creators
        ref.read(creatorProvider.notifier).getCreators();
      }
    });

    _searchController.addListener(_onSearchChanged);

    // Setup infinite scroll
    _scrollController.addListener(_onScroll);
  }

  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      final searchQuery = _searchController.text.trim();
      if (searchQuery.isEmpty) {
        // If search is cleared, load without search
        ref.read(creatorProvider.notifier).getCreators(page: 1);
      } else {
        // Perform search
        ref.read(creatorProvider.notifier).searchCreators(searchQuery);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // Load more data when reaching the bottom
      ref.read(creatorProvider.notifier).loadNextPage();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creatorState = ref.watch(creatorProvider);

    return Scaffold(
      backgroundColor: AppColors.BACKGROUNDCOLOR,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top performing creatives',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Search Box
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search creators...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white38),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(creatorProvider.notifier).getCreators(page: 1);
                    },
                  )
                      : null,
                ),
              ),
            ),

            // Creator List
            Expanded(
              child: creatorState.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Failed to load creators',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(creatorProvider.notifier).getCreators();
                        },
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (creatorResponse) {
                  final creators = creatorResponse.user?.data ?? [];

                  if (creators.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            color: Colors.white38,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'No creators found'
                                : 'No creators found for "${_searchController.text}"',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 16,
                            ),
                          ),
                          if (_searchController.text.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                ref.read(creatorProvider.notifier).getCreators(page: 1);
                              },
                              child: const Text(
                                'Clear search',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    controller: _scrollController,
                    itemCount: creators.length + 1, // +1 for loading indicator
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                    ),
                    itemBuilder: (context, index) {
                      // Show loading indicator at the end
                      if (index == creators.length) {
                        final hasMorePages = creatorResponse.user?.nextPageUrl != null;
                        if (hasMorePages) {
                          return const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      }

                      final creator = creators[index];
                      double getOverallRating() {
                        final reviews = creator.reviews;

                        if (reviews.isEmpty) return 0.0;

                        double total = 0;
                        for (var r in reviews) {
                          total += r.rating;
                        }

                        return total / reviews.length;
                      }
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreatorProfile(
                                creator: creator,
                              ),
                            ),
                          );
                        },
                        child: Utils.buildCreativeCard(
                          context,
                          name: '${creator.user?.firstName} ${creator.user?.lastName}',
                          role: creator.jobTitle,
                          rating: getOverallRating(),
                          profileImage: creator.user?.image ?? '',
                          firstName: creator.user?.firstName ?? '',
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
