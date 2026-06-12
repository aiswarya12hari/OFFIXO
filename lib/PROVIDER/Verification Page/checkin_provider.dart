import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:offixo/CONTROLLER/checkin_controller.dart';
import 'package:offixo/MODEL/checkin_model.dart';

enum CheckInStatus { idle, loading, success, failure }

class CheckInProvider extends ChangeNotifier {
  final CheckInController _controller = CheckInController();

  CheckInStatus _status = CheckInStatus.idle;

  CheckInResponse? _response;

  String _errorMessage = '';

  bool _isAlreadyCheckedIn = false;

  CheckInStatus get status => _status;

  CheckInResponse? get response => _response;

  String get errorMessage => _errorMessage;

  bool get isAlreadyCheckedIn => _isAlreadyCheckedIn;

  bool get isLoading => _status == CheckInStatus.loading;

  bool get isSuccess => _status == CheckInStatus.success;

  Future<Position?> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> submitCheckIn({required File selfie}) async {
    _status = CheckInStatus.loading;
    _errorMessage = '';
    _isAlreadyCheckedIn = false;

    notifyListeners();

    try {
      /// Get location
      final position = await _getLocation();

      final latitude = position?.latitude ?? 0.0;

      final longitude = position?.longitude ?? 0.0;

      /// API call
      _response = await _controller.checkIn(
        selfie: selfie,
        latitude: latitude,
        longitude: longitude,
        
      );
      debugPrint('====================');
debugPrint('SUCCESS: ${_response?.success}');
debugPrint('FACE VERIFIED: ${_response?.faceVerified}');
debugPrint('LOCATION VERIFIED: ${_response?.locationVerified}');
debugPrint('MESSAGE: ${_response?.message}');
debugPrint('====================');

      final message = _response?.message ?? '';

      /// Already checked in
      if (message.toLowerCase().contains('already checked in')) {
        _isAlreadyCheckedIn = true;
        _status = CheckInStatus.success;
      }
      /// SUCCESS
      else if (_response!.success &&
          _response!.faceVerified &&
          _response!.locationVerified) {
        _status = CheckInStatus.success;
      }
      /// FAILURE WITH REASON
      else {
        _status = CheckInStatus.failure;

        _errorMessage = message.isNotEmpty ? message : 'Check-in failed';
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');

      /// Already checked in
      if (msg.toLowerCase().contains('already checked in')) {
        _isAlreadyCheckedIn = true;
        _status = CheckInStatus.success;
      } else {
        _status = CheckInStatus.failure;

        /// SHOW API MESSAGE FROM BACKEND
        _errorMessage = msg.isNotEmpty ? msg : 'Something went wrong';
      }
    }

    notifyListeners();
  }

  void reset() {
    _status = CheckInStatus.idle;
    _response = null;
    _errorMessage = '';
    _isAlreadyCheckedIn = false;
    print("ERROR MESSAGE: $_errorMessage");
    print("RESPONSE MESSAGE: ${_response?.message}");
    notifyListeners();
  }
}
