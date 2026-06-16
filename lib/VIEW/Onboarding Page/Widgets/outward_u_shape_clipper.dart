import 'package:flutter/material.dart';

class OutwardUShapeClipper extends CustomClipper<Path> {
  const OutwardUShapeClipper({required this.screenHeight});

  final double screenHeight;

  @override
  Path getClip(Size size) {
    // Scale the curve rise and peak relative to screen height.
    // On 812px (design base): rise = 40, peak = 120
    final rise = screenHeight * (40 / 812);
    final peak = screenHeight * (120 / 812);

    final path = Path();
    path.moveTo(0, rise);
    path.quadraticBezierTo(size.width / 2, peak, size.width, rise);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(OutwardUShapeClipper oldClipper) =>
      oldClipper.screenHeight != screenHeight;
}