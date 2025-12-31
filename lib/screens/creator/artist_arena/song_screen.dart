import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/screens/creator/artist_arena/add_songs.dart';
import '../../../components/audio_player.dart';
import '../../../components/success.dart';
import '../../../components/widgets.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/lib/dashboard_provider/artist_song_provider.dart';
import '../../../model/apiresponse_model.dart';
import '../../../model/artist_song_model.dart';
import '../../../utils/alert_helper.dart';
import '../../../utils/utils.dart';

class SongScreen extends ConsumerStatefulWidget {
  const SongScreen({super.key});
  @override
  ConsumerState<SongScreen> createState() => _SongScreenState();
}

class _SongScreenState extends ConsumerState<SongScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshData();
    });
  }

  Future<void> _refreshData() async {
    ref.invalidate(artistSongProvider('published'));
    ref.invalidate(artistSongProvider('pending'));
    ref.invalidate(artistSongProvider('rejected'));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
     
      appBar: AppBar(
       
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFB0B0B6)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshData,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15.0),
                  child: Text(
                    'My Songs',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                     
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF917FC0),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
                  tabs: const [
                    Tab(text: 'Published'),
                    Tab(text: 'Under review'),
                    Tab(text: 'Rejected'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      Consumer(
                        builder: (context, ref, _) {
                          final publishedState = ref.watch(artistSongProvider('published'));
                          return publishedState.when(
                            data: (serviceResponse) =>
                                buildServiceList(serviceResponse.data.data, "No published songs"),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (error, _) => Center(child: Text('Error: $error')),
                          );
                        },
                      ),
                      Consumer(
                        builder: (context, ref, _) {
                          final pendingState = ref.watch(artistSongProvider('pending'));
                          return pendingState.when(
                            data: (serviceResponse) =>
                                buildServiceList(serviceResponse.data.data, "No songs under review"),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (error, _) => Center(child: Text('Error: $error')),
                          );
                        },
                      ),
                      Consumer(
                        builder: (context, ref, _) {
                          final rejectedState = ref.watch(artistSongProvider('rejected'));
                          return rejectedState.when(
                            data: (serviceResponse) =>
                                buildServiceList(serviceResponse.data.data, "No rejected songs"),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (error, _) => Center(child: Text('Error: $error')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 70,
        height: 70,
        child: RawMaterialButton(
          onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSongScreen()));
          },
          fillColor: const Color(0xFF8C52FF),
          shape: const CircleBorder(),
          elevation: 6,
          child: const Icon(
            Icons.add,
            color: Colors.white,
           
            size: 36,
          ),
        ),
      ),
    );
  }

  Widget buildServiceList(List<SongItem> items, String emptyMessage) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
        ),
      );
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () {
            SongDetailBottomSheet.show(
              context: context,
              song: item,
              status: item.status,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: (item.coverPhoto.isNotEmpty)
                      ? Image.network(
                    item.coverPhoto,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Utils.buildImagePlaceholder(),
                  )
                      : Utils.buildImagePlaceholder(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                           
                            fontSize: 16,
                            fontWeight: FontWeight.bold
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.status == "PENDING" ? 'Submitted ${DateFormat('dd/MM/yyyy').format(DateTime.parse(item.createdAt))}' : '',
                        style: const TextStyle( fontSize: 12, fontWeight: FontWeight.w500),
                      ),

                    ],
                  ),
                ),
                GestureDetector(
                    onTap: () {
                      ConfirmBottomSheet.show(
                        context: context,
                        message: "Are you sure you want to delete this service?",
                        confirmText: "Delete",
                        cancelText: "Cancel",
                        confirmColor: const Color(0xFFFE6163),
                        onConfirm: () {
                          deleteService(item);
                        },
                      );
                    },
                    child: const Icon(Icons.delete, color: Colors.red,)
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void deleteService(item) async {

    try {
      final response =  await ref.read(apiresponseProvider.notifier).deleteSong(
        context: context,
        songId: item.id,
      );

      if(response.status) {
        ref.watch(artistSongProvider('published'));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Success(
              title: 'Your service is deleted successfully',
              subtitle: 'Your service is deleted successfully',
              onButtonPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        );
      }

    } catch (error) {
      String errorMessage = 'An unexpected error occurred';

      if (error is DioException) {
        if (error.response?.data != null) {
          try {
            final apiResponse = ApiResponseModel.fromJson(error.response?.data);
            errorMessage = apiResponse.message;
          } catch (e) {
            errorMessage = 'Failed to parse error message';
          }
        } else {
          errorMessage = error.message ?? 'Network error occurred';
        }
      }

      print("Error: $errorMessage");
      if(mounted) {
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: errorMessage,
        );
      }

    }
  }
}
