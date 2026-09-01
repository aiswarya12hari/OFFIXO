import 'package:flutter/material.dart';
import 'package:offixo/CORE/Widget/app_style.dart';
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    final horizontalPadding = AppStyle.responsiveWidth(context, 32);
    final topPadding = AppStyle.responsiveHeight(context, 75);
    final bottomExtraPadding = AppStyle.responsiveHeight(context, 16);
    final bottomFallbackPadding = AppStyle.responsiveHeight(context, 28);
    final buttonSpacing = AppStyle.responsiveHeight(context, 16);

    return ClipPath(
      clipper: OutwardUShapeClipper(screenHeight: screenHeight),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFF9F9F9),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topPadding,
            horizontalPadding,
            bottomPadding > 0
                ? bottomPadding + bottomExtraPadding
                : bottomFallbackPadding,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: OnboardingTextContent(page: pages[currentPage]),
                  ),
                ),
              ),
              OnboardingPageIndicator(
                pageCount: pages.length,
                currentPage: currentPage,
              ),
              SizedBox(height: buttonSpacing),
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
