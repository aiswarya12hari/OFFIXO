// import 'dart:io';

// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:offixo/PROVIDER/Verification%20Page/checkin_provider.dart';
// import 'package:offixo/PROVIDER/Verification%20Page/checkout_provider.dart';
// import 'package:offixo/VIEW/Verification%20page/Widgets/action_button.dart';
// import 'package:offixo/VIEW/Verification%20page/Widgets/camera_card.dart';
// import 'package:offixo/VIEW/Verification%20page/Widgets/verification_message.dart';
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

//   /// Guards against overlapping init calls (e.g. initState's call and a
//   /// lifecycle-resume retry firing close together).
//   bool _isInitializingCamera = false;

//   Future<Position?>? _locationFuture;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _initializeCamera();
//     _locationFuture = _prefetchLocation();
//   }

//   /// On a fresh install, the camera permission dialog fires from inside
//   /// `_controller!.initialize()`. Showing that system dialog pauses the app
//   /// while the initialize() future is still in flight, which can leave the
//   /// controller stuck uninitialized once the user responds and the app
//   /// resumes - nothing was previously retrying it. This observer disposes
//   /// the (possibly half-initialized) controller when the app goes inactive
//   /// and re-initializes it on resume if needed.
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.inactive ||
//         state == AppLifecycleState.paused) {
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
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

//       if (!serviceEnabled) {
//         return null;
//       }

//       LocationPermission permission = await Geolocator.checkPermission();

//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();

//         if (permission == LocationPermission.denied) {
//           return null;
//         }
//       }

//       if (permission == LocationPermission.deniedForever) {
//         return null;
//       }

//       final sw = Stopwatch()..start();

//       try {
//         final pos = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.medium,
//           timeLimit: const Duration(seconds: 6),
//         );
//         debugPrint(
//           '[TIMING] Location prefetch resolved in ${sw.elapsedMilliseconds}ms',
//         );
//         return pos;
//       } catch (_) {
//         final pos = await Geolocator.getLastKnownPosition();
//         debugPrint(
//           '[TIMING] Location prefetch fell back to last known in ${sw.elapsedMilliseconds}ms',
//         );
//         return pos;
//       }
//     } catch (e) {
//       debugPrint('Prefetch Location Error: $e');
//       return null;
//     }
//   }

//   Future<void> _initializeCamera() async {
//     if (_isInitializingCamera) return;
//     _isInitializingCamera = true;

//     try {
//       final sw = Stopwatch()..start();

//       final cameras = await availableCameras();

//       final frontCamera = cameras.firstWhere(
//         (camera) => camera.lensDirection == CameraLensDirection.front,
//       );

//       final cameraController = CameraController(
//         frontCamera,
//         ResolutionPreset.medium,
//         enableAudio: false,
//       );

//       await cameraController.initialize();

//       debugPrint('[TIMING] Camera initialized in ${sw.elapsedMilliseconds}ms');

//       if (mounted) {
//         setState(() {
//           _controller = cameraController;
//         });
//       } else {
//         cameraController.dispose();
//       }
//     } catch (e) {
//       debugPrint('Camera Error: $e');

//       /// Even on failure, rebuild so a lifecycle-resume retry (or a future
//       /// manual retry) has a chance to run instead of leaving the UI
//       /// stuck silently on the loading indicator.
//       if (mounted) {
//         setState(() {});
//       }
//     } finally {
//       _isInitializingCamera = false;
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
//         '[TIMING] Photo capture took ${captureSw.elapsedMilliseconds}ms',
//       );

//       final selfie = File(image.path);
//       final fileSizeKb = (await selfie.length()) / 1024;
//       debugPrint(
//         '[TIMING] Captured selfie size: ${fileSizeKb.toStringAsFixed(1)} KB',
//       );

//       setState(() {
//         _capturedImage = selfie;
//       });

//       final locationSw = Stopwatch()..start();
//       final position = await (_locationFuture ?? Future.value(null));
//       debugPrint(
//         '[TIMING] Awaiting location took ${locationSw.elapsedMilliseconds}ms (should be ~0 if prefetch already finished)',
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
//           '[TIMING] Check-out API call took ${apiSw.elapsedMilliseconds}ms',
//         );
//         debugPrint(
//           '[TIMING] TOTAL check-out flow took ${totalSw.elapsedMilliseconds}ms',
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
//           '[TIMING] Check-in API call took ${apiSw.elapsedMilliseconds}ms',
//         );
//         debugPrint(
//           '[TIMING] TOTAL check-in flow took ${totalSw.elapsedMilliseconds}ms',
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
//         child: SingleChildScrollView(
//           child: Center(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24),

//               child: Column(
//                 children: [
//                   const SizedBox(height: 20),

//                   CameraCard(
//                     controller: _controller,

