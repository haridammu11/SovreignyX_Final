import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'config_service.dart';

/// Singleton service that manages proctoring across the entire app lifecycle.
/// This ensures camera and streaming continue even when navigating between screens.
class ProctorService extends ChangeNotifier {
  static final ProctorService _instance = ProctorService._internal();
  factory ProctorService() => _instance;
  ProctorService._internal();

  // State
  CameraController? _cameraController;
  Timer? _captureTimer;
  WebSocketChannel? _wsChannel;
  int? _sessionId;
  String? _userId;
  String? _contestId;
  bool _isActive = false;
  bool _isCapturing = false;
  DateTime? _lastLoggedFrameTime;

  // Configuration
  final String _backendUrl = '${ConfigService.backendBaseUrl}/api/code';
  final String _wsUrl = ConfigService.backendBaseUrl.replaceFirst('http', 'ws');

  // Getters
  bool get isActive => _isActive;
  int? get sessionId => _sessionId;
  CameraController? get cameraController => _cameraController;

  /// Start a proctoring session
  Future<bool> startSession({
    required String userId,
    required String contestId,
  }) async {
    if (_isActive) {
      debugPrint('Proctor: Session already active');
      return true;
    }

    _userId = userId;
    _contestId = contestId;

    try {
      // 1. Initialize backend session
      final response = await http.post(
        Uri.parse('$_backendUrl/start-proctor-session/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'contest_id': contestId,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('Proctor: Failed to start backend session');
        return false;
      }

      final data = jsonDecode(response.body);
      _sessionId = data['session_id'];

      // 2. Initialize camera
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('Proctor: No cameras available');
        return false;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      // 3. Initialize WebSocket
      _wsChannel = WebSocketChannel.connect(
        Uri.parse('$_wsUrl/ws/proctor/$_sessionId/'),
      );

      // 4. Start capture timer
      _startCapture();

      _isActive = true;
      notifyListeners();

      debugPrint('Proctor: Session started successfully (ID: $_sessionId)');
      return true;
    } catch (e) {
      debugPrint('Proctor: Error starting session: $e');
      return false;
    }
  }

  /// Stop the proctoring session
  Future<void> stopSession() async {
    if (!_isActive) return;

    _captureTimer?.cancel();
    _wsChannel?.sink.close();
    await _cameraController?.dispose();

    // Notify backend
    if (_sessionId != null) {
      try {
        await http.post(
          Uri.parse('$_backendUrl/end-proctor-session/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'session_id': _sessionId}),
        );
      } catch (e) {
        debugPrint('Proctor: Error ending session: $e');
      }
    }

    _cameraController = null;
    _wsChannel = null;
    _sessionId = null;
    _isActive = false;
    notifyListeners();

    debugPrint('Proctor: Session stopped');
  }

  /// Start frame capture loop
  void _startCapture() {
    if (_captureTimer?.isActive ?? false) return;

    _captureTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      _captureAndSendFrame();
    });
  }

  /// Capture and send a single frame
  Future<void> _captureAndSendFrame() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _sessionId == null ||
        _isCapturing) {
      return;
    }

    _isCapturing = true;

    try {
      final image = await _cameraController!.takePicture();
      String base64Image;

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        base64Image = base64Encode(bytes);
      } else {
        final compressedBytes = await FlutterImageCompress.compressWithFile(
          image.path,
          minWidth: 320,
          minHeight: 240,
          quality: 25,
        );
        base64Image = base64Encode(compressedBytes ?? []);
      }

      // Send via WebSocket for live stream
      if (_wsChannel != null) {
        _wsChannel!.sink.add(base64Decode(base64Image));
      }

      // Log to database every 20 seconds
      final now = DateTime.now();
      if (_lastLoggedFrameTime == null ||
          now.difference(_lastLoggedFrameTime!).inSeconds >= 20) {
        await _logFrameToDatabase(base64Image);
        _lastLoggedFrameTime = now;
      }
    } catch (e) {
      debugPrint('Proctor: Frame capture error: $e');
    } finally {
      _isCapturing = false;
    }
  }

  /// Log frame to database for evidence
  Future<void> _logFrameToDatabase(String base64Image) async {
    try {
      await http.post(
        Uri.parse('$_backendUrl/record-proctor-event/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_id': _sessionId,
          'event_type': 'FRAME',
          'description': 'Periodic evidence snapshot',
          'image_data': 'data:image/jpeg;base64,$base64Image',
        }),
      );
    } catch (e) {
      debugPrint('Proctor: Database logging error: $e');
    }
  }

  /// Record a custom event
  Future<void> recordEvent(String eventType, {String? description, String? code}) async {
    if (_sessionId == null) return;

    try {
      await http.post(
        Uri.parse('$_backendUrl/record-proctor-event/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_id': _sessionId,
          'event_type': eventType,
          'description': description ?? '',
          'code_content': code ?? '',
        }),
      );
    } catch (e) {
      debugPrint('Proctor: Event recording error: $e');
    }
  }

  /// Pause capture (for app lifecycle)
  void pauseCapture() {
    _captureTimer?.cancel();
    _cameraController?.dispose();
    debugPrint('Proctor: Capture paused');
  }

  /// Resume capture (for app lifecycle)
  Future<void> resumeCapture() async {
    if (!_isActive) return;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      _startCapture();
      notifyListeners();

      debugPrint('Proctor: Capture resumed');
    } catch (e) {
      debugPrint('Proctor: Resume error: $e');
    }
  }
}
