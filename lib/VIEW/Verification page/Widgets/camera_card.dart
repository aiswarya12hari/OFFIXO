import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraCard extends StatelessWidget {
  final CameraController? controller;

  /// null = not verified yet
  /// true = success
  /// false = failed
  final bool? isSuccess;

  final File? capturedImage;

  const CameraCard({
    super.key,
    required this.controller,
    required this.isSuccess,
    this.capturedImage,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor;

    /// Neutral border before verification
    if (isSuccess == null) {
      borderColor = Colors.white24;
    }

    /// Success
    else if (isSuccess == true) {
      borderColor = const Color(0xFF22C55E);
    }

    /// Failure
    else {
      borderColor = const Color(0xFFEF4444);
    }

    return Container(
      height: 406,
      width: 292,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: borderColor,
          width: 3,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: capturedImage != null

            /// Captured selfie → flip once
            ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(3.14159),
                child: Image.file(
                  capturedImage!,
                  fit: BoxFit.cover,
                ),
              )

            /// Loading
            : controller == null ||
                    !controller!.value.isInitialized
                ? const Center(
                    child: CircularProgressIndicator(),
                  )

                /// Live camera preview → NO flip
                : CameraPreview(controller!),
      ),
    );
  }
}