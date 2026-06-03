import 'package:flutter/material.dart';
import 'package:offixo/CORE/Widget/app_style.dart';

/// Animated dot/pill indicator — uses AppStyle.primaryGradient exactly.
class OnboardingPageIndicator extends StatelessWidget {
  const OnboardingPageIndicator({
    super.key,
    required this.pageCount,
    required this.currentPage,
  });

  final int pageCount;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: currentPage == index ? 24 : 8,
          decoration: BoxDecoration(
            gradient: currentPage == index
                ? AppStyle.primaryGradient
                : LinearGradient(colors: [
                    Colors.grey.shade400,
                    Colors.grey.shade400,
                  ]),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}