import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

/// Lets the camera start initializing the moment the user taps
/// Check In / Check Out - before VerificationScreen is even pushed - so
/// by the time the screen builds, CameraCard can show a live preview
/// immediately instead of a loading spinner.
///
/// Call [prewarm] as early as possible (e.g. right before the
/// Navigator.push in checkinout.dart). VerificationScreen then calls
/// [prewarm] again on init - since it's the same in-flight/cached future,
/// it either resolves instantly (already ready) or just keeps waiting on
/// the same initialization that's already underway, instead of starting
/// a second one.
class CameraService {
  CameraService._();

  static final CameraService instance = CameraService._();

  Future<CameraController>? _initFuture;

  CameraController? _controller;

  /// Non-null only once the controller exists AND is fully initialized -
  /// safe to hand straight to CameraPreview with no further waiting.
  CameraController? get readyController {
    final c = _controller;
    return (c != null && c.value.isInitialized) ? c : null;
  }

  /// Starts camera initialization if nothing is in progress/ready yet.
  /// Safe to call repeatedly - later callers just await the same future.
  Future<CameraController> prewarm() {
    return _initFuture ??= _initialize();
  }

  Future<CameraController> _initialize() async {
    final status = await Permission.camera.request();

    if (!status.isGranted) {
      throw Exception('Camera permission not granted: $status');
    }

    final cameras = await availableCameras();

    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    final controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller.initialize();

    _controller = controller;

    return controller;
  }

  /// Disposes the current controller and clears state so the next
  /// [prewarm] call starts completely fresh. Call this when
  /// VerificationScreen is backgrounded or closed - never leave a stale
  /// controller sitting around holding the camera hardware.
  void reset() {
    _controller?.dispose();
    _controller = null;
    _initFuture = null;
  }
}