import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

import 'agora_token_provider.dart';

class AudioCallState {
  final bool isInCall;
  final bool isMuted;
  final bool isSpeakerOn;
  final CallStatus status;
  final int? remoteUid;
  final String callDuration; // Add this

  AudioCallState({
    this.isInCall = false,
    this.isMuted = false,
    this.isSpeakerOn = true,
    this.status = CallStatus.idle,
    this.remoteUid,
    this.callDuration = '00:00', // Add default
  });

  AudioCallState copyWith({
    bool? isInCall,
    bool? isMuted,
    bool? isSpeakerOn,
    CallStatus? status,
    int? remoteUid,
    String? callDuration, // Add this
  }) {
    return AudioCallState(
      isInCall: isInCall ?? this.isInCall,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      status: status ?? this.status,
      remoteUid: remoteUid ?? this.remoteUid,
      callDuration: callDuration ?? this.callDuration, // Add this
    );
  }
}

enum CallStatus {
  idle,
  calling,
  ringing,
  connected,
  ended,
  failed
}

class AudioCallNotifier extends StateNotifier<AudioCallState> {
  final Ref ref;

  // Agora SDK - Use RtcEngine instead of RtcEngineEx
  late RtcEngine _agoraEngine;
  bool _isEngineInitialized = false;

  // Call management
  String? _currentChannel;
  Timer? _callTimer;
  int _callDurationSeconds = 0;
  int? _localUid;

  AudioCallNotifier(this.ref) : super(AudioCallState());

  // Initialize Agora engine
  Future<void> initializeAgora() async {
    if (_isEngineInitialized) return;

    try {
      // Request microphone permission
      await [Permission.microphone].request();

      // Create Agora engine - this returns RtcEngine
      _agoraEngine = createAgoraRtcEngine();
      await _agoraEngine.initialize(RtcEngineContext(
        appId: dotenv.env['AGORA_APP_ID'],
      ));

      await _agoraEngine.setAudioProfile(
        profile: AudioProfileType.audioProfileDefault,
        scenario: AudioScenarioType.audioScenarioDefault,
      );

      await _agoraEngine.enableAudio();
      await _agoraEngine.setEnableSpeakerphone(true);

      // Register event handlers
      _agoraEngine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint("Local user joined channel: ${connection.channelId}");
            state = state.copyWith(
              status: CallStatus.connected,
              isInCall: true,
            );
            _startCallTimer();
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint("Remote user joined: $remoteUid");
            state = state.copyWith(remoteUid: remoteUid);
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            debugPrint("Remote user offline: $remoteUid");
            _endCall();
          },
          onError: (ErrorCodeType errorCode, String message) {
            debugPrint("Agora error: $message");
            state = state.copyWith(status: CallStatus.failed);
          },
        ),
      );
      _isEngineInitialized = true;
    } catch (e) {
      debugPrint("Failed to initialize Agora: $e");
      state = state.copyWith(status: CallStatus.failed);
    }
  }

  // Get Agora token using your existing pattern
  Future<String> _getToken(String channelName, int uid) async {
    try {
      final tokenNotifier = ref.read(agoraTokenProvider.notifier);
      final token = await tokenNotifier.generateToken(
        AgoraTokenRequest(
          channelName: channelName,
          uid: uid,
          expireTime: 3600, // 1 hour
        ),
      );

      if (token.isEmpty) {
        debugPrint("Warning: Using empty token - only for testing mode");
      }

      return token;
    } catch (e) {
      debugPrint("Error getting Agora token: $e");
      // For development/testing, you can return empty string
      // In production, you should handle this error appropriately
      return "";
    }
  }

  // Start an audio call
  // Start an audio call
  Future<void> startCall(String channelName, int localUid) async {
    if (!_isEngineInitialized) {
      await initializeAgora();
    }

    try {
      state = state.copyWith(
        status: CallStatus.calling,
        callDuration: '00:00',
      );
      _localUid = localUid;
      _currentChannel = channelName;
      _callDurationSeconds = 0;

      // Get token for the channel
      final token = await _getToken(channelName, localUid);

      // Set channel profile and join channel
      await _agoraEngine.setChannelProfile(ChannelProfileType.channelProfileCommunication);

      // Set client role
      await _agoraEngine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      await _agoraEngine.joinChannel(
        token: token,
        channelId: channelName,
        uid: localUid,
        options: const ChannelMediaOptions(
          autoSubscribeAudio: true,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

    } catch (e) {
      debugPrint("Failed to start call: $e");
      state = state.copyWith(status: CallStatus.failed);
      rethrow;
    }
  }

  // Join an ongoing call (for receiver)
  Future<void> joinCall(String channelName, int localUid) async {
    if (!_isEngineInitialized) {
      await initializeAgora();
    }

    try {
      state = state.copyWith(status: CallStatus.ringing);
      _currentChannel = channelName;

      // Get token for the channel using your provider pattern
      final token = await _getToken(channelName, localUid);

      await _agoraEngine.setChannelProfile(ChannelProfileType.channelProfileCommunication);

      await _agoraEngine.joinChannel(
        token: token,
        channelId: channelName,
        uid: localUid,
        options: const ChannelMediaOptions(
          autoSubscribeAudio: true,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

    } catch (e) {
      debugPrint("Failed to join call: $e");
      state = state.copyWith(status: CallStatus.failed);
      rethrow;
    }
  }

  // End the current call
  Future<void> endCall() async {
    _endCall();
  }

  void _endCall() {
    _callTimer?.cancel();
    _callDurationSeconds = 0;

    if (_isEngineInitialized && _currentChannel != null) {
      try {
        // First leave the channel
        _agoraEngine.leaveChannel();

        // Then destroy the engine to completely stop audio
        _agoraEngine.release();
        _isEngineInitialized = false;

      } catch (e) {
        print('Error ending call: $e');
      }
    }

    // Clear the token when call ends
    ref.read(agoraTokenProvider.notifier).clearToken();

    state = AudioCallState(); // Reset to initial state
    _currentChannel = null;
  }

  // Toggle mute
  Future<void> toggleMute() async {
    if (!_isEngineInitialized) return;

    try {
      await _agoraEngine.muteLocalAudioStream(!state.isMuted);
      state = state.copyWith(isMuted: !state.isMuted);
    } catch (e) {
      debugPrint("Failed to toggle mute: $e");
    }
  }

  // Toggle speaker
  Future<void> toggleSpeaker() async {
    if (!_isEngineInitialized) return;

    try {
      await _agoraEngine.setEnableSpeakerphone(!state.isSpeakerOn);
      state = state.copyWith(isSpeakerOn: !state.isSpeakerOn);
    } catch (e) {
      debugPrint("Failed to toggle speaker: $e");
    }
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callDurationSeconds++;
      final minutes = (_callDurationSeconds ~/ 60).toString().padLeft(2, '0');
      final seconds = (_callDurationSeconds % 60).toString().padLeft(2, '0');

      // Update state with new duration
      state = state.copyWith(callDuration: '$minutes:$seconds');
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    if (_isEngineInitialized) {
      _agoraEngine.release();
    }
    super.dispose();
  }
}

// Provider - remains the same
final audioCallProvider = StateNotifierProvider<AudioCallNotifier, AudioCallState>(
      (ref) => AudioCallNotifier(ref),
);

class CallUser {
  final String id;
  final String name;
  final String service;
  final String? avatarUrl;

  CallUser({
    required this.id,
    required this.name,
    required this.service,
    this.avatarUrl,
  });
}
