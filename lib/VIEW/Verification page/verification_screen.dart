// import 'dart:async';
// import 'dart:io';

// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:offixo/PROVIDER/Verification%20Page/checkin_provider.dart';
// import 'package:offixo/PROVIDER/Verification%20Page/checkout_provider.dart';
// import 'package:offixo/SERVICES/battery_saver_service.dart';
// import 'package:offixo/VIEW/Checkin%20page/Widgets/battery_saver_dialog.dart';
// import 'package:offixo/VIEW/Verification%20page/Widgets/action_button.dart';
// import 'package:offixo/VIEW/Verification%20page/Widgets/camera_card.dart';
// import 'package:offixo/VIEW/Verification%20page/Widgets/verification_message.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:provider/provider.dart';

// class VerificationScreen extends StatefulWidget {
//   final bool isCheckout;

//   const VerificationScreen({super.key, this.isCheckout = false});

//   @override
//   State<VerificationScreen> createState() => _VerificationScreenState();
// }

// class _VerificationScreenState extends State<VerificationScreen>
//     with WidgetsBindingObserver {
//   CameraController? _controller;

//   File? _capturedImage;

//   bool _isVerifying = false;

//   bool _showResult = false;

//   bool? _verificationSuccess;

//   /// Tags each `_initializeCamera()` attempt.
//   int _initGeneration = 0;

//   Future<Position?>? _locationFuture;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);

//     _initializeLocationAndCamera();
//   }

//   Future<void> _initializeLocationAndCamera() async {
//     // Resolve camera permission first so its dialog fully dismisses before
//     // location's own permission check (inside _prefetchLocation) runs —
//     // requesting both permissions at once caused Android to drop or
//     // duplicate prompts. _prefetchLocation() already does its own
//     // check-then-request for location, so it isn't repeated here.
//     await Permission.camera.request();

//     _locationFuture = _prefetchLocation();

//     await _initializeCamera();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.paused) {
//       _controller?.dispose();

//       if (mounted) {
//         setState(() {
//           _controller = null;
//         });
//       } else {
//         _controller = null;
//       }
//     } else if (state == AppLifecycleState.resumed) {
//       if (_controller == null || !_controller!.value.isInitialized) {
//         _initializeCamera();
//       }
//     }
//   }

//   Future<Position?> _prefetchLocation() async {
//     try {

//       final batterySaverOn =
//         await BatterySaverService.instance.isBatterySaverOn();

//     if (batterySaverOn && mounted) {
//       await BatterySaverDialog.show(context);
//     }
//       final serviceEnabled = await Geolocator.isLocationServiceEnabled();

//       if (!serviceEnabled) {
//         debugPrint('Location service is disabled');
//         return null;
//       }

//       LocationPermission permission = await Geolocator.checkPermission();

//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();

//         if (permission == LocationPermission.denied) {
//           debugPrint('Location permission denied');
//           return null;
//         }
//       }

//       if (permission == LocationPermission.deniedForever) {
//         debugPrint('Location permission permanently denied');
//         return null;
//       }

//       final sw = Stopwatch()..start();

//       try {
//         Position position;

//         int retryCount = 0;

//         do {
//           position = await Geolocator.getCurrentPosition(
//             desiredAccuracy: LocationAccuracy.high,
//             timeLimit: const Duration(seconds: 15),
//           );

//           debugPrint(
//             '[GPS] Accuracy: ${position.accuracy.toStringAsFixed(1)} meters',
//           );

//           if (position.accuracy <= 20) {
//             break;
//           }

//           retryCount++;

//           await Future.delayed(const Duration(seconds: 2));
//         } while (retryCount < 3);

//         debugPrint(
//           '[TIMING] Location resolved in '
//           '${sw.elapsedMilliseconds}ms',
//         );

//         return position;
//       } catch (e) {
//         debugPrint('Location Error: $e');
//         return null;
//       }
//     } catch (e) {
//       debugPrint('Location Error: $e');
//       return null;
//     }
//   }

//   Future<void> _initializeCamera() async {
//     final myGeneration = ++_initGeneration;

