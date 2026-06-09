import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl {
    return dotenv.env['BASE_URL'] ?? '';
  }

  static String get memberLoginUrl {
    return '$baseUrl/api/accounts/member/login/';
  }

  static String get memberProfileUrl {
    return '$baseUrl/api/accounts/member/profile/';
  }

  static String get checkInUrl {
    return '$baseUrl/api/attendance/checkin/';
  }

  static String get checkOutUrl {
    return '$baseUrl/api/attendance/checkout/';
  }
  
}