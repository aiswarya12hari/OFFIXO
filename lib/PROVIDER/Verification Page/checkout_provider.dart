import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:offixo/CONTROLLER/checkout_controller.dart';
import 'package:offixo/MODEL/checkout_model.dart';

enum CheckOutStatus { idle, loading, success, failure }

class CheckOutProvider extends ChangeNotifier {
  final CheckOutController _controller = CheckOutController();

  CheckOutStatus _status = CheckOutStatus.idle;

  CheckOutResponse? _response;

  String _errorMessage = '';

  CheckOutStatus get status => _status;

  CheckOutResponse? get response => _response;

  String get errorMessage => _errorMessage;

  bool get isLoading => _status == CheckOutStatus.loading;

  bool get isSuccess => _status == CheckOutStatus.success;

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

      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 6),
        );
      } catch (_) {
        /// Fresh fix timed out - fall back to last known position instead
        /// of blocking check-out entirely.
        return await Geolocator.getLastKnownPosition();
      }
    } catch (e) {
      debugPrint('LOCATION ERROR: $e');
      return null;
    }
  }

  /// [prefetchedPosition] lets the caller (verification screen) pass in a
  /// location that was already fetched earlier - e.g. started in parallel
  /// with camera initialization - so we don't wait for a fresh GPS fix at
  /// the moment the user taps check-out. If not provided, falls back to
  /// fetching fresh, same as before.
  Future<void> submitCheckOut({
    required File selfie,
    Position? prefetchedPosition,
  }) async {
    _status = CheckOutStatus.loading;

    _errorMessage = '';

    notifyListeners();

    try {
      final position = prefetchedPosition ?? await _getLocation();

      if (position == null) {
        _status = CheckOutStatus.failure;
        _errorMessage =
            'Location permission is required to check out. Please enable location and try again.';
        notifyListeners();
        return;
      }

      final latitude = position.latitude;

      final longitude = position.longitude;

      debugPrint(
        'CHECK-OUT LOCATION -> Latitude: $latitude, Longitude: $longitude',
      );

      _response = await _controller.checkOut(
        selfie: selfie,
        latitude: latitude,
        longitude: longitude,
      );

      if (_response!.success) {
        _status = CheckOutStatus.success;
      } else {
        _status = CheckOutStatus.failure;

        _errorMessage = _response!.message;
      }
    } catch (e) {
      _status = CheckOutStatus.failure;

      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    notifyListeners();
  }

  void reset() {
    _status = CheckOutStatus.idle;

    _response = null;

    _errorMessage = '';

    notifyListeners();
  }
}
