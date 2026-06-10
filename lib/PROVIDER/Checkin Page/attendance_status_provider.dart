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

  String get checkInTime =>
      _status?.checkInTime ?? '--:--';

  String get checkOutTime =>
      _status?.checkOutTime ?? '--:--';

  String get totalHours {
    final value =
        _status?.totalWorkingHours ??
            '00:00:00';

    final parts = value.split(':');

    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }

    return value;
  }

  bool get isCheckedIn =>
      _status?.isCurrentlyActive ?? false;

  Future<void> fetchStatus() async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      final headers =
          await SharedPreferenceService
              .getAuthHeaders();

      final response = await http.get(
        Uri.parse(
          ApiConfig.todayAttendanceStatusUrl,
        ),
        headers: headers,
      );

      debugPrint(
        'TODAY ATTENDANCE RESPONSE: ${response.body}',
      );

      final responseData =
          jsonDecode(response.body);

      if (response.statusCode == 200 &&
          responseData['success'] == true) {
        _status =
            AttendanceStatusModel.fromJson(
          responseData['data'],
        );

        debugPrint(
          'Check In: ${_status?.checkInTime}',
        );

        debugPrint(
          'Check Out: ${_status?.checkOutTime}',
        );

        debugPrint(
          'Total Hours: ${_status?.totalWorkingHours}',
        );
      } else if (response.statusCode ==
          401) {
        await SharedPreferenceService
            .clearData();

        _error = 'Session expired';
      } else {
        _error =
            responseData['message'] ??
                'Failed to fetch attendance';
      }
    } catch (e) {
      _error = e.toString();

      debugPrint(
        'Attendance Status Error: $e',
      );
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