import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:offixo/CONFIG/api_config.dart';
import 'package:offixo/MODEL/profile_model.dart';
import 'package:offixo/SERVICES/shared_preference_service.dart';

class ProfileProvider extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  ProfileModel? _profile;

  ProfileModel? get profile => _profile;

  Future<void> fetchProfile() async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint("========== PROFILE API ==========");
      debugPrint(
        "PROFILE URL: ${ApiConfig.memberProfileUrl}",
      );

      /// Get validated auth headers
      final headers =
          await SharedPreferenceService.getAuthHeaders();

      /// API CALL
      final response = await http.get(
        Uri.parse(
          ApiConfig.memberProfileUrl,
        ),
        headers: headers,
      );

      debugPrint(
        "STATUS CODE: ${response.statusCode}",
      );

      debugPrint(
        "RESPONSE BODY: ${response.body}",
      );

      /// SUCCESS
      if (response.statusCode == 200) {
        final data =
            jsonDecode(response.body);

        if (data["success"] == true) {
          _profile =
              ProfileModel.fromJson(
            data,
          );

          debugPrint(
            "PROFILE FETCHED SUCCESSFULLY",
          );
        } else {
          debugPrint(
            "PROFILE API SUCCESS FALSE",
          );
        }
      }

      /// SESSION EXPIRED
      else if (response.statusCode == 401) {
        debugPrint(
          "SESSION EXPIRED",
        );

        await SharedPreferenceService.clearData();
      }

      /// OTHER ERROR
      else {
        debugPrint(
          "PROFILE API FAILED",
        );
      }
    } catch (e) {
      debugPrint(
        "PROFILE ERROR: $e",
      );

      /// If token validation fails
      if (e.toString().contains('Session expired')) {
        await SharedPreferenceService.clearData();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearProfile() {
    _profile = null;
    notifyListeners();
  }
}