//     try {
//       /// Request camera permission FIRST and wait for the user's response
//       /// to fully resolve before ever touching CameraController.
//       final status = await Permission.camera.request();

//       if (myGeneration != _initGeneration) return;

//       if (!status.isGranted) {
//         debugPrint('Camera permission not granted: $status');

//         if (mounted) {
//           setState(() {});
//         }

//         return;
//       }

//       final sw = Stopwatch()..start();

//       // On a fresh install, the very first time camera permission is
//       // granted, Android's camera service can take a moment to actually
//       // become ready - availableCameras()/CameraController.initialize()
//       // can hang or fail right after that first grant, even though the
//       // permission itself is fine. Retrying a couple of times (with a
//       // timeout so a hung initialize() doesn't stall forever, and a fresh
//       // CameraController each attempt) reproduces exactly what manually
//       // backing out and reopening the screen was doing - just
//       // automatically, without the user having to do it themselves.
//       const maxAttempts = 3;

//       CameraController? cameraController;
//       Object? lastError;

//       for (var attempt = 1; attempt <= maxAttempts; attempt++) {
//         if (myGeneration != _initGeneration) return;

//         CameraController? attemptController;

//         try {
//           final cameras = await availableCameras();

//           final frontCamera = cameras.firstWhere(
//             (camera) => camera.lensDirection == CameraLensDirection.front,
//           );

//           attemptController = CameraController(
//             frontCamera,
//             ResolutionPreset.medium,
//             enableAudio: false,
//           );

//           await attemptController.initialize().timeout(
//             const Duration(seconds: 5),
//             onTimeout: () {
//               throw TimeoutException(
//                 'Camera initialize() did not respond in time',
//               );
//             },
//           );

//           cameraController = attemptController;
//           break;
//         } catch (e) {
//           lastError = e;

//           debugPrint(
//             '[TIMING] Camera init attempt $attempt/$maxAttempts failed: $e',
//           );

//           // Clean up the stuck/failed controller before retrying - reusing
//           // one that failed to initialize can itself get stuck again.
//           try {
//             await attemptController?.dispose();
//           } catch (_) {}

//           if (attempt < maxAttempts) {
//             await Future.delayed(const Duration(milliseconds: 500));
//           }
//         }
//       }

//       debugPrint(
//         '[TIMING] Camera initialized in '
//         '${sw.elapsedMilliseconds}ms '
//         '(succeeded: ${cameraController != null})',
//       );

//       if (myGeneration != _initGeneration) {
//         cameraController?.dispose();
//         return;
//       }

//       if (cameraController == null) {
//         debugPrint('Camera Error: all init attempts failed - $lastError');

//         if (mounted) {
//           setState(() {});
//         }

//         return;
//       }

//       if (mounted) {
//         setState(() {
//           _controller = cameraController;
//         });
//       } else {
//         cameraController.dispose();
//       }
//     } catch (e) {
//       debugPrint('Camera Error: $e');

//       if (myGeneration == _initGeneration && mounted) {
//         setState(() {});
//       }
//     }
//   }

//   Future<void> _captureAndVerify() async {
//     if (_controller == null || !_controller!.value.isInitialized) {
//       return;
//     }

//     final totalSw = Stopwatch()..start();

//     try {
//       setState(() {
//         _isVerifying = true;
//       });

//       final captureSw = Stopwatch()..start();

//       final image = await _controller!.takePicture();

//       debugPrint(
//         '[TIMING] Photo capture took '
//         '${captureSw.elapsedMilliseconds}ms',
//       );

//       final selfie = File(image.path);

//       final fileSizeKb = (await selfie.length()) / 1024;

//       debugPrint(
//         '[TIMING] Captured selfie size: '
//         '${fileSizeKb.toStringAsFixed(1)} KB',
//       );

//       setState(() {
//         _capturedImage = selfie;
//       });

//       final locationSw = Stopwatch()..start();

//       // Use the same location request started in initState.
//       final position = await (_locationFuture ?? Future.value(null));

//       debugPrint(
//         '[TIMING] Awaiting location took '
//         '${locationSw.elapsedMilliseconds}ms '
//         '(should be ~0 if prefetch already finished)',
//       );

