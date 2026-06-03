import 'package:flutter/material.dart';
import 'package:offixo/MODEL/onboarding_model.dart';
import 'package:offixo/VIEW/Onboarding%20Page/Widgets/action_button.dart';
import 'package:offixo/VIEW/Onboarding%20Page/Widgets/outward_u_shape_clipper.dart';
import 'package:offixo/VIEW/Onboarding%20Page/Widgets/page_indicator.dart';
import 'package:offixo/VIEW/Onboarding%20Page/Widgets/text_content.dart';


class OnboardingBottomSheet extends StatelessWidget {
  const OnboardingBottomSheet({
    super.key,
    required this.pages,
    required this.currentPage,
    required this.buttonKey,
    required this.onNext,
  });

  final List<OnboardingModel> pages;
  final int currentPage;
  final GlobalKey buttonKey;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to scale bottom padding so it never clips on small screens
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipPath(
      clipper: OutwardUShapeClipper(),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFF9F9F9),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            32,
            75, // curve compensation — unchanged
            32,
            bottomPadding > 0 ? bottomPadding + 16 : 28, // safe-area aware
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: OnboardingTextContent(page: pages[currentPage]),
              ),
              OnboardingPageIndicator(
                pageCount: pages.length,
                currentPage: currentPage,
              ),
              const SizedBox(height: 16),
              OnboardingActionButton(
                buttonKey: buttonKey,
                isLastPage: currentPage == pages.length - 1,
                onPressed: onNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}