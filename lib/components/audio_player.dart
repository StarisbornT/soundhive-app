import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:soundhive2/utils/utils.dart';
import '../model/artist_song_model.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;

  const AudioPlayerWidget({Key? key, required this.audioUrl}) : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _player.setUrl(widget.audioUrl);

      // Listen for duration
      _player.durationStream.listen((d) {
        if (d != null) {
          setState(() => _duration = d);
        }
      });

      // Listen for position
      _player.positionStream.listen((p) {
        setState(() => _position = p);
      });

      // Listen for play/pause state
      _player.playerStateStream.listen((state) {
        setState(() => _isPlaying = state.playing);
      });
    } catch (e) {
      debugPrint("Audio init error: $e");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (_isPlaying) {
                      _player.pause();
                    } else {
                      _player.play();
                    }
                  },
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2.0,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6.0),
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: _position.inMilliseconds.toDouble().clamp(
                          0.0, _duration.inMilliseconds.toDouble()),
                      min: 0.0,
                      max: _duration.inMilliseconds.toDouble() > 0
                          ? _duration.inMilliseconds.toDouble()
                          : 1.0,
                      activeColor: Colors.white,
                      inactiveColor: Colors.white24,
                      onChanged: (value) async {
                        await _player.seek(
                            Duration(milliseconds: value.toInt()));
                      },
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_position),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Text(
                  _formatDuration(_duration),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SongDetailBottomSheet extends StatefulWidget {
  final SongItem song;
  final String status;
  final String? feedback;

  const SongDetailBottomSheet({
    super.key,
    required this.song,
    required this.status,
    this.feedback,
  });

  @override
  State<SongDetailBottomSheet> createState() => _SongDetailBottomSheetState();

  static void show({
    required BuildContext context,
    required SongItem song,
    required String status,
    String? feedback,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => SongDetailBottomSheet(
        song: song,
        status: status,
        feedback: feedback,
      ),
    );
  }
}

class _SongDetailBottomSheetState extends State<SongDetailBottomSheet> {
  late AudioPlayer _player;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _player.setUrl(widget.song.songAudio);
      _player.playerStateStream.listen((state) {
        if (mounted) setState(() {});
      });
      _player.durationStream.listen((d) {
        if (d != null && mounted) setState(() => _duration = d);
      });
      _player.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
    } catch (e) {
      debugPrint('Error loading audio: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _player.playing;
    final formattedDate = DateFormat('dd/MM/yyyy')
        .format(DateTime.parse(widget.song.createdAt));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${widget.status} $formattedDate',
            style: const TextStyle(
              color: Color(0xFFB0B0B6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  widget.song.coverPhoto,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.grey, width: 60, height: 60),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.song.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.song.artist?.userName!.capitalize() ?? '',
                      style: const TextStyle(
                        color: Color(0xFFB0B0B6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause_circle : Icons.play_circle,
                  color: Colors.white,
                  size: 36,
                ),
                onPressed: () async {
                  if (isPlaying) {
                    await _player.pause();
                  } else {
                    await _player.play();
                  }
                  setState(() {});
                },
              ),
              Expanded(
                child: ProgressBar(
                  progress: _position,
                  total: _duration,
                  onSeek: _player.seek,
                  progressBarColor: const Color(0xFF8C52FF),
                  baseBarColor: Colors.white24,
                  thumbColor: Colors.white,
                  timeLabelTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (widget.feedback != null && widget.feedback!.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Feedback',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.feedback!,
              style: const TextStyle(
                color: Color(0xFFB0B0B6),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}



