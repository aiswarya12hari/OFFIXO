import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:offixo/CONFIG/api_config.dart';
import 'package:offixo/SERVICES/shared_preference_service.dart';

class AttendanceStatus {
  final bool checkedIn;
  final bool hasCheckedOutToday;
  final String checkinTime;
  final String currentDuration;
  final String totalWorkingHours;

  AttendanceStatus({
    required this.checkedIn,
    required this.hasCheckedOutToday,
    required this.checkinTime,
    required this.currentDuration,
    required this.totalWorkingHours,
  });

  factory AttendanceStatus.fromJson(Map<String, dynamic> json) {
    return AttendanceStatus(
      checkedIn: json['checked_in'] ?? false,
      hasCheckedOutToday: json['has_checked_out_today'] ?? false,
      checkinTime: json['checkin_time'] ?? '',
      currentDuration: json['current_duration'] ?? '0:00:00',
      totalWorkingHours: json['total_working_hours_today'] ?? '00:00:00',
    );
  }
}

class AttendanceStatusProvider extends ChangeNotifier {
  AttendanceStatus? _status;
  bool _isLoading = false;
  String _error = '';

  // Cache these so they survive after checkout
  String _cachedCheckinTime = '';
  String _cachedCheckoutTime = '';
  String _cachedTotalHours = '';

  AttendanceStatus? get status => _status;
  bool get isLoading => _isLoading;
  String get error => _error;

  // ─── Private helpers ───────────────────────────────────────────────

  /// Formats an ISO datetime string → "7:04 AM"
  String _formatIsoTime(String iso) {
    if (iso.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (_) {
      return '--:--';
    }
  }

  /// Computes checkout time = checkin ISO + duration "H:MM:SS" → "7:14 AM"
  String _computeCheckoutTime(String checkinIso, String durationStr) {
    if (checkinIso.isEmpty || durationStr.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(checkinIso).toLocal();
      final parts = durationStr.split(':');
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final seconds = int.parse(parts[2]);
      final checkout = dt.add(
        Duration(hours: hours, minutes: minutes, seconds: seconds),
      );
      final hour = checkout.hour % 12 == 0 ? 12 : checkout.hour % 12;
      final minute = checkout.minute.toString().padLeft(2, '0');
      final period = checkout.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (_) {
      return '--:--';
    }
  }

  /// Trims seconds from "HH:MM:SS" → "HH:MM"
  String _trimSeconds(String duration) {
    if (duration.isEmpty) return '00:00';
    final parts = duration.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return duration;
  }

  // ─── Public getters ────────────────────────────────────────────────

  String get checkInTimeFormatted {
    if (_cachedCheckinTime.isNotEmpty) return _cachedCheckinTime;
    return _formatIsoTime(_status?.checkinTime ?? '');
  }

  String get totalHoursFormatted {
    if (_cachedTotalHours.isNotEmpty) return _cachedTotalHours;
    return _trimSeconds(_status?.totalWorkingHours ?? '');
  }

  String get checkOutTimeFormatted {
    if (_cachedCheckoutTime.isNotEmpty) return _cachedCheckoutTime;
    return '--:--';
  }

  bool get isCheckedIn => _status?.checkedIn ?? false;

  // ─── API call ──────────────────────────────────────────────────────

  Future<void> fetchStatus() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final headers = await SharedPreferenceService.getAuthHeaders();

      final response = await http.get(
        Uri.parse(ApiConfig.checkOutUrl),
        headers: headers,
      );

      debugPrint('AttendanceStatus response: ${response.body}');

      final json = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _status = AttendanceStatus.fromJson(json);

        // Cache checkin time while API still returns it (before checkout)
        if (_status!.checkinTime.isNotEmpty) {
          _cachedCheckinTime = _formatIsoTime(_status!.checkinTime);
        }

        // Clear checkout cache on a fresh session (new day / new checkin)
        if (!_status!.hasCheckedOutToday) {
          _cachedCheckoutTime = '';
          _cachedTotalHours = '';
        } else if (response.statusCode == 401) {
          await SharedPreferenceService.clearData();

          _error = 'Session expired';

          notifyListeners();
        }
      } else {
        _error = json['message'] ?? 'Failed to fetch status';
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('AttendanceStatusProvider error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Called after successful POST checkout ─────────────────────────

  void applyCheckoutResult({
    required String totalWorkingHours,
    required String currentSessionHours,
  }) {
    // Total hours from POST response
    _cachedTotalHours = _trimSeconds(totalWorkingHours);

    // Checkout time = checkin time + total working hours
    _cachedCheckoutTime = _computeCheckoutTime(
      _status?.checkinTime ?? '',
      totalWorkingHours,
    );

    debugPrint('Cached checkout time: $_cachedCheckoutTime');
    debugPrint('Cached total hours: $_cachedTotalHours');

    notifyListeners();
  }

  // ─── Reset ─────────────────────────────────────────────────────────

  void reset() {
    _status = null;
    _error = '';
    _cachedCheckinTime = '';
    _cachedCheckoutTime = '';
    _cachedTotalHours = '';
    notifyListeners();
  }
}
