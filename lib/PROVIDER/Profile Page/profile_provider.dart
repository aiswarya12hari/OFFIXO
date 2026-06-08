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

      /// GET TOKEN
      String? token =
          await SharedPreferenceService.getAccessToken();

      debugPrint("========== PROFILE API ==========");
      debugPrint("TOKEN: $token");
      debugPrint(
        "PROFILE URL: ${ApiConfig.memberProfileUrl}",
      );

      /// TOKEN NULL CHECK
      if (token == null || token.isEmpty) {
        debugPrint("ACCESS TOKEN IS NULL");
        _isLoading = false;
        notifyListeners();
        return;
      }

      /// API CALL
      final response = await http.get(
        Uri.parse(
          ApiConfig.memberProfileUrl,
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
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

      /// UNAUTHORIZED
      else if (response.statusCode ==
          401) {
        debugPrint(
          "401 UNAUTHORIZED - INVALID TOKEN",
        );
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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}