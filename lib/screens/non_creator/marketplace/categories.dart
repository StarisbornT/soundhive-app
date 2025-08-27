import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/model/user_model.dart';

import 'package:soundhive2/lib/dashboard_provider/categoryProvider.dart';
import '../../../model/category_model.dart';
import '../../../utils/app_colors.dart';
import 'service_list_screen.dart';

class Categories extends ConsumerStatefulWidget {
  final MemberCreatorResponse user;
  const Categories({Key? key, required this.user}) : super(key: key);

  @override
  _CategoriesState createState() => _CategoriesState();
}

class _CategoriesState extends ConsumerState<Categories> {
  final TextEditingController _searchController = TextEditingController();

  List<Category> _allCategories = [];
  List<Category> _filteredCategories = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(categoryProvider.notifier).getCategory();
      final fetched = ref.read(categoryProvider).value?.data.data;
      setState(() {
        _allCategories = fetched!;
        _filteredCategories = fetched;
      });
    });
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCategories = _allCategories
          .where((category) => category.name.toLowerCase().contains(query))
          .toList();
    });
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
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search for a category',
                  hintStyle: TextStyle(color: Colors.white38),
                  prefixIcon: Icon(Icons.search, color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),

            // Loading, Error or Categories
            Expanded(
              child: categoryState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredCategories.isEmpty
                  ? const Center(
                child: Text(
                  'No categories found.',
                  style: TextStyle(color: Colors.white60),
                ),
              )
                  : ListView.builder(
                itemCount: _filteredCategories.length,
                itemBuilder: (context, index) {
                  final category = _filteredCategories[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ServicesListScreen(
                              categoryName: category.name,
                              user: widget.user,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        side:
                        const BorderSide(color: Colors.white12),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

