import 'package:flutter/material.dart';
import 'package:offixo/MODEL/onboarding_model.dart';

/// Stacked fading images — identical fade + gradient overlay to original.
class OnboardingImageSection extends StatelessWidget {
  const OnboardingImageSection({
    super.key,
    required this.pages,
    required this.currentPage,
  });

  final List<OnboardingModel> pages;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(
        pages.length,
        (index) => AnimatedOpacity(
          duration: const Duration(milliseconds: 600),
          opacity: currentPage == index ? 1.0 : 0.0,
          curve: Curves.easeInOut,
          child: Stack(
            children: [
              // Full-bleed image
              Image.asset(
                pages[index].image,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              // Bottom fade-to-white gradient (same as original)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 150,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        const Color(0xFFF9F9F9).withOpacity(0.9),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}