import 'package:flutter/material.dart';
import 'package:offixo/CORE/Widget/app_style.dart';

/// Gradient CTA button — size (56 h), radius (12), and gradient match original.
/// [buttonKey] is attached to the outermost SizedBox for hero transition lookup.
class OnboardingActionButton extends StatelessWidget {
  const OnboardingActionButton({
    super.key,
    required this.buttonKey,
    required this.isLastPage,
    required this.onPressed,
  });

  final GlobalKey buttonKey;
  final bool isLastPage;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: buttonKey, // ← only here; never repeated elsewhere
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppStyle.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            animationDuration: const Duration(milliseconds: 200),
          ),
          onPressed: onPressed,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: Text(
              isLastPage ? 'Login to your account' : 'Continue',
              key: ValueKey(isLastPage),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}