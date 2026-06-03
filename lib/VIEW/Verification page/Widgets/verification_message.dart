import 'package:flutter/material.dart';
import 'package:offixo/CORE/Widget/app_style.dart';

class VerificationMessage extends StatelessWidget {
  final String title;
  final String message;

  const VerificationMessage({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,

          textAlign: TextAlign.center,

          style: AppStyle.jakartaText(
            context: context,

            size: 19,

            color: const Color(0xFFF5F7FA),

            weight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 0),

        Text(
          message,

          textAlign: TextAlign.center,

          style: AppStyle.jakartaText(
            context: context,

            size: 16,

            color: const Color(0xFFF5F7FA),

            weight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}
