import 'package:flutter/material.dart';
import 'package:offixo/CORE/Widget/app_style.dart';
import 'package:offixo/MODEL/onboarding_model.dart';

/// Title + description with the exact same slide/fade AnimatedSwitcher
/// transitions and ShaderMask gradient as the original screen.
class OnboardingTextContent extends StatelessWidget {
  const OnboardingTextContent({super.key, required this.page});

  final OnboardingModel page;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ── Gradient title — slides in from the RIGHT ─────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.5, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
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
                size: 25,
                weight: FontWeight.w700,
                height: 1.2,
                color: Colors.white, // ShaderMask overrides the colour
              ).copyWith(letterSpacing: 0.14),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Description — slides in from the LEFT ─────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, animation) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-0.5, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: Text(
            page.description,
            key: ValueKey(page.description),
            textAlign: TextAlign.center,
            style: AppStyle.textStatic(
              size: 13,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ),
      ],
    );
  }
}