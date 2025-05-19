import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'config.dart';

class VideoCall extends StatefulWidget {
  const VideoCall({super.key});

  @override
  State<VideoCall> createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> {
  late final RtcEngine _engine;
  bool _isJoined = false;
  int? _localUid;
  final List<int> _remoteUids = [];

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  @override
  void dispose() {
    _leaveChannel();
    super.dispose();
  }

  Future<void> _initAgora() async {
    // 1. Request permissions
    await [
      Permission.camera,
      Permission.microphone,
    ].request(); // :contentReference[oaicite:5]{index=5}

    // 2. Create and initialize engine
    _engine = createAgoraRtcEngine(); // :contentReference[oaicite:6]{index=6}
    await _engine.initialize(
      RtcEngineContext(appId: Config.appId),
    ); // :contentReference[oaicite:7]{index=7}

    // 3. Enable video module
    await _engine.enableVideo(); // :contentReference[oaicite:8]{index=8}

    // 4. Register event handlers
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() {
            _isJoined = true;
            _localUid = connection.localUid;
          });
        },
        onUserJoined: (connection, uid, elapsed) {
          setState(() {
            _remoteUids.add(uid);
          });
        },
        onUserOffline: (connection, uid, reason) {
          setState(() {
            _remoteUids.remove(uid);
          });
        },
      ),
    );

    // 5. Join channel
    await _engine.joinChannel(
      token: Config.token,
      channelId: Config.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    ); // :contentReference[oaicite:9]{index=9}
  }

  Future<void> _leaveChannel() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  // Local video view widget
  Widget _buildLocalVideo() {
    if (!_isJoined || _localUid == null) {
      return const Center(child: Text('Joining channel...'));
    }
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine,
        canvas: const VideoCanvas(uid: 0),
      ),
    ); // :contentReference[oaicite:10]{index=10}
  }

  // Remote video view widget
  Widget _buildRemoteVideo() {
    if (_remoteUids.isEmpty) {
      return const Center(child: Text('Waiting for a peer to join...'));
    }
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine,
        canvas: VideoCanvas(uid: _remoteUids.first),
        connection: RtcConnection(channelId: Config.channelName),
      ),
    ); // :contentReference[oaicite:11]{index=11}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Call')),
      body: Stack(
        children: [
          // Remote fills the screen
          Positioned.fill(child: _buildRemoteVideo()),

          // Local as a small overlay
          Positioned(
            top: 16,
            right: 16,
            width: 120,
            height: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                ),
                child: _buildLocalVideo(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _leaveChannel,
        child: const Icon(Icons.call_end),
        backgroundColor: Colors.red,
      ),
    );
  }
}
