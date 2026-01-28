import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/lib/dashboard_provider/categoryProvider.dart';
import 'package:soundhive2/lib/dashboard_provider/getMarketPlaceService.dart';
import 'package:soundhive2/lib/dashboard_provider/sub_category_provider.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import 'package:soundhive2/lib/navigator_provider.dart';
import '../../../model/category_model.dart';
import '../../../model/sub_categories.dart';
import 'service_list_screen.dart';

class Categories extends ConsumerStatefulWidget {
  const Categories({super.key});

  @override
  ConsumerState<Categories> createState() => _CategoriesState();
}


class _CategoriesState extends ConsumerState<Categories> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;
  int? _selectedCategoryId;
  String? _selectedCategoryName;

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
      if (_isSearching) {
        _isSearching = false;
        ref.read(categoryProvider.notifier).resetSearch();
        ref.read(categoryProvider.notifier).getCategory();
      }
      return;
    }

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
      ref.read(categoryProvider.notifier).loadMore();
    }
  }

  // void _clearSearch() {
  //   _searchController.clear();
  //   _isSearching = false;
  //   ref.read(categoryProvider.notifier).resetSearch();
  //   ref.read(categoryProvider.notifier).getCategory();
  // }

  void _loadSubcategories(int categoryId, String categoryName) {
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedCategoryName = categoryName;
    });
    ref.read(subcategoryProvider.notifier).getSubCategory(categoryId);
  }

  void _clearSubcategories() {
    setState(() {
      _selectedCategoryId = null;
      _selectedCategoryName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryProvider);
    final subcategoryState = ref.watch(subcategoryProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
       
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              if (_selectedCategoryId != null) {
                // 🔙 If currently in subcategory view, go back to categories
                _clearSubcategories();
              } else {
                // 🔙 Otherwise, go back to the Hive/Home section
                ref.read(getMarketplaceServiceProvider.notifier).resetMarketplaceState();
                Navigator.pop(context);
                ref.read(bottomNavigationProvider.notifier).state = 0;
              }
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Explore Hives/Service Categories",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),

              // Search Box
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: "Search",
                    // hintStyle: TextStyle(color: Colors.white54),
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Expanded( child: _selectedCategoryId == null ? _buildCategoriesList(categoryState) : _buildSubcategoriesList(subcategoryState)),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildCategoriesList(AsyncValue<CategoryResponse> categoryState) {
    return categoryState.when(
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
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          itemCount: categories.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == categories.length) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final category = categories[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(width: 1),
              ),
              child: InkWell(
                onTap: () => _loadSubcategories(category.id, category.name),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (category.description != null &&
                          category.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            category.description!,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "No of creators: ${category.creatorCount}",
                            style: const TextStyle(
                              color: Color(0xFFD6ABFE),
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            "No of services: ${category.servicesCount}",
                            style: const TextStyle(
                              color: Color(0xFFD6ABFE),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubcategoriesList(AsyncValue<SubCategories> subcategoryState) {
    final user = ref.watch(userProvider).value;
    return subcategoryState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text(
          'Error loading subcategories: $error',
          style: const TextStyle(color: Colors.white60),
        ),
      ),
      data: (subcategoryResponse) {
        final subcategories = subcategoryResponse.data;

        return Column(
          children: [
            // "All Services in Category" option
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServicesListScreen(
                        id: _selectedCategoryId!,
                        subCategoryId: null,
                        user: user!,
                        categoryName: 'All Services in $_selectedCategoryName',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A0DAD),
                  // foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white12),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child:  Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'All Services in $_selectedCategoryName',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            // Subcategories list
            Expanded(
              child: subcategories.isEmpty
                  ? const Center(
                child: Text(
                  'No Service Clusters found.',
                  style: TextStyle(color: Colors.white60),
                ),
              )
                  : ListView.builder(
                itemCount: subcategories.length,
                itemBuilder: (context, index) {
                  final subcategory = subcategories[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ServicesListScreen(
                              id: _selectedCategoryId!,
                              subCategoryId: subcategory.id,
                              user: user!,
                              categoryName: subcategory.name,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        // foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white12),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          subcategory.name,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}