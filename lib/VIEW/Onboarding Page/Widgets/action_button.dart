import 'package:flutter/material.dart';
import 'package:offixo/CORE/Widget/app_style.dart';

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
    final buttonHeight = AppStyle.responsiveHeight(context, 56);
    final fontSize = AppStyle.responsiveText(context, 16);
    final radius = AppStyle.responsiveWidth(context, 12);

    return SizedBox(
      key: buttonKey,
      width: double.infinity,
      height: buttonHeight,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppStyle.primaryGradient,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
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
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}