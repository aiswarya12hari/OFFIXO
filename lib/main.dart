import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:offixo/PROVIDER/Login%20Page/login_provider.dart';
import 'package:offixo/PROVIDER/Profile%20Page/profile_provider.dart';
import 'package:offixo/PROVIDER/Verification%20Page/checkin_provider.dart';
import 'package:offixo/PROVIDER/Verification%20Page/checkout_provider.dart';
import 'package:provider/provider.dart';
import 'package:offixo/VIEW/Login%20page/login_screen.dart';
import 'package:offixo/VIEW/Onboarding%20page/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  runApp(const OffixoApp());
}

class OffixoApp extends StatelessWidget {
  const OffixoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => CheckInProvider()),
        ChangeNotifierProvider(create: (_) => CheckOutProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: OnboardingScreen(),
        routes: {'/login': (context) => LoginScreen()},
      ),
    );
  }
}
