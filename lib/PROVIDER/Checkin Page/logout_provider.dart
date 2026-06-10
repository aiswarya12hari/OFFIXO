import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:offixo/CONFIG/api_config.dart';
import 'package:offixo/SERVICES/shared_preference_service.dart';

class LogoutProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> logout() async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    final accessToken = await SharedPreferenceService.getAccessToken();
    final refreshToken = await SharedPreferenceService.getRefreshToken(); // ← add this

    final response = await http.post(
      Uri.parse(ApiConfig.memberLogoutUrl),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'refresh': refreshToken, // ← send refresh token in body
      }),
    );

    debugPrint('LOGOUT RESPONSE: ${response.statusCode} ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      await SharedPreferenceService.clearData();
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = data['message'] ?? 'Logout failed';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  } catch (e) {
    debugPrint('Logout error: $e');
    await SharedPreferenceService.clearData(); // clear anyway
    _isLoading = false;
    notifyListeners();
    return true;
  }
}
}