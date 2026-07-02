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
  
  static String get memberLogoutUrl {
    return '$baseUrl/api/accounts/member/logout/';
  }

  static String get leaveRequestUrl =>
      '$baseUrl/api/leave/member/request/';

  static String get todayAttendanceStatusUrl {
  return '$baseUrl/api/member/attendance/today-status/';
}

static String get leaveBalanceUrl =>
    '$baseUrl/api/leave/member/balances/';

  static String get deleteAccountUrl {
  return '$baseUrl/api/accounts/member/delete-account/';
}

static String get memberBreakUrl {
  return '$baseUrl/api/attendance/member-break/';
}

static String get leaveTypesDropdownUrl =>
    '$baseUrl/api/leave/types/dropdown/';
}