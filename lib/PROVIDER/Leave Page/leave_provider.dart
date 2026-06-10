import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:offixo/CONFIG/api_config.dart';
import 'package:offixo/MODEL/leave_model.dart';
import 'package:offixo/SERVICES/shared_preference_service.dart';

class LeaveProvider extends ChangeNotifier {
  // ── GET state ──────────────────────────────────────────────────────────────
  bool _isFetching = false;
  List<LeaveModel> _leaves = [];
  String? _fetchError;

  bool get isFetching => _isFetching;
  List<LeaveModel> get leaves => _leaves;
  String? get fetchError => _fetchError;

  // ── POST state ─────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;
  LeaveModel? _leaveResponse;

  bool get isLoading => _isLoading;
  bool get isSuccess => _isSuccess;
  String? get errorMessage => _errorMessage;
  LeaveModel? get leaveResponse => _leaveResponse;

  // ── GET: fetch all applied leaves ──────────────────────────────────────────
  Future<void> fetchLeaves() async {
    _isFetching = true;
    _fetchError = null;
    notifyListeners();

    try {
      final headers = await SharedPreferenceService.getAuthHeaders();

      final response = await http.get(
        Uri.parse(ApiConfig.leaveRequestUrl),
        headers: headers,
      );

      debugPrint('LEAVE FETCH STATUS: ${response.statusCode}');
      debugPrint('LEAVE FETCH BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list =
            data is List ? data : (data['results'] ?? []);
        _leaves = list.map((e) => LeaveModel.fromJson(e)).toList();
      } else {
        _fetchError = 'Failed to load leave history';
      }
    } catch (e) {
      _fetchError = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      debugPrint('LEAVE FETCH ERROR: $e');
    }

    _isFetching = false;
    notifyListeners();
  }

  // ── POST: submit leave request ─────────────────────────────────────────────
  Future<void> submitLeaveRequest({
    required int leaveType,
    required String fromDate,
    required String toDate,
    required String session,
    required String reason,
  }) async {
    _isLoading = true;
    _isSuccess = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = await SharedPreferenceService.getAuthHeaders();

      final payload = jsonEncode({
        'leave_type': leaveType,
        'from_date': fromDate,
        'to_date': toDate,
        'session': session,
        'reason': reason,
      });

      debugPrint('LEAVE REQUEST PAYLOAD: $payload');

      final response = await http.post(
        Uri.parse(ApiConfig.leaveRequestUrl),
        headers: headers,
        body: payload,
      );

      debugPrint('LEAVE RESPONSE STATUS: ${response.statusCode}');
      debugPrint('LEAVE RESPONSE BODY: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _leaveResponse = LeaveModel.fromJson(data);
        _isSuccess = true;
        await fetchLeaves();
      } else {
        // ── Parse every possible Django error shape ──────────────────────
        debugPrint('LEAVE ERROR RAW: ${response.body}');
        String msg = 'Failed to submit leave request';
        try {
          final data = jsonDecode(response.body);
          if (data is Map) {
            final buffer = StringBuffer();
            data.forEach((key, value) {
              if (value is List) {
                buffer.write(value.join(', '));
              } else if (value is String) {
                buffer.write(value);
              } else {
                buffer.write(value.toString());
              }
              buffer.write(' ');
            });
            final extracted = buffer.toString().trim();
            if (extracted.isNotEmpty) msg = extracted;
          } else if (data is String && data.isNotEmpty) {
            msg = data;
          }
        } catch (_) {
          if (response.body.isNotEmpty) msg = response.body;
        }
        _errorMessage = msg.replaceFirst(RegExp(r'^Exception:\s*'), '');
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      debugPrint('LEAVE REQUEST ERROR: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Reset POST state only (keeps list intact) ──────────────────────────────
  void resetForm() {
    _isLoading = false;
    _isSuccess = false;
    _errorMessage = null;
    _leaveResponse = null;
    notifyListeners();
  }

  // ── Full reset ─────────────────────────────────────────────────────────────
  void reset() {
    _isFetching = false;
    _leaves = [];
    _fetchError = null;
    resetForm();
  }
}