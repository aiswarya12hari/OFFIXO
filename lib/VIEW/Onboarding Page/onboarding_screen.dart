import 'package:flutter/material.dart';
import 'package:offixo/MODEL/onboarding_model.dart';
import 'package:offixo/VIEW/Login%20page/login_screen.dart';
import 'package:offixo/VIEW/Onboarding%20Page/Widgets/bottom_sheet.dart';
import 'package:offixo/VIEW/Onboarding%20Page/Widgets/custom_transitions.dart';
import 'package:offixo/VIEW/Onboarding%20Page/Widgets/image_section.dart';

const List<OnboardingModel> _kPages = [
  OnboardingModel(
    image: 'assets/images/onboarding1.jpg',
    title: 'Manage Your Workforce Without the Confusion',
    description:
        'Track employee check-ins, monitor attendance, and manage teams from one dashboard.',
  ),
  OnboardingModel(
    image: 'assets/images/onboarding2.jpg',
    title: 'Track Every Check-In With Accuracy',
    description:
        'View real-time check-in and check-out activity, employee status, and work hours instantly.',
  ),
  OnboardingModel(
    image: 'assets/images/onboarding3.jpg',
    title: 'Simplify Payroll and Attendance Reports',
    description:
        'Automate salary calculations, monthly reports, and attendance summaries without manual work.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  final GlobalKey _buttonKey = GlobalKey();

  void _handleNext() {
    if (_currentPage == _kPages.length - 1) {
      _navigateToLogin();
    } else {
      setState(() => _currentPage++);
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      CustomTransitions.heroButtonTransition(
        page: LoginScreen(),
        buttonKey: _buttonKey,
      ),
    );
  }

  void _onSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < 0 && _currentPage < _kPages.length - 1) {
      setState(() => _currentPage++);
    } else if (velocity > 0 && _currentPage > 0) {
      setState(() => _currentPage--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomHeight = screenHeight * 0.46; // increased from 0.40

    return Scaffold(
      backgroundColor: const Color(0xFF0F1211),
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragEnd: _onSwipe,
          child: Stack(
            children: [
              // Top image area
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: screenHeight * 0.75,
                child: OnboardingImageSection(
                  pages: _kPages,
                  currentPage: _currentPage,
                ),
              ),

              // Bottom U-shape card — taller so content never overflows
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: bottomHeight,
                child: OnboardingBottomSheet(
                  pages: _kPages,
                  currentPage: _currentPage,
                  buttonKey: _buttonKey,
                  onNext: _handleNext,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}