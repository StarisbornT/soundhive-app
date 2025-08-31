import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/model/user_model.dart';

import 'package:soundhive2/lib/dashboard_provider/categoryProvider.dart';
import '../../../model/category_model.dart';
import '../../../utils/app_colors.dart';
import 'service_list_screen.dart';

class Categories extends ConsumerStatefulWidget {
  final MemberCreatorResponse user;
  const Categories({super.key, required this.user});

  @override
  _CategoriesState createState() => _CategoriesState();
}

class _CategoriesState extends ConsumerState<Categories> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(categoryProvider.notifier).getCategory();
    });

    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      // Reset search if query is empty
      if (_isSearching) {
        _isSearching = false;
        ref.read(categoryProvider.notifier).resetSearch();
        ref.read(categoryProvider.notifier).getCategory();
      }
      return;
    }

    // Debounce search to avoid too many API calls
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text.trim() == query) {
        _isSearching = true;
        ref.read(categoryProvider.notifier).searchCategories(query);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // Load more data when scrolled to bottom
      ref.read(categoryProvider.notifier).loadMore();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _isSearching = false;
    ref.read(categoryProvider.notifier).resetSearch();
    ref.read(categoryProvider.notifier).getCategory();
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryProvider);

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
              'Service Categories',
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
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Search by category name',
                        hintStyle: TextStyle(color: Colors.white38),
                        prefixIcon: Icon(Icons.search, color: Colors.white38),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white38),
                      onPressed: _clearSearch,
                    ),
                ],
              ),
            ),

            // Loading, Error or Categories
            Expanded(
              child: categoryState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Text(
                    'Error loading categories: $error',
                    style: const TextStyle(color: Colors.white60),
                  ),
                ),
                data: (categoryResponse) {
                  final categories = categoryResponse.data.data;
                  final hasMore = categoryResponse.data.nextPageUrl != null;

                  if (categories.isEmpty) {
                    return Center(
                      child: Text(
                        _isSearching
                            ? 'No categories found for "${_searchController.text}"'
                            : 'No categories found.',
                        style: const TextStyle(color: Colors.white60),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: categories.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == categories.length) {
                        // Show loading indicator at the bottom for pagination
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final category = categories[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ServicesListScreen(
                                  id: category.id,
                                  user: widget.user,
                                    categoryName: category.name
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white12),
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              category.name,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
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