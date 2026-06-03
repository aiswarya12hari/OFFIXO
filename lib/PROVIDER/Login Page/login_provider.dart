import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart'
    as http;
import 'package:offixo/CONFIG/api_config.dart';
import 'package:offixo/SERVICES/shared_preference_service.dart';
import 'package:offixo/VIEW/Checkin%20page/checkinout.dart';

class LoginProvider
    extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading =>
      _isLoading;

  String? _loginError;

  String? get loginError =>
      _loginError;

  void clearError() {
    _loginError = null;
    notifyListeners();
  }

  void _setLoading(
    bool value,
  ) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> login({
    required BuildContext
        context,
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);

      _loginError = null;
      notifyListeners();

      final response =
          await http.post(
        Uri.parse(
          ApiConfig
              .memberLoginUrl,
        ),
        headers: {
          "Content-Type":
              "application/json",
        },
        body: jsonEncode({
          "email":
              email.trim(),
          "password":
              password.trim(),
        }),
      );

      debugPrint(
        "Status Code: ${response.statusCode}",
      );

      debugPrint(
        "Response Body: ${response.body}",
      );

      final data =
          jsonDecode(
        response.body,
      );

      _setLoading(false);

      if (response.statusCode >=
              200 &&
          response.statusCode <
              300) {
        String accessToken =
            data["access"] ??
                "";

        String refreshToken =
            data["refresh"] ??
                "";

        await SharedPreferenceService
            .saveAccessToken(
          accessToken,
        );

        await SharedPreferenceService
            .saveRefreshToken(
          refreshToken,
        );

        debugPrint(
          "Access Token Saved",
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const CheckinScreen(),
          ),
        );
      } else {

        // SHOW ERROR BELOW FIELD
        _loginError =
            data["message"] ??
                data["detail"] ??
                data["error"] ??
                "Invalid credentials";

        notifyListeners();
      }
    } catch (e) {
      _setLoading(false);

      debugPrint(
        "Login Error: $e",
      );

      _loginError =
          "Something went wrong";

      notifyListeners();
    }
  }
}