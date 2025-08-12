import 'dart:nativewrappers/_internal/vm/lib/ffi_allocation_patch.dart';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'package:uuid/uuid.dart';

import '../main.dart';
import 'call_end_screen.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({super.key});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  static const String apiKey = 'mmhfdzb5evj2';
  static const String userId = 'test-user-1';
  static const String token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoidGVzdC11c2VyLTEifQ.P5_9gKdPjczTJYBFWLEXI8h6XVFZ4IyN4QfczJ_XY8M';  // Test token
  static const String callId = 'test-room';

  StreamVideo? streamVideo;
  Call? call;
  bool isConnecting = true;
  bool isCallActive = false;
  String? errorMessage;
  bool isCameraOn = true;
  bool isMicOn = true;

  @override
  void initState() {
    super.initState();
    _initializeVideoCall();
  }

  Future<void> _initializeVideoCall() async {
    try {
      await _requestPermissions();

      final user = User(
        info: UserInfo(
          id: userId,
          name: 'Test User ${const Uuid().v4().substring(0, 4)}',
        ),
      );

      streamVideo = StreamVideo(
        apiKey,
        user: user,
        userToken: token,
      );

      call = streamVideo?.call();

      if (call != null) {
        await call!.getOrCreate();
        await call!.join();

        setState(() {
          isConnecting = false;
          isCallActive = true;
        });
      }

    } catch (e) {
      setState(() {
        isConnecting = false;
        errorMessage = 'Failed to join call: ${e.toString()}';
      });
      print('Error: $e');
    }
  }

  Future<void> _requestPermissions() async {
    final permissions = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    permissions.forEach((permission, status) {
      print('$permission: $status');
    });
  }

  Future<void> _toggleCamera() async {
    if (call != null) {
      try {
        if (isCameraOn) {
          await call!.setCameraEnabled(enabled: false);
        } else {
          await call!.setCameraEnabled(enabled: true);
        }
        setState(() {
          isCameraOn = !isCameraOn;
        });
      } catch (e) {
        print('Camera toggle error: $e');
      }
    }
  }

  Future<void> _toggleMicrophone() async {
    if (call != null) {
      try {
        if (isMicOn) {
          await call!.setMicrophoneEnabled(enabled: false);
        } else {
          await call!.setMicrophoneEnabled(enabled: true);
        }
        setState(() {
          isMicOn = !isMicOn;
        });
      } catch (e) {
        print('Microphone toggle error: $e');
      }
    }
  }

  Future<void> _endCall() async {
    try {
      if (call != null) {
        await call!.leave();
      }
      setState(() {
        isCallActive = false;
      });

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const CallEndedScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error ending call: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    if (isCallActive && call != null) {
      call!.leave();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isConnecting) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Connecting to Test Room...',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 10),
              Text(
                'Make sure to allow camera and microphone permissions',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 64),
                const SizedBox(height: 20),
                const Text(
                  'Connection Error',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          errorMessage = null;
                          isConnecting = true;
                        });
                        _initializeVideoCall();
                      },
                      child: const Text('Retry'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          errorMessage = null;
                        });
                      },
                      child: const Text('Continue Anyway'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Room - Video Call'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: isCallActive ? Colors.green : Colors.orange,
            child: Text(
              isCallActive
                  ? '🟢 Connected to Test Room'
                  : '🟠 Setting up connection...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: call != null
                  ? StreamCallContainer(
                call: call!,
                // <-- use callContentBuilder in v0.4.4
                callContentBuilder: (
                    BuildContext context,
                    Call call,
                    CallState? callState,
                    ) {
                  // show loading if callState not ready yet
                  if (callState == null) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  final participants = callState.callParticipants;

                  if (participants.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people,
                            size: 64,
                            color: Colors.white54,
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Waiting for other participants...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Share this room with others to start the call!',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: participants.length == 1 ? 1 : 2,
                      childAspectRatio: 16 / 9,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: participants.length,
                    itemBuilder: (context, index) {
                      final participant = participants[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: participant.isLocal ? Colors.blue : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              // Video renderer
                              Positioned.fill(
                                child: StreamVideoRenderer(
                                  call: call,
                                  participant: participant,
                                  videoTrackType: SfuTrackType.video,
                                ),
                              ),

                              // Participant name
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    participant.isLocal
                                        ? 'You'
                                        : (participant.name ??
                                        'Participant ${index + 1}'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              // Muted indicator
                              if (!participant.isAudioEnabled)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.mic_off,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              )
                  : const Center(
                child: Text(
                  'Initializing video call...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Camera button
                FloatingActionButton(
                  heroTag: "camera",
                  onPressed: _toggleCamera,
                  backgroundColor: isCameraOn ? Colors.blue : Colors.red,
                  child: Icon(
                    isCameraOn ? Icons.videocam : Icons.videocam_off,
                    color: Colors.white,
                  ),
                ),

                // Microphone button
                FloatingActionButton(
                  heroTag: "mic",
                  onPressed: _toggleMicrophone,
                  backgroundColor: isMicOn ? Colors.green : Colors.red,
                  child: Icon(
                    isMicOn ? Icons.mic : Icons.mic_off,
                    color: Colors.white,
                  ),
                ),

                // End call button
                FloatingActionButton(
                  heroTag: "end",
                  onPressed: _endCall,
                  backgroundColor: Colors.red,
                  child: const Icon(
                    Icons.call_end,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}