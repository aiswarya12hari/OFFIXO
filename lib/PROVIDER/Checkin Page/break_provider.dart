// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:offixo/CONFIG/api_config.dart';
// import 'package:offixo/MODEL/break_model.dart';
// import 'package:offixo/SERVICES/shared_preference_service.dart';

// enum BreakStatus { idle, loading, success, failure }

// class BreakProvider extends ChangeNotifier {
//   BreakStatus _status = BreakStatus.idle;
//   String _errorMessage = '';
//   String _successMessage = '';
//   bool _isOnBreak = false;

//   BreakStatus get status => _status;
//   String get errorMessage => _errorMessage;
//   String get successMessage => _successMessage;
//   bool get isLoading => _status == BreakStatus.loading;
//   bool get isOnBreak => _isOnBreak;

//   Future<void> startBreak({required String reason}) async {
//     debugPrint('START BREAK CALLED');

//     _status = BreakStatus.loading;
//     _errorMessage = '';
//     _successMessage = '';
//     notifyListeners();

//     try {
//       final headers = await SharedPreferenceService.getAuthHeaders();
//       headers['Content-Type'] = 'application/json';

//       final response = await http.post(
//         Uri.parse(ApiConfig.memberBreakUrl),
//         headers: headers,
//         body: jsonEncode({"reason": reason}),
//       );

//       final responseData = jsonDecode(response.body);

//       debugPrint('BREAK START RESPONSE: ${response.body}');
//       debugPrint(
//         'STATUS=${response.statusCode}, SUCCESS=${responseData['success']}',
//       );

//       // ✅ Accept any successful response from backend
//       if (responseData['success'] == true) {
//         final breakResponse = BreakResponse.fromJson(responseData);

//         _successMessage = breakResponse.message;
//         _status = BreakStatus.success;
//         _isOnBreak = true;

//         debugPrint('BREAK STATUS CHANGED => $_isOnBreak');
//       } else {
//         _errorMessage = responseData['message'] ?? 'Failed to start break';

//         _status = BreakStatus.failure;

//         final msg = (responseData['message'] ?? '').toString().toLowerCase();

//         // Sync UI if backend says already on break
//         if (msg.contains('already on a break')) {
//           _isOnBreak = true;
//         }
//       }
//     } catch (e) {
//       _errorMessage = e.toString().replaceFirst('Exception: ', '');

//       _status = BreakStatus.failure;
//     }

//     notifyListeners();
//   }

//   Future<void> endBreak() async {
//     debugPrint('END BREAK CALLED');

//     _status = BreakStatus.loading;
//     _errorMessage = '';
//     _successMessage = '';
//     notifyListeners();

//     try {
//       final headers = await SharedPreferenceService.getAuthHeaders();
//       headers['Content-Type'] = 'application/json';

//       final response = await http.patch(
//         Uri.parse(ApiConfig.memberBreakUrl),
//         headers: headers,
//       );

//       final responseData = jsonDecode(response.body);

//       debugPrint('BREAK END RESPONSE: ${response.body}');

//       if (responseData['success'] == true) {
//         _successMessage =
//             responseData['message'] ?? 'Work resumed successfully.';

//         _status = BreakStatus.success;
//         _isOnBreak = false;

//         debugPrint('BREAK STATUS CHANGED => $_isOnBreak');
//       } else {
//         _errorMessage = responseData['message'] ?? 'Failed to end break';

//         _status = BreakStatus.failure;
//       }
//     } catch (e) {
//       _errorMessage = e.toString().replaceFirst('Exception: ', '');

//       _status = BreakStatus.failure;
//     }

//     notifyListeners();
//   }

//   void setBreakStatus(bool value) {
//     _isOnBreak = value;
//     notifyListeners();
//   }

//   void reset() {
//     debugPrint('BREAK RESET CALLED');

//     _status = BreakStatus.idle;
//     _errorMessage = '';
//     _successMessage = '';

//     notifyListeners();
//   }

//   void resetAll() {
//     debugPrint('BREAK RESET ALL CALLED');

//     _status = BreakStatus.idle;
//     _errorMessage = '';
//     _successMessage = '';
//     _isOnBreak = false;

