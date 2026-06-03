import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraCard extends StatelessWidget {
  final CameraController? controller;
  final bool isSuccess;
  final File? capturedImage;

  const CameraCard({
    super.key,
    required this.controller,
    required this.isSuccess,
    this.capturedImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 406,
      width: 292,

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: isSuccess
              ? const Color(0xFF22C55E)
              : const Color(0xFFEF4444),
          width: 3,
        ),
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),

        child: capturedImage != null
            ? Image.file(
                capturedImage!,
                fit: BoxFit.cover,
              )
            : controller == null || !controller!.value.isInitialized
                ? const Center(child: CircularProgressIndicator())
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scale(-1.0, 1.0),
                    child: CameraPreview(controller!),
                  ),
      ),
    );
  }
}