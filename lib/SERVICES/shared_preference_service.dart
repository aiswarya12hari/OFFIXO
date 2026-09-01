import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:offixo/CONFIG/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Result of checking the stored token's status.
enum TokenStatus { valid, invalid, networkError }

enum RefreshOutcome { success, invalidToken, networkError }

/// Internal result of a refresh-token attempt. Kept private since only
/// this file needs to react to it.
enum _RefreshResult { success, invalidToken, networkError }

class SharedPreferenceService {
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  /// Persists the current break state locally so it survives process
  /// death / app restarts. The break-status API does not report an
  /// active break, so this is the only source of truth we have for
  /// restoring the UI to "Resume Work" after the app is recreated.
  static const String onBreakKey = 'is_on_break';

  static Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(accessTokenKey, token);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(accessTokenKey);
  }

  static Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(refreshTokenKey, token);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(refreshTokenKey);
  }

  /// Persists whether the user is currently on a break.
  static Future<void> saveBreakState(bool isOnBreak) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onBreakKey, isOnBreak);
  }

  /// Reads the last-persisted break state. Defaults to false (not on
  /// break) if nothing has ever been saved.
  static Future<bool> getBreakState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(onBreakKey) ?? false;
  }

  static Future<void> clearData({String reason = 'unspecified'}) async {
    debugPrint('[AUTH] clearData() called — reason: $reason');
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ─── TOKEN VALIDATION ──────────────────────────────────────────────────────

  /// Returns true if user has a valid (or refreshed) token.
  // ───────────────── TOKEN VALIDATION ─────────────────

  static Future<bool> validateAccessToken() async {
    try {
      final token = await getAccessToken();

      if (token == null || token.isEmpty) {
        return false;
      }

      final response = await http.get(
        Uri.parse(ApiConfig.memberProfileUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('TOKEN VALIDATION RESPONSE: ${response.statusCode}');

      if (response.statusCode == 200) {
        return true;
      }

      if (response.statusCode == 401) {
        final refreshResult = await _refreshAccessToken();

        if (refreshResult == _RefreshResult.success) {
          // verify new token actually works
          return await validateAccessToken();
        }

        return false;
      }

      return false;
    } catch (e) {
      debugPrint('Validate Token Error: $e');
      return false;
    }
  }

  /// Same purpose as [validateAccessToken] but distinguishes between:
  /// - TokenStatus.valid        -> token confirmed with backend
  /// - TokenStatus.invalid      -> token genuinely expired/rejected (401 + refresh failed)
  /// - TokenStatus.networkError -> could not reach backend at all (no internet / timeout),
  ///                                or the backend responded with an unexpected/transient
  ///                                error (5xx, 429, etc.) that doesn't actually prove the
  ///                                token is invalid.
  ///
  /// This is needed because without this distinction, "no internet" (and, as of this fix,
  /// "backend hiccup") was being treated the same as "invalid token", which incorrectly
  /// logged users out.
  static Future<TokenStatus> checkTokenStatus() async {
    try {
      final token = await getAccessToken();

      if (token == null || token.isEmpty) {
        return TokenStatus.invalid;
      }

      final response = await http
          .get(
            Uri.parse(ApiConfig.memberProfileUrl),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('TOKEN STATUS CHECK RESPONSE: ${response.statusCode}');

      if (response.statusCode == 200) {
        return TokenStatus.valid;
      }

      if (response.statusCode == 401) {
        final refreshResult = await _refreshAccessToken();

        switch (refreshResult) {
          case _RefreshResult.success:
            return await checkTokenStatus();
          case _RefreshResult.invalidToken:
            return TokenStatus.invalid;
          case _RefreshResult.networkError:
            // Refresh attempt itself couldn't get a clean answer (timeout,
            // no internet, or a non-401 error from the refresh endpoint).
            // Don't punish the user for that — treat it as a network issue,
            // not an invalid session.
            return TokenStatus.networkError;
        }
      }

      // Any other unexpected status from the profile endpoint (500, 502,
      // 503, 429, etc.) is a backend/network issue, not proof the token is
      // invalid, so don't force a logout for it.
      return TokenStatus.networkError;
    } on SocketException catch (e) {
      debugPrint('Token Status Check - No Internet: $e');
      return TokenStatus.networkError;
    } on TimeoutException catch (e) {
      debugPrint('Token Status Check - Timeout: $e');
      return TokenStatus.networkError;
    } on http.ClientException catch (e) {
      debugPrint('Token Status Check - Connection Lost: $e');
      return TokenStatus.networkError;
    } catch (e) {
      debugPrint('Token Status Check - Unknown Error: $e');

      /// Treat unknown/low-level errors as a network error rather than
      /// logging the user out, since we can't be sure the token is actually
      /// invalid.
      return TokenStatus.networkError;
    }
  }

  static Future<RefreshOutcome> refreshAccessToken() async {
    final result = await _refreshAccessToken();

    switch (result) {
      case _RefreshResult.success:
        return RefreshOutcome.success;
      case _RefreshResult.invalidToken:
        return RefreshOutcome.invalidToken;
      case _RefreshResult.networkError:
        return RefreshOutcome.networkError;
    }
  }

  /// Only clears the saved session when the refresh endpoint explicitly
  /// rejects the refresh token with a 401 (i.e. it's genuinely expired or
  /// revoked). Any other outcome — network failure, timeout, or a
  /// transient server error (5xx, 429, etc.) — must NOT wipe the user's
  /// tokens, since that isn't proof the session is actually invalid.
  static Future<_RefreshResult> _refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        return _RefreshResult.invalidToken;
      }

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/accounts/token/refresh/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh': refreshToken}),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('REFRESH RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['access'] != null) {
          await saveAccessToken(data['access']);
        }

        if (data['refresh'] != null) {
          await saveRefreshToken(data['refresh']);
        }

        return _RefreshResult.success;
      }

      if (response.statusCode == 401) {
        // Refresh token itself was rejected by the backend — genuinely
        // expired/invalid. This is the only case that should clear the
        // saved session.
        await clearData(
          reason: '_refreshAccessToken: refresh token rejected (401)',
        );
        return _RefreshResult.invalidToken;
      }

      // Any other status (500, 502, 503, 429, etc.) is a transient
      // server-side issue, not an invalid refresh token — don't clear data.
      return _RefreshResult.networkError;
    } on SocketException catch (e) {
      debugPrint('_refreshAccessToken - No Internet: $e');
      return _RefreshResult.networkError;
    } on TimeoutException catch (e) {
      debugPrint('_refreshAccessToken - Timeout: $e');
      return _RefreshResult.networkError;
    } on http.ClientException catch (e) {
      debugPrint('_refreshAccessToken - Connection Lost: $e');
      return _RefreshResult.networkError;
    } catch (e) {
      debugPrint('_refreshAccessToken Error: $e');
      return _RefreshResult.networkError;
    }
  }

  /// USE THIS FOR ALL AUTHORIZED APIS
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Session expired');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }
}
