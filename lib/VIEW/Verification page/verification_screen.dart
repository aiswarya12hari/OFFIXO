import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:offixo/PROVIDER/Verification%20Page/checkin_provider.dart';
import 'package:offixo/PROVIDER/Verification%20Page/checkout_provider.dart';
import 'package:offixo/SERVICES/battery_saver_service.dart';
import 'package:offixo/VIEW/Checkin%20page/Widgets/battery_saver_dialog.dart';
import 'package:offixo/VIEW/Verification%20page/Widgets/action_button.dart';
import 'package:offixo/VIEW/Verification%20page/Widgets/camera_card.dart';
import 'package:offixo/VIEW/Verification%20page/Widgets/verification_message.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class VerificationScreen extends StatefulWidget {
  final bool isCheckout;

  const VerificationScreen({super.key, this.isCheckout = false});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;

  File? _capturedImage;

  bool _isVerifying = false;

  /// True only while actively fetching a fresh GPS fix after the user
  /// tapped Check In / Check Out (and after the selfie has already been
  /// captured).
  bool _isFetchingLocation = false;

  /// True only during the final "Verifying..." stage - after the selfie
  /// is captured AND location is successfully fetched, right up until
  /// the API call resolves. Kept separate from _isFetchingLocation so
  /// the loading text doesn't fall back to "Verifying..." prematurely
  /// during the (brief, unlabeled) selfie-capture step.
  bool _isSubmittingAttendance = false;

  /// True while the screen is working through its ONE-TIME startup
  /// sequence on open (camera permission -> location permission /
  /// location-services check). Drives the initial "Preparing..."
  /// spinner shown on screen entry only. This sequence NEVER fetches an
  /// actual GPS fix, so it should resolve quickly (no permission
  /// dialogs shown if already granted).
  bool _isInitializing = true;

  bool _showResult = false;

  bool? _verificationSuccess;

  String _locationFailureMessage = '';

  /// Tags each camera *controller* (re)initialization attempt so a
  /// stale attempt (superseded by dispose or a newer resume-triggered
  /// attempt) can be detected and discarded.
  ///
  /// IMPORTANT: this counter is scoped ONLY to camera controller
  /// (re)initialization. It must never be used to gate the one-time
  /// startup permission sequence in [_initializePermissions] - see the
  /// comment there for why mixing the two was the root cause of the
  /// "location permission only requested after reopening the screen"
  /// bug.
  int _initGeneration = 0;

  /// Tags each Check-In/Check-Out attempt (the full
  /// capture-locate-verify-submit sequence kicked off by
  /// [_captureAndVerify]). Bumped on [dispose] and whenever a brand new
  /// attempt starts, so a result belonging to an OLD attempt (e.g. one
  /// that was still in flight when the user backed out) can never
  /// update the UI, even if that old attempt happens to share the same
  /// State instance as a later "Try Again" tap would.
  int _verificationGeneration = 0;

  /// Set the instant the user backs out — either by tapping the
  /// on-screen back arrow or via the system back button/gesture — and
  /// BEFORE `Navigator.pop()` even runs.
  ///
  /// ROOT CAUSE of the "Success shows after Back" bug: `mounted` stays
  /// `true` for the entire pop transition animation, not just until the
  /// user taps back. If an in-flight verification's API call resolves
  /// during that transition window, a `mounted`-only check still passes,
  /// so `setState()` succeeds and the Success/Failure UI flashes for a
  /// frame while the screen is sliding away. `_isClosing` is independent
  /// of `mounted` and flips synchronously on the back action itself, so
  /// every guard below closes this window completely.
  bool _isClosing = false;

  /// True once the camera controller has been successfully assigned at
  /// least once this screen entry. The app-resume handler uses this to
  /// tell "camera was genuinely torn down mid-session (app backgrounded
  /// after being ready)" apart from "camera hasn't been set up yet
  /// because we're still in the initial permission sequence" - the
  /// latter must NOT trigger a reinit, since the resume event fired by
  /// the OS permission dialog itself would otherwise race with
  /// [_initializePermissions].
  bool _cameraEverInitialized = false;

  /// True when the app opened Battery Saver settings and is waiting
  /// for the user to return to the app.
  bool _waitingForBatterySaverSettings = false;

  /// Prevents duplicate resume handling.
  bool _isHandlingResume = false;

  /// True once [Geolocator.requestPermission] has been called for this
  /// Verification-screen entry (this State instance's lifetime). Without
  /// this, a permission denied (but not permanently) during startup
  /// would trigger a second native dialog the moment the user taps
  /// Check In / Check Out.
  bool _hasRequestedLocationPermissionThisEntry = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _initializePermissions();
  }

  /// Whether a Check-In/Check-Out attempt tagged [myGeneration] is safe
  /// to keep acting on. Combines three independent reasons an attempt
  /// can go stale:
  ///  - the widget was actually disposed (`!mounted`)
  ///  - the user has already triggered Back, even if disposal /
  ///    the pop transition hasn't finished yet (`_isClosing`)
  ///  - a newer attempt has since superseded this one
  ///    (`myGeneration != _verificationGeneration`)
  ///
  /// Call this after every `await` in the verification flow, before
  /// touching `setState`, showing Success/Failure, or navigating.
  bool _isStaleAttempt(int myGeneration) =>
      !mounted || _isClosing || myGeneration != _verificationGeneration;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      debugPrint('[LIFECYCLE] App paused');

      _controller?.dispose();

      if (mounted) {
        setState(() {
          _controller = null;
        });
      } else {
        _controller = null;
      }
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('[LIFECYCLE] App resumed');

      if (_waitingForBatterySaverSettings &&
          _isVerifying &&
          !_isHandlingResume) {
        _continueAfterBatterySaverSettings();
      }

      // Only reinitialize the camera on resume if it was genuinely torn
      // down mid-session (already ready once, then backgrounded). Do
      // NOT do this while the initial permission sequence is still
      // running - the resume event fired by the OS permission dialog
      // closing must not be mistaken for that, or it bumps
      // `_initGeneration` and races with `_initializePermissions()`.
      if (_cameraEverInitialized &&
          (_controller == null || !_controller!.value.isInitialized)) {
        final myGeneration = ++_initGeneration;
        _initializeCameraController(generation: myGeneration);
      }
    }
  }

  /// Called when the user returns from Android Battery Saver settings.
  Future<void> _continueAfterBatterySaverSettings() async {
    if (_isHandlingResume) {
      return;
    }

    _isHandlingResume = true;

    // The attempt that was in progress when Battery Saver settings were
    // opened is still tagged with whatever generation was current at
    // that time. Nothing else bumps `_verificationGeneration` while
    // we're waiting on the user (no new attempt can start - the button
    // is hidden behind `_isVerifying`), so reading it now recovers the
    // same token `_captureAndVerify` captured originally.
    final myGeneration = _verificationGeneration;

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      if (_isStaleAttempt(myGeneration) || !_isVerifying) {
        return;
      }

      final batterySaverOn = await BatterySaverService.instance
          .isBatterySaverOn();

      debugPrint(
        '[BATTERY SAVER] Status after returning: '
        '${batterySaverOn ? "ON" : "OFF"}',
      );

      if (_isStaleAttempt(myGeneration) || !_isVerifying) {
        return;
      }

      _waitingForBatterySaverSettings = false;

      if (batterySaverOn) {
        setState(() {
          _isVerifying = false;
          _isFetchingLocation = false;
          _isSubmittingAttendance = false;
        });

        await BatterySaverDialog.show(context);

        return;
      }

      debugPrint('[BATTERY SAVER] OFF - continuing attendance flow');

      await _fetchLocationCaptureAndSubmit(myGeneration);
    } finally {
      _isHandlingResume = false;
    }
  }

  /// One-time startup sequence, run exactly once per Verification-screen
  /// entry.
  ///
  /// ROOT CAUSE FIX (see class doc above for the full story): this no
  /// longer shares its continuation gate with the camera-controller
  /// generation counter. It just runs straight through camera
  /// permission -> location permission, checking `mounted` at each
  /// await instead of a generation value that unrelated camera-resume
  /// logic could also mutate.
  ///
  /// IMPORTANT: this only checks/requests permissions. It never fetches
  /// an actual GPS position - that only happens after the user taps
  /// Check In / Check Out, inside [_fetchLocationCaptureAndSubmit].
  Future<void> _initializePermissions() async {
    // ---------------------------------------------------------
    // Step 1: Camera permission (+ kick off camera hardware init in
    // the background - does not block step 2 below).
    // ---------------------------------------------------------

    final cameraGranted = await _requestCameraPermission();

    if (!mounted) {
      return;
    }

    if (cameraGranted) {
      final myGeneration = ++_initGeneration;

      // Fire-and-forget: camera hardware init runs in the background
      // and must not block the location permission request that
      // follows immediately below.
      _initializeCameraController(
        generation: myGeneration,
        skipPermissionRequest: true,
      );
    } else {
      debugPrint('Camera permission not granted');
    }

    // ---------------------------------------------------------
    // Step 2: Location permission + location-services check only.
    // No GPS fetch here.
    // ---------------------------------------------------------

    await _ensureLocationReady();

    if (!mounted) {
      return;
    }

    setState(() {
      _isInitializing = false;
    });
  }

  /// Requests Camera permission and returns whether it was granted.
  /// Safe to call when already granted - returns immediately, no dialog.
  Future<bool> _requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Camera permission request error: $e');
      return false;
    }
  }

  /// Ensures location permission is granted and location services are
  /// enabled, WITHOUT performing an actual GPS fetch. Returns true only
  /// when it's safe to proceed to fetching a position. Safe to call
  /// when permission is already granted - no dialog is shown.
  ///
  /// This is the ONLY place in the Verification screen that calls
  /// [Geolocator.requestPermission]. It's called from both the startup
  /// sequence and the Check In / Check Out tap, so
  /// [_hasRequestedLocationPermissionThisEntry] guards against asking
  /// twice in the same screen entry.
  Future<bool> _ensureLocationReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      debugPrint('[LOCATION] Location service is disabled');

      if (mounted) {
        await Geolocator.openLocationSettings();
      }

      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      if (_hasRequestedLocationPermissionThisEntry) {
        debugPrint(
          '[LOCATION-PERM] Skipping requestPermission() - already '
          'requested once this Verification-screen entry (still denied)',
        );

        return false;
      }

      debugPrint('[LOCATION] Requesting location permission');

      debugPrint(
        '[LOCATION-PERM] requestPermission() called from '
        '_ensureLocationReady() (isCheckout: ${widget.isCheckout})',
      );

      _hasRequestedLocationPermissionThisEntry = true;

      permission = await Geolocator.requestPermission();

      debugPrint('[LOCATION-PERM] requestPermission() result: $permission');

      if (permission == LocationPermission.denied) {
        debugPrint('[LOCATION] Location permission denied');

        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('[LOCATION] Location permission permanently denied');

      if (mounted) {
        await Geolocator.openAppSettings();
      }

      return false;
    }

    return true;
  }

  /// Fetches the current GPS position. Assumes [_ensureLocationReady]
  /// has already returned true - this only performs the actual fix
  /// acquisition with accuracy retries.
  Future<Position?> _fetchGpsPosition() async {
    debugPrint('[LOCATION] Starting location fetch...');

    final sw = Stopwatch()..start();

    Position? position;

    int retryCount = 0;

    while (retryCount < 3) {
      debugPrint(
        '[LOCATION] Requesting GPS position (attempt ${retryCount + 1})',
      );

      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );

        debugPrint(
          '[GPS] Accuracy: ${position.accuracy.toStringAsFixed(1)} meters',
        );

        if (position.accuracy <= 20) {
          break;
        }
      } catch (e) {
        debugPrint('[LOCATION] Attempt ${retryCount + 1} failed: $e');

        position = null;
      }

      retryCount++;

      if (retryCount < 3) {
        debugPrint(
          position == null
              ? '[GPS] Attempt timed out or errored. Retrying...'
              : '[GPS] Accuracy is above 20m. Retrying...',
        );

        await Future.delayed(const Duration(seconds: 2));
      }
    }

    debugPrint('[TIMING] Location resolved in ${sw.elapsedMilliseconds}ms');

    if (position == null) {
      debugPrint('[LOCATION] Failed to get a location fix after retries');

      return null;
    }

    debugPrint('[LOCATION] Latitude: ${position.latitude}');
    debugPrint('[LOCATION] Longitude: ${position.longitude}');

    return position;
  }

  /// Fetches the current device location. Called only after the user
  /// presses Check In / Check Out (and after the selfie is captured).
  Future<Position?> _fetchLocation() async {
    final ready = await _ensureLocationReady();

    if (!ready) {
      return null;
    }

    return _fetchGpsPosition();
  }

  /// Main Check In / Check Out data flow, run after the user taps the
  /// bottom button (and after any Battery Saver handling in
  /// [_captureAndVerify] has resolved).
  ///
  /// [myGeneration] is the token captured when this attempt started
  /// (see [_captureAndVerify]). Every stage below re-checks
  /// [_isStaleAttempt] immediately after its `await` - if the user
  /// pressed Back (or a newer attempt somehow started) while that
  /// `await` was in flight, the function returns immediately without
  /// touching `setState`, showing Success/Failure, or continuing to the
  /// next stage.
  ///
  /// 1. Capture the selfie first - no dedicated loading text is shown
  ///    for this step (it happens quickly against the already-live
  ///    camera preview); the spinner is visible but unlabeled.
  /// 2. Fetch current GPS location - shows "Fetching location...".
  /// 3. Submit attendance - shows "Verifying..." (set right before the
  ///    API call starts, not any earlier, so this text only ever
  ///    appears once, at the correct point in the sequence).
  /// 4. Show Success / Failure.
  Future<void> _fetchLocationCaptureAndSubmit(int myGeneration) async {
    if (_isStaleAttempt(myGeneration) || !_isVerifying) {
      return;
    }

    // ---------------------------------------------------------
    // Step 1: Capture selfie
    // ---------------------------------------------------------

    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint('[ATTENDANCE] Camera not ready for capture');

      if (_isStaleAttempt(myGeneration)) {
        return;
      }

      setState(() {
        _isVerifying = false;
        _isFetchingLocation = false;
        _isSubmittingAttendance = false;
        _showResult = true;
        _verificationSuccess = false;
        _locationFailureMessage = '';
      });

      return;
    }

    try {
      final captureSw = Stopwatch()..start();

      final image = await _controller!.takePicture();

      debugPrint(
        '[TIMING] Photo capture took ${captureSw.elapsedMilliseconds}ms',
      );

      final selfie = File(image.path);

      final fileSizeKb = (await selfie.length()) / 1024;

      debugPrint(
        '[TIMING] Captured selfie size: ${fileSizeKb.toStringAsFixed(1)} KB',
      );

      if (_isStaleAttempt(myGeneration)) {
        return;
      }

      setState(() {
        _capturedImage = selfie;
      });
    } catch (e) {
      debugPrint('[ATTENDANCE] Capture error: $e');

      if (_isStaleAttempt(myGeneration)) {
        return;
      }

      setState(() {
        _isVerifying = false;
        _isSubmittingAttendance = false;
        _showResult = true;
        _verificationSuccess = false;
      });

      return;
    }

    // ---------------------------------------------------------
    // Step 2: Fetch location
    // ---------------------------------------------------------

    if (_isStaleAttempt(myGeneration)) {
      return;
    }

    setState(() {
      _isFetchingLocation = true;
    });

    debugPrint('[LOCATION] Fetching location...');

    final position = await _fetchLocation();

    if (_isStaleAttempt(myGeneration)) {
      return;
    }

    if (position == null) {
      debugPrint('[LOCATION] Failed to get location');

      setState(() {
        _isVerifying = false;
        _isFetchingLocation = false;
        _isSubmittingAttendance = false;
        _showResult = true;
        _verificationSuccess = false;

        _locationFailureMessage =
            'Could not get your location. '
            'Please check your location settings and try again.';
      });

      return;
    }

    debugPrint('[LOCATION] Successfully received location');

    // ---------------------------------------------------------
    // Step 3: Submit ("Verifying...")
    // ---------------------------------------------------------
    //
    // _isSubmittingAttendance flips on here - right before the API call -
    // so "Verifying..." only ever shows at this exact point, never
    // during the earlier selfie-capture step.

    setState(() {
      _isFetchingLocation = false;
      _isSubmittingAttendance = true;
    });

    await _submitAttendance(position, myGeneration);
  }

  /// Sends the attendance request after selfie + location are ready.
  /// See [_fetchLocationCaptureAndSubmit] for what [myGeneration] means.
  Future<void> _submitAttendance(Position position, int myGeneration) async {
    if (_isStaleAttempt(myGeneration) || _capturedImage == null) {
      return;
    }

    final apiSw = Stopwatch()..start();

    try {
      // ---------------------------------------------------------
      // CHECK OUT
      // ---------------------------------------------------------

      if (widget.isCheckout) {
        final provider = context.read<CheckOutProvider>();

        await provider.submitCheckOut(
          selfie: _capturedImage!,
          prefetchedPosition: position,
        );

        debugPrint(
          '[TIMING] Check-out API call took ${apiSw.elapsedMilliseconds}ms',
        );

        // The API call has resolved. Regardless of the result, ignore it
        // entirely if the user backed out (or a newer attempt somehow
        // superseded this one) at any point while it was in flight.
        if (_isStaleAttempt(myGeneration)) {
          return;
        }

        setState(() {
          _verificationSuccess = provider.isSuccess;
          _showResult = true;
          _isVerifying = false;
          _isFetchingLocation = false;
          _isSubmittingAttendance = false;
        });

        return;
      }

      // ---------------------------------------------------------
      // CHECK IN
      // ---------------------------------------------------------

      final provider = context.read<CheckInProvider>();

      await provider.submitCheckIn(
        selfie: _capturedImage!,
        prefetchedPosition: position,
      );

      debugPrint(
        '[TIMING] Check-in API call took ${apiSw.elapsedMilliseconds}ms',
      );

      if (_isStaleAttempt(myGeneration)) {
        return;
      }

      setState(() {
        _verificationSuccess = provider.isSuccess;
        _showResult = true;
        _isVerifying = false;
        _isFetchingLocation = false;
        _isSubmittingAttendance = false;
      });
    } catch (e) {
      debugPrint('[ATTENDANCE] API error: $e');

      if (_isStaleAttempt(myGeneration)) {
        return;
      }

      setState(() {
        _isVerifying = false;
        _isFetchingLocation = false;
        _isSubmittingAttendance = false;
        _showResult = true;
        _verificationSuccess = false;
      });
    }
  }

  /// Initializes the front camera.
  Future<void> _initializeCameraController({
    required int generation,
    bool skipPermissionRequest = false,
  }) async {
    final myGeneration = generation;

    try {
      // ---------------------------------------------------------
      // Camera permission
      // ---------------------------------------------------------

      if (!skipPermissionRequest) {
        final status = await Permission.camera.request();

        if (myGeneration != _initGeneration) {
          return;
        }

        if (!status.isGranted) {
          debugPrint('Camera permission not granted: $status');

          if (mounted) {
            setState(() {});
          }

          return;
        }
      }

      final sw = Stopwatch()..start();

      // ---------------------------------------------------------
      // Camera initialization
      // ---------------------------------------------------------

      const maxAttempts = 3;

      CameraController? cameraController;

      Object? lastError;

      for (var attempt = 1; attempt <= maxAttempts; attempt++) {
        if (myGeneration != _initGeneration) {
          return;
        }

        CameraController? attemptController;

        try {
          final cameras = await availableCameras();

          if (cameras.isEmpty) {
            throw Exception('No cameras available');
          }

          final frontCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
          );

          attemptController = CameraController(
            frontCamera,
            ResolutionPreset.medium,
            enableAudio: false,
          );

          await attemptController.initialize().timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw TimeoutException(
                'Camera initialize() did not respond in time',
              );
            },
          );

          cameraController = attemptController;

          break;
        } catch (e) {
          lastError = e;

          debugPrint(
            '[TIMING] Camera init attempt $attempt/$maxAttempts failed: $e',
          );

          try {
            await attemptController?.dispose();
          } catch (_) {}

          if (attempt < maxAttempts) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }

      debugPrint(
        '[TIMING] Camera initialized in ${sw.elapsedMilliseconds}ms '
        '(succeeded: ${cameraController != null})',
      );

      if (myGeneration != _initGeneration) {
        try {
          await cameraController?.dispose();
        } catch (_) {}

        return;
      }

      if (cameraController == null) {
        debugPrint('Camera Error: all init attempts failed - $lastError');

        if (mounted) {
          setState(() {});
        }

        return;
      }

      if (mounted) {
        setState(() {
          _controller = cameraController;
          _cameraEverInitialized = true;
        });
      } else {
        await cameraController.dispose();
      }
    } catch (e) {
      debugPrint('Camera Error: $e');

      if (myGeneration == _initGeneration && mounted) {
        setState(() {});
      }
    }
  }

  /// Called when the user taps the bottom Check In / Check Out button.
  /// Handles Battery Saver, then delegates the actual capture / location
  /// fetch / submit sequence to [_fetchLocationCaptureAndSubmit].
  Future<void> _captureAndVerify() async {
    if (_isVerifying || _isInitializing || _isClosing) {
      return;
    }

    // Tag this attempt. Every async continuation below carries this
    // token and re-checks it (via [_isStaleAttempt]) after each await,
    // so if the user backs out mid-flow, nothing from this attempt can
    // reach the UI afterwards - see [_fetchLocationCaptureAndSubmit] and
    // [_submitAttendance].
    final myGeneration = ++_verificationGeneration;

    final totalSw = Stopwatch()..start();

    try {
      setState(() {
        _isVerifying = true;
        _isFetchingLocation = false;
        _isSubmittingAttendance = false;
        _locationFailureMessage = '';
        _showResult = false;
        _verificationSuccess = null;
        _capturedImage = null;
      });

      debugPrint(
        '[ATTENDANCE] ${widget.isCheckout ? "CHECK-OUT" : "CHECK-IN"} started',
      );

      // ---------------------------------------------------------
      // Check Battery Saver
      // ---------------------------------------------------------

      debugPrint('[BATTERY SAVER] Checking battery saver state...');

      final batterySaverOn = await BatterySaverService.instance
          .isBatterySaverOn();

      if (_isStaleAttempt(myGeneration)) {
        return;
      }

      debugPrint('[BATTERY SAVER] ${batterySaverOn ? "ON" : "OFF"}');

      if (batterySaverOn) {
        debugPrint('[BATTERY SAVER] ON - opening settings');

        _waitingForBatterySaverSettings = true;

        await BatterySaverDialog.show(context);

        if (_isStaleAttempt(myGeneration)) {
          return;
        }

        final batteryStillOn = await BatterySaverService.instance
            .isBatterySaverOn();

        if (_isStaleAttempt(myGeneration)) {
          return;
        }

        // If the user opened Settings, the lifecycle resume handler is
        // responsible for continuing the flow.
        if (_waitingForBatterySaverSettings) {
          if (batteryStillOn) {
            debugPrint('[BATTERY SAVER] Still ON - waiting for user');

            return;
          }

          _waitingForBatterySaverSettings = false;

          debugPrint('[BATTERY SAVER] OFF - proceeding to capture selfie');

          await _fetchLocationCaptureAndSubmit(myGeneration);

          debugPrint(
            '[TIMING] TOTAL attendance flow took ${totalSw.elapsedMilliseconds}ms',
          );

          return;
        }

        // User cancelled and Battery Saver is still ON.
        if (batteryStillOn) {
          debugPrint('[BATTERY SAVER] User cancelled - still ON');

          if (_isStaleAttempt(myGeneration)) {
            return;
          }

          setState(() {
            _isVerifying = false;
            _isFetchingLocation = false;
            _isSubmittingAttendance = false;
          });

          return;
        }

        // Battery Saver was turned OFF.
        debugPrint('[BATTERY SAVER] OFF - proceeding to capture selfie');

        await _fetchLocationCaptureAndSubmit(myGeneration);

        debugPrint(
          '[TIMING] TOTAL attendance flow took ${totalSw.elapsedMilliseconds}ms',
        );

        return;
      }

      // ---------------------------------------------------------
      // Battery Saver OFF
      // ---------------------------------------------------------

      debugPrint('[BATTERY SAVER] OFF - proceeding to capture selfie');

      _waitingForBatterySaverSettings = false;

      await _fetchLocationCaptureAndSubmit(myGeneration);

      debugPrint(
        '[TIMING] TOTAL attendance flow took ${totalSw.elapsedMilliseconds}ms',
      );
    } catch (e) {
      debugPrint('[ATTENDANCE] Error: $e');

      if (_isStaleAttempt(myGeneration)) {
        return;
      }

      setState(() {
        _isVerifying = false;
        _isFetchingLocation = false;
        _isSubmittingAttendance = false;
        _showResult = true;
        _verificationSuccess = false;
      });
    }
  }

  /// Reset the current attempt.
  ///
  /// IMPORTANT: no location fetching happens here. Location starts only
  /// when Check In / Check Out is pressed.
  void _tryAgain() {
    // Invalidate anything left over from the previous attempt so it can
    // never race with the fresh one the user is about to start.
    _verificationGeneration++;

    context.read<CheckInProvider>().reset();

    context.read<CheckOutProvider>().reset();

    _waitingForBatterySaverSettings = false;

    setState(() {
      _capturedImage = null;
      _showResult = false;
      _isVerifying = false;
      _isFetchingLocation = false;
      _isSubmittingAttendance = false;
      _verificationSuccess = null;
      _locationFailureMessage = '';
    });
  }

  /// Handles the user pressing Back - either the on-screen arrow below,
  /// or the system back button/gesture (see the `PopScope` in [build]).
  ///
  /// Always closes the screen immediately, even mid-verification, per
  /// the required behaviour - Back must never be blocked while
  /// processing. `_isClosing` is set synchronously, before navigation
  /// even starts, so every in-flight `await` in the verification flow
  /// is guaranteed to see it on its very next check (see
  /// [_isStaleAttempt]), regardless of how long the pop transition
  /// animation takes to finish disposing this State.
  void _handleBackPressed() {
    if (_isClosing) {
      return;
    }

    _isClosing = true;
    _verificationGeneration++;

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Belt-and-braces: if dispose is ever reached without going through
    // _handleBackPressed (e.g. the route is popped programmatically from
    // elsewhere), still invalidate any in-flight attempt.
    _isClosing = true;
    _initGeneration++;
    _verificationGeneration++;

    _controller?.dispose();

    // IMPORTANT: Do NOT call context.read(), Provider.of(), etc. here -
    // this avoids "Looking up a deactivated widget's ancestor is unsafe."
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkInProvider = context.watch<CheckInProvider>();

    final checkOutProvider = context.watch<CheckOutProvider>();

    final isCheckout = widget.isCheckout;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _isClosing = true;
          _verificationGeneration++;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 70),

                        // -------------------------------------------------
                        // CAMERA
                        // -------------------------------------------------
                        CameraCard(
                          controller: _controller,
                          isSuccess: _verificationSuccess,
                          capturedImage: _capturedImage,
                        ),

                        const SizedBox(height: 30),

                        // -------------------------------------------------
                        // LOADING (capturing / fetching location / verifying)
                        // -------------------------------------------------
                        //
                        // No text is shown during the brief selfie-capture
                        // window (just the spinner) - "Fetching location..."
                        // and "Verifying..." each appear exactly once, in
                        // that order, at the correct point in the flow.
                        if (_isVerifying)
                          Column(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              if (_isFetchingLocation)
                                const Text(
                                  'Fetching location...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                )
                              else if (_isSubmittingAttendance)
                                const Text(
                                  'Verifying...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                            ],
                          )
                        // -------------------------------------------------
                        // RESULT
                        // -------------------------------------------------
                        else if (_showResult)
                          Column(
                            children: [
                              VerificationMessage(
                                title: isCheckout
                                    ? (_verificationSuccess == true
                                          ? 'Success 🎉'
                                          : 'Check-Out Failed ❌')
                                    : checkInProvider.isAlreadyCheckedIn
                                    ? 'Already Checked In'
                                    : (_verificationSuccess == true
                                          ? 'Success 🎉'
                                          : 'Check-In Failed ❌'),
                                message: isCheckout
                                    ? (_verificationSuccess == true
                                          ? (checkOutProvider
                                                    .response
                                                    ?.message ??
                                                'Check-out successful')
                                          : (_locationFailureMessage.isNotEmpty
                                                ? _locationFailureMessage
                                                : (checkOutProvider
                                                          .errorMessage
                                                          .isNotEmpty
                                                      ? checkOutProvider
                                                            .errorMessage
                                                      : 'Check-out failed')))
                                    : checkInProvider.isAlreadyCheckedIn
                                    ? (checkInProvider
                                                  .response
                                                  ?.message
                                                  .isNotEmpty ==
                                              true
                                          ? checkInProvider.response!.message
                                          : 'You have already checked in today.')
                                    : (_verificationSuccess == true
                                          ? (checkInProvider
                                                    .response
                                                    ?.message ??
                                                'Check-in successful')
                                          : (_locationFailureMessage.isNotEmpty
                                                ? _locationFailureMessage
                                                : (checkInProvider
                                                          .errorMessage
                                                          .isNotEmpty
                                                      ? checkInProvider
                                                            .errorMessage
                                                      : 'Check-in failed'))),
                              ),
                              const SizedBox(height: 25),
                              ActionButtons(
                                isSuccess: _verificationSuccess == true,
                                onTryAgain: _tryAgain,
                              ),
                            ],
                          )
                        // -------------------------------------------------
                        // INITIAL STARTUP (permission checks only)
                        // -------------------------------------------------
                        else if (_isInitializing)
                          const Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                'Preparing...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          )
                        // -------------------------------------------------
                        // CHECK IN / CHECK OUT BUTTON
                        // -------------------------------------------------
                        else
                          SizedBox(
                            width: 300,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _captureAndVerify,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                isCheckout ? 'Check Out' : 'Check In',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // -----------------------------------------------------------
              // BACK BUTTON
              //
              // Always active - even while verifying - per the required
              // behaviour. It no longer refuses to fire when
              // `_isVerifying` is true; instead, [_handleBackPressed]
              // marks `_isClosing` synchronously so the in-flight
              // verification is guaranteed to stop updating the UI.
              // -----------------------------------------------------------
              Positioned(
                top: 12,
                left: 16,
                child: GestureDetector(
                  onTap: _handleBackPressed,
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
