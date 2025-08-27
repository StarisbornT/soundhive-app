
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/screens/non_creator/marketplace/creator.dart';

import '../../../model/creator_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/utils.dart';

class CreatorsList extends ConsumerStatefulWidget {
  final List<CreatorData> creator;
  const CreatorsList({Key? key, required this.creator}) : super(key: key);

  @override
  _CreatorsListState createState() => _CreatorsListState();
}

class _CreatorsListState extends ConsumerState<CreatorsList> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredCreators = []; // State variable for filtered list

  @override
  void initState() {
    super.initState();
    _filteredCreators = widget.creator; // Initialize with all creators

    _searchController.addListener(_filterCreators); // Listen to search
  }

  void _filterCreators() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredCreators = widget.creator.where((c) {
        final firstName = c.user?.firstName.toLowerCase() ?? '';
        final lastName = c.user?.lastName.toLowerCase() ?? '';
        final jobTitle = c.jobTitle.toLowerCase() ?? '';

        return firstName.contains(query) ||
            lastName.contains(query) ||
            jobTitle.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                decoration: const InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(color: Colors.white38),
                  prefixIcon: Icon(Icons.search, color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),

            // Creator List
            Expanded(
              child: _filteredCreators.isEmpty
                  ? const Center(
                child: Text(
                  'No Creator found.',
                  style: TextStyle(color: Colors.white60),
                ),
              )
                  : GridView.builder(
                itemCount: _filteredCreators.length,
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final creators = _filteredCreators[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreatorProfile(
                            creator: creators,
                          ),
                        ),
                      );
                    },
                    child: Utils.buildCreativeCard(
                      context,
                      name: '${creators.user?.firstName} ${creators.user?.lastName}',
                      role: creators.jobTitle ?? '',
                      rating: 4.8,
                      profileImage: creators.user?.image ?? '',
                      firstName: creators.user!.firstName,
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
