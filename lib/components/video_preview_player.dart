import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail_gen/video_thumbnail_gen.dart';

class VideoPreviewPlayer extends StatefulWidget {
  final String videoUrl;

  const VideoPreviewPlayer({super.key, required this.videoUrl});

  @override
  State<VideoPreviewPlayer> createState() => _VideoPreviewPlayerState();
}

class _VideoPreviewPlayerState extends State<VideoPreviewPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  bool _isLoading = false;
  bool _hasStartedLoading = false;
  bool _isGeneratingThumbnail = true;
  String? _thumbnailPath;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // Generates thumbnail file using video_thumbnail_gen
  Future<void> _generateThumbnail() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: widget.videoUrl,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 360,
        quality: 75,
      );

      if (!mounted) return;

      setState(() {
        _thumbnailPath = thumbnailPath;
        _isGeneratingThumbnail = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGeneratingThumbnail = false;
      });
    }
  }

  Future<void> _initializePlayer() async {
    if (_hasStartedLoading) return;

    setState(() {
      _hasStartedLoading = true;
      _isLoading = true;
      _error = null;
    });

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await controller.initialize();

      if (!mounted) {
        controller.dispose();
        return;
      }

      final chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        showControls: true,
        allowFullScreen: true,
        allowMuting: true,
        placeholder: _thumbnailPath != null
            ? Image.file(
          File(_thumbnailPath!),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        )
            : null,
        materialProgressColors: ChewieProgressColors(
          playedColor: Theme.of(context).colorScheme.primary,
          handleColor: Theme.of(context).colorScheme.primary,
          bufferedColor: Colors.grey.shade400,
          backgroundColor: Colors.grey.shade300,
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Unable to play video.',
                style: TextStyle(color: Colors.white.withOpacity(0.8)),
              ),
            ),
          );
        },
      );

      setState(() {
        _videoController = controller;
        _chewieController = chewieController;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not load video. Check your connection and try again.';
      });
    }
  }

  void _retry() {
    setState(() {
      _hasStartedLoading = false;
      _error = null;
    });
    _initializePlayer();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: Colors.black,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.white.withOpacity(0.7), size: 32),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _retry,
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_chewieController != null) {
      return Chewie(controller: _chewieController!);
    }

    // Displays extracted thumbnail image with Play overlay button
    return GestureDetector(
      onTap: _initializePlayer,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_thumbnailPath != null)
            Image.file(
              File(_thumbnailPath!),
              fit: BoxFit.cover,
            ),
          if (_isGeneratingThumbnail)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white54,
                strokeWidth: 2,
              ),
            )
          else ...[
            Container(color: Colors.black26),
            const Center(
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 56,
              ),
            ),
          ],
        ],
      ),
    );
  }
}