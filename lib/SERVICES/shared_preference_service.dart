import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:offixo/CONFIG/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceService {
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

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

  static Future<void> clearData() async {
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

    debugPrint(
      'TOKEN VALIDATION RESPONSE: ${response.statusCode}',
    );

    if (response.statusCode == 200) {
      return true;
    }

    if (response.statusCode == 401) {
      final refreshed = await _refreshAccessToken();

      if (refreshed) {
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

static Future<bool> _refreshAccessToken() async {
  try {
    final refreshToken = await getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/accounts/token/refresh/',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'refresh': refreshToken,
      }),
    );

    debugPrint(
      'REFRESH RESPONSE: ${response.body}',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['access'] != null) {
        await saveAccessToken(
          data['access'],
        );
      }

      if (data['refresh'] != null) {
        await saveRefreshToken(
          data['refresh'],
        );
      }

      return true;
    }

    await clearData();
    return false;
  } catch (e) {
    debugPrint(
      '_refreshAccessToken Error: $e',
    );

    return false;
  }
}

/// USE THIS FOR ALL AUTHORIZED APIS
static Future<Map<String, String>>
    getAuthHeaders() async {

  final token =
      await getAccessToken();

  if (token == null ||
      token.isEmpty) {
    throw Exception(
      'Session expired',
    );
  }

  return {
    'Authorization':
        'Bearer $token',
    'Content-Type':
        'application/json',
  };
}
}