//       final apiSw = Stopwatch()..start();

//       /// CHECKOUT
//       if (widget.isCheckout) {
//         final provider = context.read<CheckOutProvider>();

//         await provider.submitCheckOut(
//           selfie: selfie,
//           prefetchedPosition: position,
//         );

//         debugPrint(
//           '[TIMING] Check-out API call took '
//           '${apiSw.elapsedMilliseconds}ms',
//         );

//         debugPrint(
//           '[TIMING] TOTAL check-out flow took '
//           '${totalSw.elapsedMilliseconds}ms',
//         );

//         setState(() {
//           _verificationSuccess = provider.isSuccess;

//           _showResult = true;

//           _isVerifying = false;
//         });
//       }
//       /// CHECKIN
//       else {
//         final provider = context.read<CheckInProvider>();

//         await provider.submitCheckIn(
//           selfie: selfie,
//           prefetchedPosition: position,
//         );

//         debugPrint(
//           '[TIMING] Check-in API call took '
//           '${apiSw.elapsedMilliseconds}ms',
//         );

//         debugPrint(
//           '[TIMING] TOTAL check-in flow took '
//           '${totalSw.elapsedMilliseconds}ms',
//         );

//         setState(() {
//           _verificationSuccess = provider.isSuccess;

//           _showResult = true;

//           _isVerifying = false;
//         });
//       }
//     } catch (_) {
//       setState(() {
//         _isVerifying = false;

//         _showResult = true;

//         _verificationSuccess = false;
//       });
//     }
//   }

//   void _tryAgain() {
//     context.read<CheckInProvider>().reset();

//     context.read<CheckOutProvider>().reset();

//     _locationFuture = _prefetchLocation();
//     setState(() {
//       _capturedImage = null;

//       _showResult = false;

//       _isVerifying = false;

//       _verificationSuccess = null;
//     });
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);

//     _controller?.dispose();

//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final checkInProvider = context.watch<CheckInProvider>();

//     final checkOutProvider = context.watch<CheckOutProvider>();

//     final isCheckout = widget.isCheckout;

//     return Scaffold(
//       backgroundColor: Colors.transparent,

//       extendBodyBehindAppBar: true,

//       body: SafeArea(
//         child: Stack(
//           children: [
//             SingleChildScrollView(
//               child: Center(
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 24),

//                   child: Column(
//                     children: [
//                       const SizedBox(height: 70),

//                       CameraCard(
//                         controller: _controller,

//                         isSuccess: _verificationSuccess,

//                         capturedImage: _capturedImage,
//                       ),

//                       const SizedBox(height: 30),

//                       /// LOADER
//                       if (_isVerifying)
//                         const Column(
//                           children: [
//                             CircularProgressIndicator(),

//                             SizedBox(height: 16),

//                             Text(
//                               'Verifying...',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 18,
//                               ),
//                             ),
//                           ],
//                         )
//                       /// RESULT
//                       else if (_showResult)
//                         Column(
//                           children: [
//                             VerificationMessage(
//                               title: isCheckout
//                                   ? (_verificationSuccess == true
//                                         ? 'Success 🎉'
//                                         : 'Check-Out Failed ❌')
//                                   : checkInProvider.isAlreadyCheckedIn
//                                   ? 'Already Checked In'
//                                   : (_verificationSuccess == true
//                                         ? 'Success 🎉'
//                                         : 'Check-In Failed ❌'),

//                               message: isCheckout
//                                   ? (_verificationSuccess == true
//                                         ? (checkOutProvider.response?.message ??
//                                               'Check-out successful')
//                                         : (checkOutProvider
//                                                   .errorMessage
//                                                   .isNotEmpty
//                                               ? checkOutProvider.errorMessage
//                                               : 'Check-out failed'))
//                                   : checkInProvider.isAlreadyCheckedIn
//                                   ? (checkInProvider
//                                                 .response
//                                                 ?.message
//                                                 .isNotEmpty ==
//                                             true
//                                         ? checkInProvider.response!.message
//                                         : 'You have already checked in today.')
//                                   : (_verificationSuccess == true
//                                         ? (checkInProvider.response?.message ??
//                                               'Check-in successful')
//                                         : (checkInProvider
//                                                   .errorMessage
//                                                   .isNotEmpty
//                                               ? checkInProvider.errorMessage
//                                               : 'Check-in failed')),
//                             ),

