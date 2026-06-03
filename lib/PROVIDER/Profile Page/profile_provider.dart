import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart'
    as http;
import 'package:offixo/CONFIG/api_config.dart';
import 'package:offixo/MODEL/profile_model.dart';
import 'package:offixo/SERVICES/shared_preference_service.dart';

class ProfileProvider
    extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading =>
      _isLoading;

  ProfileModel? _profile;

  ProfileModel? get profile =>
      _profile;

  Future<void>
      fetchProfile() async {
    try {
      _isLoading = true;
      notifyListeners();

      String? token =
          await SharedPreferenceService
              .getAccessToken();

      final response =
          await http.get(
        Uri.parse(
          ApiConfig
              .memberProfileUrl,
        ),
        headers: {
          "Content-Type":
              "application/json",
          "Authorization":
              "Bearer $token",
        },
      );

      debugPrint(
        "Profile Status: ${response.statusCode}",
      );

      debugPrint(
        "Profile Response: ${response.body}",
      );

      if (response.statusCode ==
          200) {
        final data = jsonDecode(
          response.body,
        );

        _profile =
            ProfileModel
                .fromJson(data);
      }
    } catch (e) {
      debugPrint(
        "Profile Error: $e",
      );
    }

    _isLoading = false;
    notifyListeners();
  }
}