import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soundhive2/components/label_text.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/screens/creator/artist_arena/artist_profile_screen.dart';
import 'package:soundhive2/utils/app_colors.dart';
import '../../../components/image_picker.dart';
import '../../../components/success.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import 'package:soundhive2/lib/dashboard_provider/get_featured_artists_provider.dart';
import '../../../components/widgets.dart';
import '../../../model/apiresponse_model.dart';
import '../../../services/loader_service.dart';
import '../../../utils/alert_helper.dart';

class AddSongScreen extends ConsumerStatefulWidget {
  const AddSongScreen({super.key});

  @override
  _AddSongScreenState createState() => _AddSongScreenState();
}

class _AddSongScreenState extends ConsumerState<AddSongScreen> {
  late TextEditingController songTitleController;
  late TextEditingController songDescriptionController;
  late TextEditingController songTypeController;

  final ValueNotifier<File?> _audioFileNotifier = ValueNotifier<File?>(null);
  final ValueNotifier<File?> _coverPhotoNotifier = ValueNotifier<File?>(null);
  double _uploadProgress = 0.0;
  bool _isUploadingAudio = false;


  String? _uploadedAudioUrl;
  String? _uploadedCoverUrl;

  final List<Map<String, String>> songTypes = [
    {'label': 'Gospel', 'value': 'gospel'},
    {'label': 'Jazz', 'value': 'jazz'},
    {'label': 'Hip-Pop', 'value': 'hip_pop'},
    {'label': 'Pop', 'value': 'pop'},
    {'label': 'Reggae', 'value': 'reggae'},
    {'label': 'Afro', 'value': 'afro'},
    {'label': 'Metal', 'value': 'metal'},
  ];
  String? selectedSongType;
  List<String> selectedFeaturedArtists = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(getFeaturedArtistProvider.notifier).getArtists();
    });
    songTitleController = TextEditingController();
    songDescriptionController = TextEditingController();
    songTypeController = TextEditingController();
  }

  @override
  void dispose() {
    songTitleController.dispose();
    songDescriptionController.dispose();
    songTypeController.dispose();
    super.dispose();
  }

  /// Upload both audio & cover photos
  Future<void> _uploadMediaToCloudinary() async {
    final audioFile = _audioFileNotifier.value;
    final coverFile = _coverPhotoNotifier.value;

    if (audioFile == null) {
      throw Exception('Audio file is required');
    }

    // Upload audio file
    final audioUrl = await _uploadFileToCloudinary(
      file: audioFile,
      resourceType: 'video',
      preset: 'soundhive',
    );

    // Upload cover photo if provided
    String? coverUrl;
    if (coverFile != null) {
      coverUrl = await _uploadFileToCloudinary(
        file: coverFile,
        resourceType: 'image',
        preset: 'soundhive',
      );
    }

    _uploadedAudioUrl = audioUrl;
    _uploadedCoverUrl = coverUrl;
  }

  /// Upload a single file to Cloudinary
  Future<String> _uploadFileToCloudinary({
    required File file,
    required String resourceType,
    required String preset,
  }) async {
    setState(() {
      if (resourceType == 'video') {
        _isUploadingAudio = true;
        _uploadProgress = 0.0;
      }
    });

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
      'upload_preset': preset,
    });

    final response = await Dio().post(
      'https://api.cloudinary.com/v1_1/djutcezwz/$resourceType/upload',
      data: formData,
      onSendProgress: (count, total) {
        if (resourceType == 'video') {
          setState(() {
            _uploadProgress = count / total;
          });
        }
      },
    );

    setState(() {
      if (resourceType == 'video') {
        _isUploadingAudio = false;
      }
    });

    if (response.statusCode != 200) {
      throw Exception('$resourceType upload failed');
    }

    return response.data['secure_url'] as String;
  }


  /// Check if the path is valid and local
  Future<bool> _isValidLocalPath(String path) async {
    final tempDir = await getTemporaryDirectory();
    final tempPath = tempDir.path;

    return path.startsWith(tempPath) ||
        path.startsWith('/data') ||
        path.startsWith('file://') ||
        path.startsWith('content://');
  }

  /// Submit form to backend
  void _submitForm() async {
    print('🔄 Starting song submission');

    if (songTitleController.text.trim().isEmpty) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Missing Field',
        message: 'Please enter song title',
      );
      return;
    }

    if (selectedSongType == null) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Missing Field',
        message: 'Please select song type',
      );
      return;
    }

    if (_audioFileNotifier.value == null) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Missing Field',
        message: 'Please upload audio file',
      );
      return;
    }

    try {
      LoaderService.showLoader(context);

      final audioFile = _audioFileNotifier.value!;

      bool isAudioValid = await _isValidLocalPath(audioFile.path);

      if (!await audioFile.exists() || !isAudioValid) {
        throw Exception('Invalid or missing audio file');
      }

      await _uploadMediaToCloudinary();

      await _submitSongToBackend();

      LoaderService.hideLoader(context);
      final user = await ref.read(userProvider.notifier).loadUserProfile();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Success(
            title: 'Your song has been uploaded successfully!',
            subtitle: 'Your song is under review and will be published soon.',
            onButtonPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ArtistProfileScreen(user: user!)),
              );
            },
          ),
        ),
      );
    } catch (error) {
      LoaderService.hideLoader(context);
      String errorMessage = 'An unexpected error occurred';
      print('FULL ERROR DETAILS: $error');

      if (error is DioException) {
        if (error.response?.data != null) {
          try {
            final apiResponse = ApiResponseModel.fromJson(error.response?.data);
            errorMessage = apiResponse.message;
          } catch (_) {
            errorMessage = 'Failed to parse error message';
          }
        } else {
          errorMessage = error.message ?? 'Network error occurred';
        }
      }

      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: errorMessage,
      );
    } finally {
      LoaderService.hideLoader(context);
    }
  }


  Future<void> _pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      PlatformFile file = result.files.first;
      _audioFileNotifier.value = File(file.path!);
    }
  }

  /// Send final payload to backend for song upload
  Future<ApiResponseModel> _submitSongToBackend() async {
    final payload = {
      "title": songTitleController.text.trim(),
      "type": selectedSongType,
      "song_audio": _uploadedAudioUrl,
      if (_uploadedCoverUrl != null) "cover_photo": _uploadedCoverUrl,
      if (selectedFeaturedArtists.isNotEmpty) "featured_artists": selectedFeaturedArtists,
    };

    final response = await ref.read(apiresponseProvider.notifier).uploadSong(
      context: context,
      payload: payload,
    );

    if (!response.status) {
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          data: {'message': response.message},
        ),
      );
    }

    return response;
  }

  @override
  Widget build(BuildContext context) {
    final artistsAsync = ref.watch(getFeaturedArtistProvider);

    return Scaffold(
      backgroundColor: AppColors.BACKGROUNDCOLOR,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xFFB0B0B6),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Add new song',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Note that all added songs will be reviewed by Soundhive before it is published.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 40),

                      /// --- Song Title ---
                      LabeledTextField(
                        label: 'Title of Song',
                        controller: songTitleController,
                        hintText: 'E.g. Feel',
                      ),
                      const SizedBox(height: 10),

                      /// --- Song Type ---
                      LabeledSelectField(
                        label: "Type of Song",
                        items: songTypes,
                        hintText: 'E.g. Afrobeats',
                        onChanged: (value) {
                          selectedSongType = value;
                        }, controller: songTypeController,
                      ),
                      const SizedBox(height: 10),

                      /// --- Upload Audio File ---
                      FileUploadField(
                        label: 'Upload Song',
                        uploadText: _audioFileNotifier.value != null
                            ? 'Audio Selected'
                            : _uploadedAudioUrl != null
                            ? 'Existing Audio (click to replace)'
                            : 'Upload Audio',
                        supportedFileTypes: 'Supported file types: mp3, ogg, wav',
                        maxFileSize: 'Max file size: 10MB',
                        uploadIcon: Icons.upload_file_outlined,
                        onTap: _pickAudioFile,
                        fileName: _audioFileNotifier.value?.path.split('/').last,
                        isUploading: _isUploadingAudio,
                        progress: _uploadProgress,
                      ),
                      const SizedBox(height: 10),

                      /// --- Upload Cover Photo ---
                      ImagePickerComponent(
                        labelText: 'Upload Song Cover Photo',
                        imageNotifier: _coverPhotoNotifier,
                        hintText: 'Upload song cover photo',
                      ),
                      const SizedBox(height: 20),

                      /// --- Featured Artists Dropdown ---
                      artistsAsync.when(
                        data: (artistsModel) {
                          final featuredArtists = artistsModel.data.data
                              .map((artist) => {
                            'value': artist.id.toString(),
                            'label': artist.username,
                          })
                              .toList();

                          return LabeledMultiSelectField(
                              label: "Add Featured Artist (Optional)",
                              items: featuredArtists,
                              hintText: 'Select Featured Artists',
                              selectedValues: selectedFeaturedArtists,
                              onChanged: (values) {
                                setState(() {
                                  selectedFeaturedArtists = values;
                                });
                              }
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (err, stack) => Text(
                          'Failed to load artists: $err',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),

                /// --- Fixed Submit Button ---
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: RoundedButton(
                    title: 'Upload Song',
                    onPressed: _submitForm,
                    color: AppColors.PRIMARYCOLOR,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

