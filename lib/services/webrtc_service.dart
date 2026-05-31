import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

enum WebRtcState { idle, connecting, connected, error }

class WebRtcService extends ChangeNotifier {
  // WebRTC & Signaling Objects
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  io.Socket? _socket;
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  // State Management
  WebRtcState state = WebRtcState.idle;
  String? sessionUrl;
  String? sessionToken;
  String? errorMsg;

  bool get isConnected => state == WebRtcState.connected;
  bool get isConnecting => state == WebRtcState.connecting;

  Future<void> init() async {
    await remoteRenderer.initialize();
  }

  // Connect via QR Payload
  Future<void> connectFromQr(String qrPayload) async {
    try {
      final parts = _parseQr(qrPayload);
      sessionUrl = parts['url'];
      sessionToken = parts['token'];

      state = WebRtcState.connecting;
      notifyListeners();

      // 1. Initialize Signaling
      _socket = io.io(
          sessionUrl!,
          io.OptionBuilder()
              .setTransports(['websocket'])
              .disableAutoConnect()
              .build());

      // 2. Setup PeerConnection
      final config = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'}
        ]
      };
      _peerConnection = await createPeerConnection(config);

      // 3. Setup Data Channel
      _dataChannel = await _peerConnection!.createDataChannel(
          'hid-channel', RTCDataChannelInit()..ordered = false);

      _dataChannel!.onDataChannelState = (s) {
        if (s == RTCDataChannelState.RTCDataChannelOpen) {
          state = WebRtcState.connected;
          notifyListeners();
        }
      };

      // 4. Handle Incoming Video
      _peerConnection!.onAddStream = (stream) {
        remoteRenderer.srcObject = stream;
        notifyListeners();
      };

      // 5. Connect Socket
      _socket!.connect();
      _socket!.onConnect((_) => debugPrint("Connected to signaling server"));
    } catch (e) {
      state = WebRtcState.error;
      errorMsg = e.toString();
      notifyListeners();
    }
  }

  // HID Input Methods
  Future<void> sendKey(String key, {bool pressed = true}) async {
    if (!isConnected) return;
    _dataChannel?.send(RTCDataChannelMessage(jsonEncode(
        {"type": "keyboard", "key": key, "state": pressed ? "down" : "up"})));
  }

  Future<void> sendMouse(int dx, int dy) async {
    if (!isConnected) return;
    _dataChannel?.send(RTCDataChannelMessage(
        jsonEncode({"type": "mouse", "dx": dx, "dy": dy})));
  }

  void disconnect() {
    _peerConnection?.close();
    _peerConnection = null;
    _socket?.disconnect();
    state = WebRtcState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    remoteRenderer.dispose();
    disconnect();
    super.dispose();
  }

  Map<String, String> _parseQr(String payload) {
    final url =
        RegExp(r'"url"\s*:\s*"([^"]+)"').firstMatch(payload)?.group(1) ?? '';
    final token =
        RegExp(r'"token"\s*:\s*"([^"]+)"').firstMatch(payload)?.group(1) ?? '';
    if (url.isEmpty) throw Exception('Invalid QR code');
    return {'url': url, 'token': token};
  }

  String get statusText {
    switch (state) {
      case WebRtcState.idle:
        return 'Not connected';
      case WebRtcState.connecting:
        return 'Connecting…';
      case WebRtcState.connected:
        return 'Connected via WebRTC';
      case WebRtcState.error:
        return 'Error: ${errorMsg ?? "unknown"}';
    }
  }
}
