import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:offixo/VIEW/Verification%20page/Widgets/action_button.dart';
import 'package:offixo/VIEW/Verification%20page/Widgets/camera_card.dart';
import 'package:offixo/VIEW/Verification%20page/Widgets/verification_message.dart';

class VerificationScreen extends StatefulWidget {
  final bool isSuccess;
  final String title;
  final String message;
  final String successMessage; // NEW

  const VerificationScreen({
    super.key,
    required this.isSuccess,
    required this.title,
    required this.message,
    required this.successMessage,
  });

  @override
  State<VerificationScreen> createState() =>
      _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  CameraController? _controller;

  File? _capturedImage;

  bool _isVerifying = false;
  bool _showResult = false;
  bool _verificationSuccess = false;

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();

    final frontCamera = cameras.firstWhere(
      (camera) =>
          camera.lensDirection ==
          CameraLensDirection.front,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
    );

    await _controller!.initialize();

    if (mounted) setState(() {});
  }

  Future<void> _captureAndVerify() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      setState(() => _isVerifying = true);

      final image = await _controller!.takePicture();

      setState(() {
        _capturedImage = File(image.path);
      });

      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isVerifying = false;
        _showResult = true;
        _verificationSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _showResult = true;
        _verificationSuccess = false;
      });
    }
  }

  void _tryAgain() {
    setState(() {
      _capturedImage = null;
      _showResult = false;
      _isVerifying = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,

      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                /// CAMERA
                CameraCard(
                  controller: _controller,
                  isSuccess: _verificationSuccess,
                  capturedImage: _capturedImage,
                ),

                const SizedBox(height: 30),

                /// VERIFYING
                if (_isVerifying)
                  const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        "Verifying...",
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
                        title: _verificationSuccess
                            ? "Success 🎉"
                            : "Verification Failed",
                        message: _verificationSuccess
                            ? widget.successMessage
                            : "Face verification failed",
                      ),

                      const SizedBox(height: 25),

                      ActionButtons(
                        isSuccess: _verificationSuccess,
                      ),
                    ],
                  )

                /// CHECK IN BUTTON
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
                      child: const Text(
                        "Check In",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                if (_showResult && !_verificationSuccess)
                  TextButton(
                    onPressed: _tryAgain,
                    child: const Text("Try Again"),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}