import 'package:flutter/material.dart';
import 'package:offixo/VIEW/Checkin%20page/checkinout.dart';

class LoginController {
  void login({
    required BuildContext context,
    required String email,
    required String password,
  }) {

    // SUCCESS LOGIN
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const CheckinScreen(),
      ),
    );
  }
}