import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:offixo/CONFIG/api_config.dart';
import 'package:offixo/MODEL/attendance_status_model.dart';
import 'package:offixo/SERVICES/shared_preference_service.dart';

/// Drives the "Total Working Hours" page. Reuses the existing
/// `ApiConfig.todayAttendanceStatusUrl` and `AttendanceStatusModel` — the
/// only difference from `AttendanceStatusProvider` is that this hits the
/// same endpoint with a caller-selected `date` query param instead of
/// always fetching "today".
class TotalWorkingHoursProvider extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  AttendanceStatusModel? _status;

  /// Top-level `status` string from the API (e.g. "COMPLETED_OR_BREAK"),
  /// kept separate from the model since AttendanceStatusModel only wraps
  /// the `data` object.
  String? _apiStatus;

  bool _isLoading = false;
  bool _hasNoData = false;
  String _error = '';

  DateTime get selectedDate => _selectedDate;

  AttendanceStatusModel? get status => _status;

  String? get apiStatus => _apiStatus;

  bool get isLoading => _isLoading;

  bool get hasNoData => _hasNoData;

  String get error => _error;

  String get formattedSelectedDate =>
      DateFormat('dd MMM yyyy').format(_selectedDate);

  Future<void> fetchForDate(DateTime date) async {
    _selectedDate = date;
    _isLoading = true;
    _error = '';
    _hasNoData = false;
    notifyListeners();

    try {
      final headers = await SharedPreferenceService.getAuthHeaders();
      final dateParam = DateFormat('yyyy-MM-dd').format(date);

      final response = await http
          .get(
            Uri.parse('${ApiConfig.todayAttendanceStatusUrl}?date=$dateParam'),
            headers: headers,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException(
                'Request timed out. Please check your internet connection and try again.',
              );
            },
          );

      debugPrint('TOTAL WORKING HOURS RESPONSE: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        _apiStatus = responseData['status'];

        final data = responseData['data'];

        if (data == null) {
          _status = null;
          _hasNoData = true;
        } else {
          _status = AttendanceStatusModel.fromJson(data);
          _hasNoData = false;
        }
      } else if (response.statusCode == 401) {
        await SharedPreferenceService.clearData();
        _error = 'Session expired';
      } else {
        _status = null;
        _apiStatus = null;
        _error = responseData['message'] ?? 'Failed to fetch attendance';
      }
    } on TimeoutException catch (e) {
      _error = e.message ?? 'Request timed out. Please try again.';
    } on SocketException {
      _error = 'No internet connection. Please check your network and try again.';
    } catch (e) {
      _error = 'Failed to fetch attendance. Please try again.';
      debugPrint('Total Working Hours Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _selectedDate = DateTime.now();
    _status = null;
    _apiStatus = null;
    _hasNoData = false;
    _error = '';
    notifyListeners();
  }
}