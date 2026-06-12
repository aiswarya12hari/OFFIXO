import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:offixo/CONFIG/api_config.dart';
import 'package:offixo/MODEL/leave_balance_model.dart';
import 'package:offixo/SERVICES/shared_preference_service.dart';

class LeaveBalanceProvider extends ChangeNotifier {
  bool _isLoading = false;
  List<LeaveBalanceModel> _balances = [];
  String? _error;
  int? _year;

  bool get isLoading => _isLoading;
  List<LeaveBalanceModel> get balances => _balances;
  String? get error => _error;
  int? get year => _year;

  Future<void> fetchBalances() async {
    debugPrint('>>> fetchBalances CALLED');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await SharedPreferenceService.getAuthHeaders();
      debugPrint('LEAVE BALANCE URL: ${ApiConfig.leaveBalanceUrl}');
      debugPrint('LEAVE BALANCE HEADERS: $headers');

      final response = await http.get(
        Uri.parse(ApiConfig.leaveBalanceUrl),
        headers: headers,
      );

      debugPrint('LEAVE BALANCE STATUS: ${response.statusCode}');
      debugPrint('LEAVE BALANCE BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _year = data['year'];
        final List<dynamic> list = data['leave_balances'] ?? [];
        _balances = list.map((e) => LeaveBalanceModel.fromJson(e)).toList();
        debugPrint('LEAVE BALANCE COUNT: ${_balances.length}');
      } else {
        _error = 'Failed to load leave balances';
        debugPrint('LEAVE BALANCE FAILED: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      debugPrint('LEAVE BALANCE EXCEPTION: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void reset() {
    _isLoading = false;
    _balances = [];
    _error = null;
    _year = null;
    notifyListeners();
  }
}