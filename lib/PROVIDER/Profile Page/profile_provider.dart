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

  Future<void> fetchProfile({bool isRetry = false}) async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint("========== PROFILE API ==========");
      debugPrint("PROFILE URL: ${ApiConfig.memberProfileUrl}");

      /// Get validated auth headers
      final headers = await SharedPreferenceService.getAuthHeaders();

      /// API CALL
      final response = await http.get(
        Uri.parse(ApiConfig.memberProfileUrl),
        headers: headers,
      );

      debugPrint("STATUS CODE: ${response.statusCode}");

      debugPrint("RESPONSE BODY: ${response.body}");

      /// SUCCESS
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["success"] == true) {
          _profile = ProfileModel.fromJson(data);

          debugPrint("PROFILE FETCHED SUCCESSFULLY");
        } else {
          debugPrint("PROFILE API SUCCESS FALSE");
        }
      }
      /// SESSION EXPIRED
      /// POSSIBLE SESSION EXPIRY — attempt a silent refresh before
      /// concluding the session is actually dead.
      else if (response.statusCode == 401) {
        if (!isRetry) {
          debugPrint(
            '[AUTO-LOGOUT-DEBUG] ProfileProvider: 401 on profile fetch, attempting token refresh',
          );

          final outcome = await SharedPreferenceService.refreshAccessToken();

          if (outcome == RefreshOutcome.success) {
            debugPrint(
              '[AUTO-LOGOUT-DEBUG] ProfileProvider: refresh succeeded, retrying fetchProfile',
            );
            return fetchProfile(isRetry: true);
          } else if (outcome == RefreshOutcome.invalidToken) {
            debugPrint(
              '[AUTO-LOGOUT-DEBUG] ProfileProvider: refresh token rejected — session genuinely expired',
            );
            await SharedPreferenceService.clearData(
              reason:
                  'ProfileProvider.fetchProfile: 401 + refresh token rejected',
            );
          } else {
            debugPrint(
              '[AUTO-LOGOUT-DEBUG] ProfileProvider: refresh could not be confirmed (network issue) — NOT clearing session',
            );
          }
        } else {
          debugPrint(
            '[AUTO-LOGOUT-DEBUG] ProfileProvider: still 401 after refresh+retry — clearing session',
          );
          await SharedPreferenceService.clearData(
            reason:
                'ProfileProvider.fetchProfile: 401 persisted after refresh retry',
          );
        }
      }
      /// OTHER ERROR
      else {
        debugPrint("PROFILE API FAILED");
      }
    } catch (e) {
      debugPrint("PROFILE ERROR: $e");

      /// If token validation fails
            /// getAuthHeaders() throws this when there's no token stored at all
      /// (already logged out) — nothing to refresh, just log it.
      if (e.toString().contains('Session expired')) {
        debugPrint('[AUTO-LOGOUT-DEBUG] ProfileProvider: no token present when fetchProfile ran');
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