//     notifyListeners();
//   }
// }


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:offixo/CONFIG/api_config.dart';
import 'package:offixo/MODEL/break_model.dart';
import 'package:offixo/SERVICES/shared_preference_service.dart';

enum BreakStatus { idle, loading, success, failure }

class BreakProvider extends ChangeNotifier {
  BreakStatus _status = BreakStatus.idle;
  String _errorMessage = '';
  String _successMessage = '';
  bool _isOnBreak = false;

  BreakStatus get status => _status;
  String get errorMessage => _errorMessage;
  String get successMessage => _successMessage;
  bool get isLoading => _status == BreakStatus.loading;
  bool get isOnBreak => _isOnBreak;

  /// Restores the last-known break state from local storage. The
  /// attendance-status API does not report an active break, so this is
  /// what keeps the "Resume Work" state from silently reverting when the
  /// app process is recreated (backgrounding for a few minutes, hot
  /// restart, etc.) while a break is active. Call this on screen
  /// load/refresh, before relying on isOnBreak for the UI.
  Future<void> hydrate() async {
    final persisted = await SharedPreferenceService.getBreakState();

    if (persisted != _isOnBreak) {
      _isOnBreak = persisted;
      notifyListeners();
    }
  }

  Future<void> startBreak({required String reason}) async {
    debugPrint('START BREAK CALLED');

    _status = BreakStatus.loading;
    _errorMessage = '';
    _successMessage = '';
    notifyListeners();

    try {
      final headers = await SharedPreferenceService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final response = await http.post(
        Uri.parse(ApiConfig.memberBreakUrl),
        headers: headers,
        body: jsonEncode({"reason": reason}),
      );

      final responseData = jsonDecode(response.body);

      debugPrint('BREAK START RESPONSE: ${response.body}');
      debugPrint(
        'STATUS=${response.statusCode}, SUCCESS=${responseData['success']}',
      );

      // ✅ Accept any successful response from backend
      if (responseData['success'] == true) {
        final breakResponse = BreakResponse.fromJson(responseData);

        _successMessage = breakResponse.message;
        _status = BreakStatus.success;
        _isOnBreak = true;

        await SharedPreferenceService.saveBreakState(true);

        debugPrint('BREAK STATUS CHANGED => $_isOnBreak');
      } else {
        _errorMessage = responseData['message'] ?? 'Failed to start break';

        _status = BreakStatus.failure;

        final msg = (responseData['message'] ?? '').toString().toLowerCase();

        // Sync UI if backend says already on break
        if (msg.contains('already on a break')) {
          _isOnBreak = true;
          await SharedPreferenceService.saveBreakState(true);
        }
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');

      _status = BreakStatus.failure;
    }

    notifyListeners();
  }

  Future<void> endBreak() async {
    debugPrint('END BREAK CALLED');

    _status = BreakStatus.loading;
    _errorMessage = '';
    _successMessage = '';
    notifyListeners();

    try {
      final headers = await SharedPreferenceService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final response = await http.patch(
        Uri.parse(ApiConfig.memberBreakUrl),
        headers: headers,
      );

      final responseData = jsonDecode(response.body);

      debugPrint('BREAK END RESPONSE: ${response.body}');

      if (responseData['success'] == true) {
        _successMessage =
            responseData['message'] ?? 'Work resumed successfully.';

        _status = BreakStatus.success;
        _isOnBreak = false;

        await SharedPreferenceService.saveBreakState(false);

        debugPrint('BREAK STATUS CHANGED => $_isOnBreak');
      } else {
        _errorMessage = responseData['message'] ?? 'Failed to end break';

        _status = BreakStatus.failure;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');

      _status = BreakStatus.failure;
    }

    notifyListeners();
  }

  void setBreakStatus(bool value) {
    _isOnBreak = value;
    SharedPreferenceService.saveBreakState(value);
    notifyListeners();
  }

  void reset() {
    debugPrint('BREAK RESET CALLED');

    _status = BreakStatus.idle;
    _errorMessage = '';
    _successMessage = '';

    notifyListeners();
  }

  void resetAll() {
    debugPrint('BREAK RESET ALL CALLED');

    _status = BreakStatus.idle;
    _errorMessage = '';
    _successMessage = '';
    _isOnBreak = false;

    SharedPreferenceService.saveBreakState(false);

    notifyListeners();
  }
}