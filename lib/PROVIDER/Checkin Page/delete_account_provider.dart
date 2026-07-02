import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:offixo/CONFIG/api_config.dart';
import 'package:offixo/SERVICES/shared_preference_service.dart';

class DeleteAccountProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> deleteAccount() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final accessToken =
          await SharedPreferenceService.getAccessToken();

      final response = await http.delete(
        Uri.parse(ApiConfig.deleteAccountUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      debugPrint(
          'DELETE ACCOUNT RESPONSE: ${response.statusCode}');
      debugPrint(response.body);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data['success'] == true) {
        await SharedPreferenceService.clearData();

        _isLoading = false;
        notifyListeners();

        return true;
      }

      _errorMessage =
          data['message'] ?? 'Failed to delete account';

      _isLoading = false;
      notifyListeners();

      return false;
    } catch (e) {
      debugPrint('DELETE ACCOUNT ERROR: $e');

      _errorMessage = 'Something went wrong';

      _isLoading = false;
      notifyListeners();

      return false;
    }
  }
}