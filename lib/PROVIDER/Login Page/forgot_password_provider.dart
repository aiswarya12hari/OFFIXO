import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:offixo/CONFIG/api_config.dart';
import 'package:offixo/VIEW/Login%20page/login_screen.dart';
import 'package:offixo/VIEW/Login%20page/reset_password_screen.dart';

class ForgotPasswordProvider extends ChangeNotifier {
  // ================= SEND OTP STATE =================
  bool _isSendingOtp = false;

  bool get isSendingOtp => _isSendingOtp;

  String? _sendOtpError;

  String? get sendOtpError => _sendOtpError;

  void clearSendOtpError() {
    _sendOtpError = null;
    notifyListeners();
  }

  void _setSendingOtp(bool value) {
    _isSendingOtp = value;
    notifyListeners();
  }

  // ================= RESET PASSWORD STATE =================
  bool _isResetting = false;

  bool get isResetting => _isResetting;

  String? _resetError;

  String? get resetError => _resetError;

  void clearResetError() {
    _resetError = null;
    notifyListeners();
  }

  void _setResetting(bool value) {
    _isResetting = value;
    notifyListeners();
  }

  // ================= SEND OTP =================
  Future<void> sendOtp({
    required BuildContext context,
    required String email,
  }) async {
    try {
      _setSendingOtp(true);

      _sendOtpError = null;
      notifyListeners();

      final response = await http.post(
        Uri.parse(ApiConfig.forgotPasswordSendOtpUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email.trim()}),
      );

      debugPrint("Send OTP Status Code: ${response.statusCode}");

      debugPrint("Send OTP Response Body: ${response.body}");

      final data = jsonDecode(response.body);

      _setSendingOtp(false);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final message =
            data["detail"] ?? "OTP sent successfully to email.";

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(email: email.trim()),
            ),
          );
        }
      } else {
        _sendOtpError =
            data["message"] ??
            data["detail"] ??
            data["error"] ??
            "Failed to send OTP. Please try again.";

        notifyListeners();
      }
    } catch (e) {
      _setSendingOtp(false);

      debugPrint("Send OTP Error: $e");

      _sendOtpError =
          (e is SocketException || e.toString().contains('SocketException'))
          ? "No internet connection. Please check your network and try again."
          : "Something went wrong";

      notifyListeners();
    }
  }

  // ================= RESET PASSWORD =================
  Future<void> resetPassword({
    required BuildContext context,
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      _setResetting(true);

      _resetError = null;
      notifyListeners();

      final response = await http.post(
        Uri.parse(ApiConfig.forgotPasswordResetUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email.trim(),
          "otp": otp.trim(),
          "new_password": newPassword.trim(),
          "confirm_password": confirmPassword.trim(),
        }),
      );

      debugPrint("Reset Password Status Code: ${response.statusCode}");

      debugPrint("Reset Password Response Body: ${response.body}");

      final data = jsonDecode(response.body);

      _setResetting(false);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final message =
            data["detail"] ?? "Password has been reset successfully.";

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } else {
        _resetError =
            data["message"] ??
            data["detail"] ??
            data["error"] ??
            "Failed to reset password. Please try again.";

        notifyListeners();
      }
    } catch (e) {
      _setResetting(false);

      debugPrint("Reset Password Error: $e");

      _resetError =
          (e is SocketException || e.toString().contains('SocketException'))
          ? "No internet connection. Please check your network and try again."
          : "Something went wrong";

      notifyListeners();
    }
  }
}