//                     isSuccess: _verificationSuccess,

//                     capturedImage: _capturedImage,
//                   ),

//                   const SizedBox(height: 30),

//                   /// LOADER
//                   if (_isVerifying)
//                     const Column(
//                       children: [
//                         CircularProgressIndicator(),

//                         SizedBox(height: 16),

//                         Text(
//                           'Verifying...',
//                           style: TextStyle(color: Colors.white, fontSize: 18),
//                         ),
//                       ],
//                     )
//                   /// RESULT
//                   else if (_showResult)
//                     Column(
//                       children: [
//                         VerificationMessage(
//                           title: isCheckout
//                               ? (_verificationSuccess == true
//                                     ? 'Success 🎉'
//                                     : 'Check-Out Failed ❌')
//                               : checkInProvider.isAlreadyCheckedIn
//                               ? 'Already Checked In'
//                               : (_verificationSuccess == true
//                                     ? 'Success 🎉'
//                                     : 'Check-In Failed ❌'),

//                           message: isCheckout
//                               ? (_verificationSuccess == true
//                                     ? (checkOutProvider.response?.message ??
//                                           'Check-out successful')
//                                     : (checkOutProvider.errorMessage.isNotEmpty
//                                           ? checkOutProvider.errorMessage
//                                           : 'Check-out failed'))
//                               : checkInProvider.isAlreadyCheckedIn
//                               ? (checkInProvider.response?.message.isNotEmpty ==
//                                         true
//                                     ? checkInProvider.response!.message
//                                     : 'You have already checked in today.')
//                               : (_verificationSuccess == true
//                                     ? (checkInProvider.response?.message ??
//                                           'Check-in successful')
//                                     : (checkInProvider.errorMessage.isNotEmpty
//                                           ? checkInProvider.errorMessage
//                                           : 'Check-in failed')),
//                         ),
//                         const SizedBox(height: 25),

//                         ActionButtons(
//                           isSuccess: _verificationSuccess == true,

//                           onTryAgain: _tryAgain,
//                         ),
//                       ],
//                     )
//                   /// BUTTON
//                   else
//                     SizedBox(
//                       width: double.infinity,

//                       height: 52,

//                       child: ElevatedButton(
//                         onPressed: _captureAndVerify,

//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.orange,

//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(30),
//                           ),
//                         ),

//                         child: Text(
//                           isCheckout ? 'Check Out' : 'Check In',