//                             const SizedBox(height: 25),

//                             ActionButtons(
//                               isSuccess: _verificationSuccess == true,

//                               onTryAgain: _tryAgain,
//                             ),
//                           ],
//                         )
//                       /// BUTTON
//                       else
//                         SizedBox(
//                           width: 300,

//                           height: 52,

//                           child: ElevatedButton(
//                             onPressed: _captureAndVerify,

//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.orange,

//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(30),
//                               ),
//                             ),

//                             child: Text(
//                               isCheckout ? 'Check Out' : 'Check In',

//                               style: const TextStyle(
//                                 fontSize: 18,

//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//             /// BACK BUTTON
//             Positioned(
//               top: 12,

//               left: 16,

//               child: GestureDetector(
//                 onTap: () => Navigator.pop(context),

//                 child: const Icon(
//                   Icons.arrow_back,

//                   color: Colors.white,

//                   size: 32,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

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

  const VerificationScreen({
    super.key,
    this.isCheckout = false,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;

  File? _capturedImage;

  bool _isVerifying = false;

  /// True while location is being fetched.
  bool _isFetchingLocation = false;

  /// True while the screen is prefetching a location fix right after
  /// opening (in parallel with camera init), before the user has tapped
  /// Check In / Check Out. Drives the "Fetching location..." message shown
  /// on screen entry only.
  bool _isFetchingInitialLocation = true;

  /// Location fetched on screen open, in parallel with the camera. If
  /// available when the user taps Check In / Check Out, it's used
  /// directly so the flow can skip straight to "Verifying..." instead of
  /// "Fetching location..." again.
  Position? _prefetchedPosition;

  bool _showResult = false;

  bool? _verificationSuccess;

  String _locationFailureMessage = '';

  /// Tags each camera initialization attempt.
  int _initGeneration = 0;

  /// True when the app opened Battery Saver settings and is waiting
  /// for the user to return to the app.
  bool _waitingForBatterySaverSettings = false;

  /// Prevents duplicate resume handling.
  bool _isHandlingResume = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // Camera and location are both requested the moment the screen opens,
    // in parallel, so there's no noticeable delay before either
    // permission prompt appears.
    _initializeCamera();
    _prefetchLocationOnOpen();
  }

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

      // Continue the attendance flow only when the user was
      // actually sent to Battery Saver settings.
      if (_waitingForBatterySaverSettings &&
          _isVerifying &&
          !_isHandlingResume) {
        _continueAfterBatterySaverSettings();
      }

      // Reinitialize camera when returning to the app.
      if (_controller == null ||
          !_controller!.value.isInitialized) {
        _initializeCamera();
      }
    }
  }

  /// Called when the user returns from Android Battery Saver settings.
  ///
  /// Battery Saver is checked again instead of assuming that the
  /// user turned it OFF.
  Future<void> _continueAfterBatterySaverSettings() async {
    if (_isHandlingResume) {
      return;
    }

    _isHandlingResume = true;

    try {
      // Give Android a short moment to update the Battery Saver state.
      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted || !_isVerifying) {
        return;
      }

      final batterySaverOn =
          await BatterySaverService.instance.isBatterySaverOn();

      debugPrint(
        '[BATTERY SAVER] Status after returning: '
        '${batterySaverOn ? "ON" : "OFF"}',
      );

      if (!mounted || !_isVerifying) {
        return;
      }

      _waitingForBatterySaverSettings = false;

      if (batterySaverOn) {
        // User returned without turning Battery Saver OFF.
        setState(() {
          _isVerifying = false;
          _isFetchingLocation = false;
        });

        await BatterySaverDialog.show(context);

        return;
      }

      // Battery Saver is OFF.
      debugPrint(
        '[BATTERY SAVER] OFF - continuing attendance flow',
      );

      await _fetchLocationAndContinue();
    } finally {
      _isHandlingResume = false;
    }
  }

  /// Fetches the current device location.
  ///
  /// This is called only after the user presses
  /// Check In / Check Out.
  Future<Position?> _fetchLocation() async {
    try {
      debugPrint('[LOCATION] Starting location fetch...');

      // ---------------------------------------------------------
      // Location service
      // ---------------------------------------------------------

      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        debugPrint(
          '[LOCATION] Location service is disabled',
        );

        if (mounted) {
          await Geolocator.openLocationSettings();
        }

        return null;
      }

      // ---------------------------------------------------------
      // Location permission
      // ---------------------------------------------------------

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        debugPrint(
          '[LOCATION] Requesting location permission',
        );

        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          debugPrint(
            '[LOCATION] Location permission denied',
          );

          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(
          '[LOCATION] Location permission permanently denied',
        );

        if (mounted) {
          await Geolocator.openAppSettings();
        }

        return null;
      }

      // ---------------------------------------------------------
      // GPS
      // ---------------------------------------------------------

      final sw = Stopwatch()..start();

      Position position;

      int retryCount = 0;

      do {
        debugPrint(
          '[LOCATION] Requesting GPS position '
          '(attempt ${retryCount + 1})',
        );

        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );

        debugPrint(
          '[GPS] Accuracy: '
          '${position.accuracy.toStringAsFixed(1)} meters',
        );

        if (position.accuracy <= 20) {
          break;
        }

        retryCount++;

        if (retryCount < 3) {
          debugPrint(
            '[GPS] Accuracy is above 20m. Retrying...',
          );

          await Future.delayed(
            const Duration(seconds: 2),
          );
        }
      } while (retryCount < 3);

      debugPrint(
        '[TIMING] Location resolved in '
        '${sw.elapsedMilliseconds}ms',
      );

      debugPrint(
        '[LOCATION] Latitude: ${position.latitude}',
      );

      debugPrint(
        '[LOCATION] Longitude: ${position.longitude}',
      );

      return position;
    } catch (e) {
      debugPrint(
        '[LOCATION] Error while fetching location: $e',
      );

      return null;
    }
  }

  /// Prefetches a location fix the moment the screen opens, in parallel
  /// with camera initialization. Drives the "Fetching location..." state
  /// shown on screen entry. The result (which may be null on failure) is
  /// stored and consumed by [_fetchLocationAndContinue] on the first
  /// Check In / Check Out attempt, so that attempt can skip straight to
  /// "Verifying..." instead of fetching location again.
  Future<void> _prefetchLocationOnOpen() async {
    final position = await _fetchLocation();

    if (!mounted) {
      return;
    }

    setState(() {
      _prefetchedPosition = position;
      _isFetchingInitialLocation = false;
    });
  }

  /// Starts location fetching and then submits attendance.
  Future<void> _fetchLocationAndContinue() async {
    if (!mounted || !_isVerifying) {
      return;
    }

    // Use the location prefetched on screen open, if we have one, instead
    // of fetching again. It's consumed here so any later attempt (e.g.
    // after Try Again) fetches a fresh fix as before.
    Position? position = _prefetchedPosition;
    _prefetchedPosition = null;

    if (position == null) {
      setState(() {
        _isFetchingLocation = true;
      });

      debugPrint(
        '[LOCATION] Fetching location...',
      );

      position = await _fetchLocation();

      if (!mounted) {
        return;
      }

      setState(() {
        _isFetchingLocation = false;
      });
    } else {
      debugPrint(
        '[LOCATION] Using prefetched location',
      );
    }

    if (position == null) {
      debugPrint(
        '[LOCATION] Failed to get location',
      );

      setState(() {
        _isVerifying = false;
        _showResult = true;
        _verificationSuccess = false;

        _locationFailureMessage =
            'Could not get your location. '
            'Please check your location settings and try again.';
      });

      return;
    }

    debugPrint(
      '[LOCATION] Successfully received location',
    );

    // Location is ready.
    //
    // UI changes from:
    // Fetching location...
    //
    // to:
    // Verifying...
    setState(() {
      _isFetchingLocation = false;
    });

    await _submitAttendance(position);
  }

  /// Sends the attendance request after location is successfully obtained.
  Future<void> _submitAttendance(
    Position position,
  ) async {
    if (!mounted || _capturedImage == null) {
      return;
    }

    final apiSw = Stopwatch()..start();

    try {
      // ---------------------------------------------------------
      // CHECK OUT
      // ---------------------------------------------------------

      if (widget.isCheckout) {
        final provider =
            context.read<CheckOutProvider>();

        await provider.submitCheckOut(
          selfie: _capturedImage!,
          prefetchedPosition: position,
        );

        debugPrint(
          '[TIMING] Check-out API call took '
          '${apiSw.elapsedMilliseconds}ms',
        );

        if (!mounted) {
          return;
        }

        setState(() {
          _verificationSuccess = provider.isSuccess;

          _showResult = true;

          _isVerifying = false;

          _isFetchingLocation = false;
        });

        return;
      }

      // ---------------------------------------------------------
      // CHECK IN
      // ---------------------------------------------------------

      final provider =
          context.read<CheckInProvider>();

      await provider.submitCheckIn(
        selfie: _capturedImage!,
        prefetchedPosition: position,
      );

      debugPrint(
        '[TIMING] Check-in API call took '
        '${apiSw.elapsedMilliseconds}ms',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _verificationSuccess = provider.isSuccess;

        _showResult = true;

        _isVerifying = false;

        _isFetchingLocation = false;
      });
    } catch (e) {
      debugPrint(
        '[ATTENDANCE] API error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isVerifying = false;

        _isFetchingLocation = false;

        _showResult = true;

        _verificationSuccess = false;
      });
    }
  }

  /// Initializes the front camera.
  Future<void> _initializeCamera() async {
    final myGeneration = ++_initGeneration;

    try {
      // ---------------------------------------------------------
      // Camera permission
      // ---------------------------------------------------------

      final status =
          await Permission.camera.request();

      if (myGeneration != _initGeneration) {
        return;
      }

      if (!status.isGranted) {
        debugPrint(
          'Camera permission not granted: $status',
        );

        if (mounted) {
          setState(() {});
        }

        return;
      }

      final sw = Stopwatch()..start();

      // ---------------------------------------------------------
      // Camera initialization
      // ---------------------------------------------------------

      const maxAttempts = 3;

      CameraController? cameraController;

      Object? lastError;

      for (
        var attempt = 1;
        attempt <= maxAttempts;
        attempt++
      ) {
        if (myGeneration != _initGeneration) {
          return;
        }

        CameraController? attemptController;

        try {
          final cameras = await availableCameras();

          if (cameras.isEmpty) {
            throw Exception(
              'No cameras available',
            );
          }

          final frontCamera =
              cameras.firstWhere(
            (camera) =>
                camera.lensDirection ==
                CameraLensDirection.front,
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
            '[TIMING] Camera init attempt '
            '$attempt/$maxAttempts failed: $e',
          );

          try {
            await attemptController?.dispose();
          } catch (_) {}

          if (attempt < maxAttempts) {
            await Future.delayed(
              const Duration(milliseconds: 500),
            );
          }
        }
      }

      debugPrint(
        '[TIMING] Camera initialized in '
        '${sw.elapsedMilliseconds}ms '
        '(succeeded: ${cameraController != null})',
      );

      if (myGeneration != _initGeneration) {
        try {
          await cameraController?.dispose();
        } catch (_) {}

        return;
      }

      if (cameraController == null) {
        debugPrint(
          'Camera Error: all init attempts failed - '
          '$lastError',
        );

        if (mounted) {
          setState(() {});
        }

        return;
      }

      if (mounted) {
        setState(() {
          _controller = cameraController;
        });
      } else {
        await cameraController.dispose();
      }
    } catch (e) {
      debugPrint(
        'Camera Error: $e',
      );

      if (
        myGeneration == _initGeneration &&
        mounted
      ) {
        setState(() {});
      }
    }
  }

  /// Main Check In / Check Out action.
  ///
  /// Flow:
  ///
  /// 1. Show "Fetching location..."
  /// 2. Take selfie
  /// 3. Check Battery Saver
  /// 4. If ON -> show Battery Saver dialog
  /// 5. Open Battery Saver settings
  /// 6. User returns -> check Battery Saver again
  /// 7. If OFF -> fetch location
  /// 8. Show "Verifying..."
  /// 9. Call API
  Future<void> _captureAndVerify() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isVerifying) {
      return;
    }

    final totalSw = Stopwatch()..start();

    try {
      // ---------------------------------------------------------
      // Start UI immediately
      // ---------------------------------------------------------

      setState(() {
        _isVerifying = true;

        _isFetchingLocation = true;

        _locationFailureMessage = '';

        _showResult = false;

        _verificationSuccess = null;
      });

      debugPrint(
        '[ATTENDANCE] '
        '${widget.isCheckout ? "CHECK-OUT" : "CHECK-IN"} started',
      );

      // ---------------------------------------------------------
      // Take selfie
      // ---------------------------------------------------------

      final captureSw = Stopwatch()..start();

      final image =
          await _controller!.takePicture();

      debugPrint(
        '[TIMING] Photo capture took '
        '${captureSw.elapsedMilliseconds}ms',
      );

      final selfie = File(image.path);

      final fileSizeKb =
          (await selfie.length()) / 1024;

      debugPrint(
        '[TIMING] Captured selfie size: '
        '${fileSizeKb.toStringAsFixed(1)} KB',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _capturedImage = selfie;

        // Keep "Fetching location..." visible.
        _isFetchingLocation = true;
      });

      // ---------------------------------------------------------
      // Check Battery Saver
      // ---------------------------------------------------------

      debugPrint(
        '[BATTERY SAVER] Checking battery saver state...',
      );

      final batterySaverOn =
          await BatterySaverService.instance
              .isBatterySaverOn();

      if (!mounted) {
        return;
      }

      debugPrint(
        '[BATTERY SAVER] '
        '${batterySaverOn ? "ON" : "OFF"}',
      );

      // ---------------------------------------------------------
      // Battery Saver ON
      // ---------------------------------------------------------

      if (batterySaverOn) {
        debugPrint(
          '[BATTERY SAVER] ON - opening settings',
        );

        _waitingForBatterySaverSettings = true;

        setState(() {
          _isVerifying = true;
          _isFetchingLocation = true;
        });

        await BatterySaverDialog.show(context);

        if (!mounted) {
          return;
        }

        // Check the state after the dialog closes.
        final batteryStillOn =
            await BatterySaverService.instance
                .isBatterySaverOn();

        if (!mounted) {
          return;
        }

        // If the user opened Settings, the lifecycle resume
        // handler is responsible for continuing the flow.
        if (_waitingForBatterySaverSettings) {
          if (batteryStillOn) {
            debugPrint(
              '[BATTERY SAVER] Still ON - waiting for user',
            );

            return;
          }

          // Battery Saver was turned OFF without a lifecycle
          // resume callback.
          _waitingForBatterySaverSettings = false;

          debugPrint(
            '[BATTERY SAVER] OFF - fetching location',
          );

          await _fetchLocationAndContinue();

          debugPrint(
            '[TIMING] TOTAL attendance flow took '
            '${totalSw.elapsedMilliseconds}ms',
          );

          return;
        }

        // User cancelled and Battery Saver is still ON.
        if (batteryStillOn) {
          debugPrint(
            '[BATTERY SAVER] User cancelled - still ON',
          );

          setState(() {
            _isVerifying = false;
            _isFetchingLocation = false;
          });

          return;
        }

        // Battery Saver was turned OFF.
        debugPrint(
          '[BATTERY SAVER] OFF - fetching location',
        );

        await _fetchLocationAndContinue();

        debugPrint(
          '[TIMING] TOTAL attendance flow took '
          '${totalSw.elapsedMilliseconds}ms',
        );

        return;
      }

      // ---------------------------------------------------------
      // Battery Saver OFF
      // ---------------------------------------------------------

      debugPrint(
        '[BATTERY SAVER] OFF - fetching location',
      );

      _waitingForBatterySaverSettings = false;

      await _fetchLocationAndContinue();

      debugPrint(
        '[TIMING] TOTAL attendance flow took '
        '${totalSw.elapsedMilliseconds}ms',
      );
    } catch (e) {
      debugPrint(
        '[ATTENDANCE] Error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isVerifying = false;

        _isFetchingLocation = false;

        _showResult = true;

        _verificationSuccess = false;
      });
    }
  }

  /// Reset the current attempt.
  ///
  /// IMPORTANT:
  /// No location fetching happens here.
  /// Location starts only when Check In / Check Out is pressed.
  void _tryAgain() {
    context.read<CheckInProvider>().reset();

    context.read<CheckOutProvider>().reset();

    _waitingForBatterySaverSettings = false;

    setState(() {
      _capturedImage = null;

      _showResult = false;

      _isVerifying = false;

      _isFetchingLocation = false;

      _verificationSuccess = null;

      _locationFailureMessage = '';
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _initGeneration++;

    _controller?.dispose();

    // IMPORTANT:
    // Do NOT call context.read(), Provider.of(), etc. here.
    //
    // This avoids:
    // "Looking up a deactivated widget's ancestor is unsafe."
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkInProvider =
        context.watch<CheckInProvider>();

    final checkOutProvider =
        context.watch<CheckOutProvider>();

    final isCheckout = widget.isCheckout;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                  ),
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
                      // LOADING
                      // -------------------------------------------------

                      if (_isVerifying)
                        Column(
                          children: [
                            const CircularProgressIndicator(),

                            const SizedBox(height: 16),

                            Text(
                              _isFetchingLocation
                                  ? 'Fetching location...'
                                  : 'Verifying...',
                              style: const TextStyle(
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
                                  ? (_verificationSuccess ==
                                          true
                                      ? 'Success 🎉'
                                      : 'Check-Out Failed ❌')
                                  : checkInProvider
                                          .isAlreadyCheckedIn
                                      ? 'Already Checked In'
                                      : (_verificationSuccess ==
                                              true
                                          ? 'Success 🎉'
                                          : 'Check-In Failed ❌'),

                              message: isCheckout
                                  ? (_verificationSuccess ==
                                          true
                                      ? (checkOutProvider
                                              .response
                                              ?.message ??
                                          'Check-out successful')
                                      : (_locationFailureMessage
                                              .isNotEmpty
                                          ? _locationFailureMessage
                                          : (checkOutProvider
                                                  .errorMessage
                                                  .isNotEmpty
                                              ? checkOutProvider
                                                  .errorMessage
                                              : 'Check-out failed')))
                                  : checkInProvider
                                          .isAlreadyCheckedIn
                                      ? (checkInProvider
                                                      .response
                                                      ?.message
                                                      .isNotEmpty ==
                                                  true
                                              ? checkInProvider
                                                  .response!
                                                  .message
                                              : 'You have already checked in today.')
                                      : (_verificationSuccess ==
                                              true
                                          ? (checkInProvider
                                                  .response
                                                  ?.message ??
                                              'Check-in successful')
                                          : (_locationFailureMessage
                                                  .isNotEmpty
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
                              isSuccess:
                                  _verificationSuccess == true,
                              onTryAgain: _tryAgain,
                            ),
                          ],
                        )

                      // -------------------------------------------------
                      // INITIAL LOCATION PREFETCH (screen just opened)
                      // -------------------------------------------------

                      else if (_isFetchingInitialLocation)
                        const Column(
                          children: [
                            CircularProgressIndicator(),

                            SizedBox(height: 16),

                            Text(
                              'Fetching location...',
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
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              isCheckout
                                  ? 'Check Out'
                                  : 'Check In',
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
            // -----------------------------------------------------------

            Positioned(
              top: 12,
              left: 16,
              child: GestureDetector(
                onTap: () {
                  if (_isVerifying) {
                    return;
                  }

                  Navigator.pop(context);
                },
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
    );
  }
}