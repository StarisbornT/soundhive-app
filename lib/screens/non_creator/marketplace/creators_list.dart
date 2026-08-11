import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/lib/dashboard_provider/creatorProvider.dart';
import '../../../services/creator_profile_loader.dart';
import '../../../utils/utils.dart';

class CreatorsList extends ConsumerStatefulWidget {
  final String? initialJobTitleFilter;

  const CreatorsList({
    super.key,
    this.initialJobTitleFilter,
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
    if (widget.initialJobTitleFilter != null) {
      _searchController.text = widget.initialJobTitleFilter!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialJobTitleFilter != null) {
        ref.read(creatorProvider.notifier).searchCreators(widget.initialJobTitleFilter!);
      } else {
        ref.read(creatorProvider.notifier).getCreators();
      }
    });

    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // FIX 1: Safely check if the controller is attached before reading positions
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      ref.read(creatorProvider.notifier).loadNextPage();
    }
  }

  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      final searchQuery = _searchController.text.trim();
      if (searchQuery.isEmpty) {
        ref.read(creatorProvider.notifier).getCreators(page: 1);
      } else {
        ref.read(creatorProvider.notifier).searchCreators(searchQuery);
      }
    });
  }

  Future<void> _onRefresh() async {
    final searchQuery = _searchController.text.trim();
    if (searchQuery.isEmpty) {
      await ref.read(creatorProvider.notifier).getCreators(page: 1);
    } else {
      await ref.read(creatorProvider.notifier).searchCreators(searchQuery);
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
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
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Search Box
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search creators...',
                  prefixIcon: const Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
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
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Failed to load creators',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(creatorProvider.notifier).getCreators();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (creatorResponse) {
                  final creators = creatorResponse.user?.data ?? [];
                  final hasMorePages = creatorResponse.user?.nextPageUrl != null;

                  if (creators.isEmpty) {
                    // FIX 1: Removed _scrollController from this ListView to avoid dual assignment
                    return RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.search_off,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isEmpty
                                      ? 'No creators found'
                                      : 'No creators found for "${_searchController.text}"',
                                  style: const TextStyle(
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
                                    child: const Text('Clear search'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: GridView.builder(
                      controller: _scrollController,
                      // FIX 2: Only add extra slot item if there actually is a next page to load
                      itemCount: hasMorePages ? creators.length + 1 : creators.length,
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                      ),
                      itemBuilder: (context, index) {
                        // FIX 2: Show loading indicator only if we reached the extra index slot
                        if (index == creators.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
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
                                builder: (context) => CreatorProfileLoader(
                                  creatorId: creator.id,
                                ),
                              ),
                            );
                          },
                          child: Utils.buildCreativeCard(
                            context,
                            name: creator.businessName ?? '${creator.user?.firstName} ${creator.user?.lastName}',
                            role: creator.jobTitle ?? "",
                            rating: Utils.getOverallRating(creator).toStringAsFixed(1),
                            profileImage: creator.user?.image ?? '',
                            firstName: creator.businessName ?? creator.user?.firstName ?? '',
                          ),
                        );
                      },
                    ),
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