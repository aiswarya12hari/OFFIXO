import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:offixo/CONFIG/api_config.dart';
import 'package:offixo/MODEL/attendance_type_model.dart';
import 'package:offixo/SERVICES/shared_preference_service.dart';

class AttendanceTypeProvider extends ChangeNotifier {
  AttendanceTypeModel? _attendanceType;

  bool _isLoading = false;
  String _error = '';

  AttendanceTypeModel? get attendanceType => _attendanceType;

  bool get isLoading => _isLoading;

  String get error => _error;

  /// Defaults to FACE_BASED (current app behaviour) until the API responds,
  /// so the UI never accidentally shows the location-only flow before we
  /// actually know the organization's configured type.
  bool get isLocationBased => _attendanceType?.isLocationBased ?? false;

  bool get isFaceBased => _attendanceType?.isFaceBased ?? true;

  bool get hasLoaded => _attendanceType != null;

  Future<void> fetchAttendanceType() async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      final headers = await SharedPreferenceService.getAuthHeaders();

      final response = await http.get(
        Uri.parse(ApiConfig.attendanceTypeUrl),
        headers: headers,
      );

      debugPrint('ATTENDANCE TYPE RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _attendanceType = AttendanceTypeModel.fromJson(data);
      } else if (response.statusCode == 401) {
        await SharedPreferenceService.clearData();

        _error = 'Session expired';
      } else {
        _error = 'Failed to fetch attendance type';
      }
    } catch (e) {
      _error = e.toString();

      debugPrint('Attendance Type Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _attendanceType = null;
    _error = '';
    notifyListeners();
  }
}