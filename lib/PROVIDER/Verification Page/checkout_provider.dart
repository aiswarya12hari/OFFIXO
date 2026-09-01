import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:offixo/CONTROLLER/checkout_controller.dart';
import 'package:offixo/MODEL/checkout_model.dart';
import 'package:offixo/MODEL/location_checkout_model.dart';

enum CheckOutStatus { idle, loading, success, failure }

class CheckOutProvider extends ChangeNotifier {
  final CheckOutController _controller = CheckOutController();

  CheckOutStatus _status = CheckOutStatus.idle;

  CheckOutResponse? _response;

  LocationCheckOutResponse? _locationResponse;

  String _errorMessage = '';

  /// Tags each submitCheckOut/submitLocationCheckOut call - see the
  /// matching field in CheckInProvider for the full explanation of why
  /// this is needed (this provider outlives any single VerificationScreen
  /// instance, so a backed-out request's late result must never overwrite
  /// a newer request's state).
  int _activeRequestId = 0;

  CheckOutStatus get status => _status;

  CheckOutResponse? get response => _response;

  LocationCheckOutResponse? get locationResponse => _locationResponse;

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
        debugPrint(
          '[LOCATION-PERM] requestPermission() called from '
          'CheckOutProvider._getLocation()',
        );

        permission = await Geolocator.requestPermission();

        debugPrint('[LOCATION-PERM] requestPermission() result: $permission');

        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return null;
      }

      try {
        Position position;

        int retryCount = 0;

        do {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 15),
          );

          debugPrint(
            '[GPS] Accuracy: ${position.accuracy.toStringAsFixed(1)} meters',
          );

          if (position.accuracy <= 20) {
            break;
          }

          retryCount++;

          await Future.delayed(const Duration(seconds: 2));
        } while (retryCount < 3);

        return position;
      } catch (e) {
        debugPrint('LOCATION ERROR: $e');
        return null;
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
    final int myRequestId = ++_activeRequestId;

    _status = CheckOutStatus.loading;

    _errorMessage = '';

    notifyListeners();

    try {
      final position = prefetchedPosition ?? await _getLocation();

      if (myRequestId != _activeRequestId) {
        // A newer request has since started - this one is stale.
        return;
      }

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

      final response = await _controller.checkOut(
        selfie: selfie,
        latitude: latitude,
        longitude: longitude,
      );

      if (myRequestId != _activeRequestId) {
        // Superseded while the API call was in flight - discard.
        return;
      }

      _response = response;

      if (_response!.success) {
        _status = CheckOutStatus.success;
      } else {
        _status = CheckOutStatus.failure;

        _errorMessage = _response!.message;
      }
    } catch (e) {
      if (myRequestId != _activeRequestId) {
        return;
      }

      _status = CheckOutStatus.failure;

      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    if (myRequestId != _activeRequestId) {
      return;
    }

    notifyListeners();
  }

  /// Location-only check-out — used for LOCATION_BASED organizations.
  /// No selfie / camera step involved.
  Future<void> submitLocationCheckOut({Position? prefetchedPosition}) async {
    final int myRequestId = ++_activeRequestId;

    _status = CheckOutStatus.loading;

    _errorMessage = '';

    notifyListeners();

    try {
      final position = prefetchedPosition ?? await _getLocation();

      if (myRequestId != _activeRequestId) {
        return;
      }

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
        'LOCATION CHECK-OUT -> Latitude: $latitude, Longitude: $longitude',
      );

      final locationResponse = await _controller.checkOutLocation(
        latitude: latitude,
        longitude: longitude,
      );

      if (myRequestId != _activeRequestId) {
        return;
      }

      _locationResponse = locationResponse;

      if (_locationResponse!.success) {
        _status = CheckOutStatus.success;
      } else {
        _status = CheckOutStatus.failure;

        _errorMessage = _locationResponse!.message;
      }
    } catch (e) {
      if (myRequestId != _activeRequestId) {
        return;
      }

      _status = CheckOutStatus.failure;

      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    if (myRequestId != _activeRequestId) {
      return;
    }

    notifyListeners();
  }

  void reset() {
    // Invalidate any request still in flight from a previous attempt so
    // it can never resolve into the fresh idle state we're about to set.
    _activeRequestId++;

    _status = CheckOutStatus.idle;

    _response = null;

    _locationResponse = null;

    _errorMessage = '';

    notifyListeners();
  }
}
