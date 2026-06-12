import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:offixo/PROVIDER/Verification%20Page/checkin_provider.dart';
import 'package:offixo/PROVIDER/Verification%20Page/checkout_provider.dart';
import 'package:offixo/VIEW/Verification%20page/Widgets/action_button.dart';
import 'package:offixo/VIEW/Verification%20page/Widgets/camera_card.dart';
import 'package:offixo/VIEW/Verification%20page/Widgets/verification_message.dart';
import 'package:provider/provider.dart';

class VerificationScreen extends StatefulWidget {
  final bool isCheckout;

  const VerificationScreen({super.key, this.isCheckout = false});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  CameraController? _controller;

  File? _capturedImage;

  bool _isVerifying = false;

  bool _showResult = false;

  bool? _verificationSuccess;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      _controller = CameraController(frontCamera, ResolutionPreset.medium, enableAudio: false,);

      await _controller!.initialize();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Camera Error: $e');
    }
  }

  Future<void> _captureAndVerify() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      setState(() {
        _isVerifying = true;
      });

      final image = await _controller!.takePicture();

      final selfie = File(image.path);

      setState(() {
        _capturedImage = selfie;
      });

      /// CHECKOUT
      if (widget.isCheckout) {
        final provider = context.read<CheckOutProvider>();

        await provider.submitCheckOut(selfie: selfie);

        setState(() {
          _verificationSuccess = provider.isSuccess;

          _showResult = true;

          _isVerifying = false;
        });
      }
      
      /// CHECKIN
      else {
        final provider = context.read<CheckInProvider>();

        await provider.submitCheckIn(selfie: selfie);

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
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),

              child: Column(
                children: [
                  const SizedBox(height: 20),

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
                          style: TextStyle(color: Colors.white, fontSize: 18),
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
                                    : (checkOutProvider.errorMessage.isNotEmpty
                                          ? checkOutProvider.errorMessage
                                          : 'Check-out failed'))
                              : checkInProvider.isAlreadyCheckedIn
                              ? (checkInProvider.response?.message.isNotEmpty ==
                                        true
                                    ? checkInProvider.response!.message
                                    : 'You have already checked in today.')
                              : (_verificationSuccess == true
                                    ? (checkInProvider.response?.message ??
                                          'Check-in successful')
                                    : (checkInProvider.errorMessage.isNotEmpty
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
                      width: double.infinity,

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
      ),
    );
  }
}
