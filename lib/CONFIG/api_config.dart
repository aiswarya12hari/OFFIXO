import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl {
    return dotenv.env['BASE_URL'] ?? '';
  }

  // MEMBER LOGIN API
  static String get memberLoginUrl {
    return '$baseUrl/api/accounts/member/login/';
  }

  // MEMBER PROFILE API
  static String get memberProfileUrl {
    return '$baseUrl/api/accounts/member/profile/';
  }

  
}