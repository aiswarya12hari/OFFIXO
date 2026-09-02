import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:offixo/CONFIG/api_config.dart';
import 'package:offixo/MODEL/attendance_status_model.dart';
import 'package:offixo/SERVICES/shared_preference_service.dart';

class AttendanceStatusProvider extends ChangeNotifier {
  AttendanceStatusModel? _status;

  bool _isLoading = false;
  String _error = '';

  AttendanceStatusModel? get status => _status;

  bool get isLoading => _isLoading;

  String get error => _error;

  String get checkInTime => _status?.checkInTime ?? '--:--';

  String get checkOutTime => _status?.checkOutTime ?? '--:--';

  String get totalHours {
    final value = _status?.totalWorkingHours ?? '00:00:00';

    final parts = value.split(':');

    if (parts.length >= 2) {
      final hh = parts[0].padLeft(2, '0');
      final mm = parts[1].padLeft(2, '0');
      return '$hh:$mm';
    }

    return '00:00';
  }

  // NOTE: `is_currently_active` from the backend reflects momentary state
  // (e.g. it's false while the user is on a break), not whether the user
  // has an open session that still needs a checkout. Relying on it here
  // caused the Check In button to reappear for a user who checked in
  // earlier but hasn't checked out yet, since is_currently_active can be
  // false even mid-session.
  //
  // `checkout_time` being null (parsed as '--:--') together with a real
  // check-in time is the correct signal for "still checked in".
  bool get isCheckedIn =>
      _status != null &&
      _status!.checkInTime != '--:--' &&
      _status!.checkOutTime == '--:--';

  Future<void> fetchStatus({bool isRetry = false}) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      final headers = await SharedPreferenceService.getAuthHeaders();

      final response = await http.get(
        Uri.parse(ApiConfig.todayAttendanceStatusUrl),
        headers: headers,
      );

      debugPrint('TODAY ATTENDANCE RESPONSE: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        _status = AttendanceStatusModel.fromJson(responseData['data']);

        notifyListeners();
        debugPrint('Check In: ${_status?.checkInTime}');
        debugPrint('Check Out: ${_status?.checkOutTime}');
        debugPrint('Total Hours: ${_status?.totalWorkingHours}');
      } else if (response.statusCode == 401) {
        if (!isRetry) {
          debugPrint(
            '[AUTO-LOGOUT-DEBUG] AttendanceStatusProvider: 401 on status fetch, attempting token refresh',
          );

          final outcome = await SharedPreferenceService.refreshAccessToken();

          if (outcome == RefreshOutcome.success) {
            debugPrint(
              '[AUTO-LOGOUT-DEBUG] AttendanceStatusProvider: refresh succeeded, retrying fetchStatus',
            );
            await fetchStatus(isRetry: true);
            return;
          } else if (outcome == RefreshOutcome.invalidToken) {
            debugPrint(
              '[AUTO-LOGOUT-DEBUG] AttendanceStatusProvider: refresh token rejected — session genuinely expired',
            );
            await SharedPreferenceService.clearData(
              reason:
                  'AttendanceStatusProvider.fetchStatus: 401 + refresh token rejected',
            );
            _error = 'Session expired';
          } else {
            debugPrint(
              '[AUTO-LOGOUT-DEBUG] AttendanceStatusProvider: refresh could not be confirmed (network issue) — NOT clearing session',
            );
            _error = 'Please check your network and try again';
          }
        } else {
          debugPrint(
            '[AUTO-LOGOUT-DEBUG] AttendanceStatusProvider: still 401 after refresh+retry — clearing session',
          );
          await SharedPreferenceService.clearData(
            reason:
                'AttendanceStatusProvider.fetchStatus: 401 persisted after refresh retry',
          );
          _error = 'Session expired';
        }
      } else {
        _error = responseData['message'] ?? 'Failed to fetch attendance';
      }
    } catch (e) {
      _error = e.toString();

      debugPrint('Attendance Status Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _status = null;
    _error = '';
    notifyListeners();
  }
}
