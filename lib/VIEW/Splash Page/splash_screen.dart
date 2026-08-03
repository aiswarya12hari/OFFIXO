// import 'package:flutter/material.dart';
// import 'package:offixo/SERVICES/app_update_service.dart';
// import 'package:offixo/SERVICES/shared_preference_service.dart';
// import 'package:offixo/VIEW/Checkin%20page/checkinout.dart';
// import 'package:offixo/VIEW/Login%20page/login_screen.dart';
// import 'package:offixo/VIEW/Onboarding%20page/onboarding_screen.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _initializeApp();
//   }

//   Future<void> _initializeApp() async {
//     try {
//       /// Show splash for minimum 2 seconds
//       await Future.delayed(const Duration(seconds: 2));

//       /// Check Play Store update
//       await AppUpdateService.checkForUpdate();

//       /// Continue normal app flow
//       await _decideRoute();
//     } catch (e) {
//       debugPrint('Splash Error: $e');

//       await _decideRoute();
//     }
//   }

//   Future<void> _decideRoute() async {
//     final token = await SharedPreferenceService.getAccessToken();

//     if (!mounted) return;

//     /// USER ALREADY LOGGED IN
//     if (token != null && token.isNotEmpty) {
//       final isValid = await SharedPreferenceService.validateAccessToken();

//       if (!mounted) return;

//       if (isValid) {
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (_) => const CheckinScreen()),
//           (route) => false,
//         );
//       } else {
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (_) => const LoginScreen()),
//           (route) => false,
//         );
//       }
//     }
//     /// FIRST INSTALL / LOGGED OUT USER
//     else {
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (_) => const OnboardingScreen()),
//         (route) => false,
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Image.asset(
//           'assets/icon/Offixo Logo User.jpg.jpeg',
//           width: 180,
//           height: 180,
//           fit: BoxFit.contain,
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:offixo/SERVICES/app_update_service.dart';
import 'package:offixo/SERVICES/shared_preference_service.dart';
import 'package:offixo/VIEW/Checkin%20page/checkinout.dart';
import 'package:offixo/VIEW/Login%20page/login_screen.dart';
import 'package:offixo/VIEW/Onboarding%20page/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    FlutterNativeSplash.remove();
  });
  _initializeApp();
}

  Future<void> _initializeApp() async {
    try {
      /// Show splash for minimum 2 seconds
      await Future.delayed(const Duration(seconds: 2));

      /// Check Play Store update
      await AppUpdateService.checkForUpdate();

      /// Continue normal app flow
      await _decideRoute();
    } catch (e) {
      debugPrint('Splash Error: $e');

      await _decideRoute();
    }
  }

  Future<void> _decideRoute() async {
    final token = await SharedPreferenceService.getAccessToken();

    if (!mounted) return;

    /// USER ALREADY LOGGED IN (token exists locally)
    if (token != null && token.isNotEmpty) {
      final status = await SharedPreferenceService.checkTokenStatus();

      if (!mounted) return;

      if (status == TokenStatus.valid) {
        /// Token confirmed valid with backend
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const CheckinScreen()),
          (route) => false,
        );
      } else if (status == TokenStatus.networkError) {
        /// Could not reach backend (no internet / timeout) but the user
        /// still has a locally saved session — do NOT log them out.
        /// Take them to the home page and let it show a network error there.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const CheckinScreen(showNetworkError: true),
          ),
          (route) => false,
        );
      } else {
        /// status == TokenStatus.invalid -> token genuinely expired/rejected
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
    /// FIRST INSTALL / LOGGED OUT USER
    else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/icon/Offixo Logo User.jpg.jpeg',
          width: 180,
          height: 180,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
