import 'package:flutter/material.dart';
import 'package:offixo/CORE/Widget/app_style.dart';
import 'package:offixo/MODEL/onboarding_model.dart';

class OnboardingTextContent extends StatelessWidget {
  const OnboardingTextContent({super.key, required this.page});

  final OnboardingModel page;

  @override
  Widget build(BuildContext context) {
    final titleSize = AppStyle.responsiveText(context, 25);
    final descSize = AppStyle.responsiveText(context, 13);
    final spacing = AppStyle.responsiveHeight(context, 12);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.5, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: ShaderMask(
            key: ValueKey(page.title),
            shaderCallback: (bounds) => AppStyle.primaryGradient.createShader(
              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
            ),
            child: Text(
              page.title,
              textAlign: TextAlign.center,
              style: AppStyle.textStatic(
                size: titleSize,
                weight: FontWeight.w700,
                height: 1.2,
                color: Colors.white,
              ).copyWith(letterSpacing: 0.14),
            ),
          ),
        ),

        SizedBox(height: spacing),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, animation) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-0.5, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: Text(
            page.description,
            key: ValueKey(page.description),
            textAlign: TextAlign.center,
            style: AppStyle.textStatic(
              size: descSize,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ),
      ],
    );
  }
}