//                           style: const TextStyle(
//                             fontSize: 18,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:offixo/PROVIDER/Verification%20Page/checkin_provider.dart';
import 'package:offixo/PROVIDER/Verification%20Page/checkout_provider.dart';
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

  bool _showResult = false;

  bool? _verificationSuccess;

  /// Tags each `_initializeCamera()` attempt.
  int _initGeneration = 0;

  Future<Position?>? _locationFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initializeLocationAndCamera();
  }

  Future<void> _initializeLocationAndCamera() async {
    // Start location permission and wait until it finishes.
    _locationFuture = _prefetchLocation();

    await _locationFuture;

    // Start camera only after location permission flow is completed.
    if (mounted) {
      await _initializeCamera();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller?.dispose();

      if (mounted) {
        setState(() {
          _controller = null;
        });
      } else {
        _controller = null;
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_controller == null || !_controller!.value.isInitialized) {
        _initializeCamera();
      }
    }
  }

  Future<Position?> _prefetchLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        debugPrint('Location service is disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission permanently denied');
        return null;
      }

      final sw = Stopwatch()..start();

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 6),
        );

        debugPrint(
          '[TIMING] Location resolved in '
          '${sw.elapsedMilliseconds}ms',
        );

        return position;
      } catch (_) {
        final position = await Geolocator.getLastKnownPosition();

        debugPrint(
          '[TIMING] Used last known location in '
          '${sw.elapsedMilliseconds}ms',
        );

        return position;
      }
    } catch (e) {
      debugPrint('Location Error: $e');
      return null;
    }
  }

  Future<void> _initializeCamera() async {
    final myGeneration = ++_initGeneration;

    try {
      /// Request camera permission FIRST and wait for the user's response
      /// to fully resolve before ever touching CameraController.
      final status = await Permission.camera.request();

      if (myGeneration != _initGeneration) return;

      if (!status.isGranted) {
        debugPrint('Camera permission not granted: $status');

        if (mounted) {
          setState(() {});
        }

        return;
      }

      final sw = Stopwatch()..start();

      final cameras = await availableCameras();

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      final cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await cameraController.initialize();

      debugPrint(
        '[TIMING] Camera initialized in '
        '${sw.elapsedMilliseconds}ms',
      );

      if (myGeneration != _initGeneration) {
        cameraController.dispose();
        return;
      }

      if (mounted) {
        setState(() {
          _controller = cameraController;
        });
      } else {
        cameraController.dispose();
      }
    } catch (e) {
      debugPrint('Camera Error: $e');

      if (myGeneration == _initGeneration && mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _captureAndVerify() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    final totalSw = Stopwatch()..start();

    try {
      setState(() {
        _isVerifying = true;
      });

      final captureSw = Stopwatch()..start();

      final image = await _controller!.takePicture();

      debugPrint(
        '[TIMING] Photo capture took '
        '${captureSw.elapsedMilliseconds}ms',
      );

      final selfie = File(image.path);

      final fileSizeKb = (await selfie.length()) / 1024;

      debugPrint(
        '[TIMING] Captured selfie size: '
        '${fileSizeKb.toStringAsFixed(1)} KB',
      );

      setState(() {
        _capturedImage = selfie;
      });

      final locationSw = Stopwatch()..start();

      // Use the same location request started in initState.
      final position = await (_locationFuture ?? Future.value(null));

      debugPrint(
        '[TIMING] Awaiting location took '
        '${locationSw.elapsedMilliseconds}ms '
        '(should be ~0 if prefetch already finished)',
      );

      final apiSw = Stopwatch()..start();

      /// CHECKOUT
      if (widget.isCheckout) {
        final provider = context.read<CheckOutProvider>();

        await provider.submitCheckOut(
          selfie: selfie,
          prefetchedPosition: position,
        );

        debugPrint(
          '[TIMING] Check-out API call took '
          '${apiSw.elapsedMilliseconds}ms',
        );

        debugPrint(
          '[TIMING] TOTAL check-out flow took '
          '${totalSw.elapsedMilliseconds}ms',
        );

        setState(() {
          _verificationSuccess = provider.isSuccess;

          _showResult = true;

          _isVerifying = false;
        });
      }
      /// CHECKIN
      else {
        final provider = context.read<CheckInProvider>();

        await provider.submitCheckIn(
          selfie: selfie,
          prefetchedPosition: position,
        );

        debugPrint(
          '[TIMING] Check-in API call took '
          '${apiSw.elapsedMilliseconds}ms',
        );

        debugPrint(
          '[TIMING] TOTAL check-in flow took '
          '${totalSw.elapsedMilliseconds}ms',
        );

        setState(() {
          _verificationSuccess = provider.isSuccess;

          _showResult = true;

          _isVerifying = false;
        });
      }
    } catch (_) {
      setState(() {
        _isVerifying = false;

        _showResult = true;

        _verificationSuccess = false;
      });
    }
  }

  void _tryAgain() {
    context.read<CheckInProvider>().reset();

    context.read<CheckOutProvider>().reset();

    setState(() {
      _capturedImage = null;

      _showResult = false;

      _isVerifying = false;

      _verificationSuccess = null;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _controller?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkInProvider = context.watch<CheckInProvider>();

    final checkOutProvider = context.watch<CheckOutProvider>();

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
                  padding: const EdgeInsets.symmetric(horizontal: 24),

                  child: Column(
                    children: [
                      const SizedBox(height: 70),

                      CameraCard(
                        controller: _controller,

                        isSuccess: _verificationSuccess,

                        capturedImage: _capturedImage,
                      ),

                      const SizedBox(height: 30),

                      /// LOADER
                      if (_isVerifying)
                        const Column(
                          children: [
                            CircularProgressIndicator(),

                            SizedBox(height: 16),

                            Text(
                              'Verifying...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        )
                      /// RESULT
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
                                        ? (checkOutProvider.response?.message ??
                                              'Check-out successful')
                                        : (checkOutProvider
                                                  .errorMessage
                                                  .isNotEmpty
                                              ? checkOutProvider.errorMessage
                                              : 'Check-out failed'))
                                  : checkInProvider.isAlreadyCheckedIn
                                  ? (checkInProvider
                                                .response
                                                ?.message
                                                .isNotEmpty ==
                                            true
                                        ? checkInProvider.response!.message
                                        : 'You have already checked in today.')
                                  : (_verificationSuccess == true
                                        ? (checkInProvider.response?.message ??
                                              'Check-in successful')
                                        : (checkInProvider
                                                  .errorMessage
                                                  .isNotEmpty
                                              ? checkInProvider.errorMessage
                                              : 'Check-in failed')),
                            ),

                            const SizedBox(height: 25),

                            ActionButtons(
                              isSuccess: _verificationSuccess == true,

                              onTryAgain: _tryAgain,
                            ),
                          ],
                        )
                      /// BUTTON
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

            /// BACK BUTTON
            Positioned(
              top: 12,

              left: 16,

              child: GestureDetector(
                onTap: () => Navigator.pop(context),

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
