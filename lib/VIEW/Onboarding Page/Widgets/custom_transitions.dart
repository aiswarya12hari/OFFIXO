import 'dart:math';
import 'package:flutter/material.dart';
import 'package:offixo/CORE/Widget/app_style.dart'; // ← match your actual path

class CustomTransitions {
  // Hero-like button expand transition
  static PageRouteBuilder heroButtonTransition({
    required Widget page,
    required GlobalKey buttonKey,
    LinearGradient buttonGradient = AppStyle.primaryGradient,
    Duration duration = const Duration(milliseconds: 1200),
  }) {
    // CAPTURE BUTTON DATA BEFORE NAVIGATION STARTS
    final buttonContext = buttonKey.currentContext;
    Offset? buttonPosition;
    Size? buttonSize;

    if (buttonContext != null) {
      final buttonBox = buttonContext.findRenderObject() as RenderBox?;
      if (buttonBox != null) {
        buttonPosition = buttonBox.localToGlobal(Offset.zero);
        buttonSize = buttonBox.size;
      }
    }

    return PageRouteBuilder(
      transitionDuration: duration,
      reverseTransitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (buttonPosition == null || buttonSize == null) {
          return _fallbackTransition(animation, child);
        }
        return _buildHeroTransition(
          context, animation, child,
          buttonPosition, buttonSize, buttonGradient,
        );
      },
    );
  }

  // Slide fade transition
  static PageRouteBuilder slideFadeTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 800),
    Offset beginOffset = const Offset(0.0, 0.3),
    Curve curve = Curves.easeOutCubic,
  }) {
    return PageRouteBuilder(
      transitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return _buildSlideFadeTransition(animation, child, beginOffset, curve);
      },
    );
  }

  // Hero transition builder (uses pre-captured data)
  static Widget _buildHeroTransition(
    BuildContext context,
    Animation<double> animation,
    Widget child,
    Offset buttonPosition,
    Size buttonSize,
    LinearGradient buttonGradient,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
    );

    final maxScale =
        max(
          screenSize.width / buttonSize.width,
          screenSize.height / buttonSize.height,
        ) * 1.5;

    final scaleAnimation = Tween<double>(
      begin: 1.0,
      end: maxScale,
    ).animate(curvedAnimation);

    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    final bgFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    return Stack(
      children: [
        // Background overlay
        AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            return Container(
              color: buttonGradient.colors.first
                  .withOpacity(bgFadeAnimation.value),
            );
          },
        ),

        // Expanding button effect
        Positioned(
          left: buttonPosition.dx,
          top: buttonPosition.dy,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              return Transform.scale(
                scale: scaleAnimation.value,
                alignment: Alignment.center,
                child: Opacity(
                  opacity: Tween<double>(begin: 1.0, end: 0.0)
                      .animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: const Interval(
                              0.7, 1.0, curve: Curves.easeIn),
                        ),
                      )
                      .value,
                  child: Container(
                    width: buttonSize.width,
                    height: buttonSize.height,
                    decoration: BoxDecoration(
                      gradient: buttonGradient,
                      borderRadius: BorderRadius.circular(
                        Tween<double>(begin: 12.0, end: 0.0)
                            .animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: const Interval(
                                    0.0, 0.4, curve: Curves.easeInOut),
                              ),
                            )
                            .value,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Page fading in
        FadeTransition(opacity: fadeAnimation, child: child),
      ],
    );
  }

  // Slide fade transition builder
  static Widget _buildSlideFadeTransition(
    Animation<double> animation,
    Widget child,
    Offset beginOffset,
    Curve curve,
  ) {
    final slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: curve));

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(opacity: fadeAnimation, child: child),
    );
  }

  // Fallback transition
  static Widget _fallbackTransition(
      Animation<double> animation, Widget child) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      ),
      child: child,
    );
  }
}