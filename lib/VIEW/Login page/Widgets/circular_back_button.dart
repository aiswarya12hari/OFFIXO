import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:offixo/CORE/Widget/app_style.dart';

class CircularBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const CircularBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ??
          () {
            SystemNavigator.pop();
          },
      child: Container(
        height: 52,
        width: 52,
        decoration: const BoxDecoration(
          color: AppStyle.primaryColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}