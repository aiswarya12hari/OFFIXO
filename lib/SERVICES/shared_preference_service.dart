import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceService {
  static const String accessTokenKey =
      'access_token';

  static const String refreshTokenKey =
      'refresh_token';

  // SAVE ACCESS TOKEN
  static Future<void> saveAccessToken(
    String token,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      accessTokenKey,
      token,
    );
  }

  // GET ACCESS TOKEN
  static Future<String?> getAccessToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      accessTokenKey,
    );
  }

  // SAVE REFRESH TOKEN
  static Future<void> saveRefreshToken(
    String token,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      refreshTokenKey,
      token,
    );
  }

  // GET REFRESH TOKEN
  static Future<String?> getRefreshToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      refreshTokenKey,
    );
  }

  // CLEAR ALL DATA (LOGOUT)
  static Future<void> clearData() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.clear();
  }
}