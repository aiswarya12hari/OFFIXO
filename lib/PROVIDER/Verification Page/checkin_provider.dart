import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:offixo/CONTROLLER/checkin_controller.dart';
import 'package:offixo/MODEL/checkin_model.dart';
import 'package:offixo/MODEL/location_checkin_model.dart';

enum CheckInStatus { idle, loading, success, failure }

class CheckInProvider extends ChangeNotifier {
  final CheckInController _controller = CheckInController();

  CheckInStatus _status = CheckInStatus.idle;

  CheckInResponse? _response;

  LocationCheckInResponse? _locationResponse;

  String _errorMessage = '';

  bool _isAlreadyCheckedIn = false;

  /// Tags each submitCheckIn/submitLocationCheckIn call. This provider is
  /// typically supplied above the Verification screen in the widget tree,
  /// so it outlives any single VerificationScreen instance. If the user
  /// backs out mid-request and then opens the screen again and submits a
  /// NEW request, the OLD request's API call can still resolve later and
  /// land here. Without this guard its (possibly stale/contradictory)
  /// result would silently overwrite the newer request's status/response,
  /// even though nothing on screen asked for that. Every mutation of
  /// _status/_response/_errorMessage below is gated on this request still
  /// being the current one.
  int _activeRequestId = 0;

  CheckInStatus get status => _status;

  CheckInResponse? get response => _response;

  LocationCheckInResponse? get locationResponse => _locationResponse;

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
        debugPrint(
          '[LOCATION-PERM] requestPermission() called from '
          'CheckInProvider._getLocation()',
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
        debugPrint('GPS Error: $e');
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// [prefetchedPosition] lets the caller (verification screen) pass in a
  /// location that was already fetched earlier - e.g. started in parallel
  /// with camera initialization - so we don't wait for a fresh GPS fix at
  /// the moment the user taps check-in. If not provided, falls back to
  /// fetching fresh, same as before.
  Future<void> submitCheckIn({
    required File selfie,
    Position? prefetchedPosition,
  }) async {
    final int myRequestId = ++_activeRequestId;

    _status = CheckInStatus.loading;
    _errorMessage = '';
    _isAlreadyCheckedIn = false;

    notifyListeners();

    try {
      /// Get location FIRST - must succeed before hitting the API
      final position = prefetchedPosition ?? await _getLocation();

      if (myRequestId != _activeRequestId) {
        // A newer request has since started (e.g. the user backed out,
        // reopened the screen, and tapped Check In again). This one is
        // stale - don't let it clobber the newer request's in-progress
        // state.
        return;
      }

      if (position == null) {
        _status = CheckInStatus.failure;
        _errorMessage =
            'Location permission is required to check in. Please enable location and try again.';
        notifyListeners();
        return;
      }

      final latitude = position.latitude;

      final longitude = position.longitude;

      debugPrint(
        'CHECK-IN LOCATION -> Latitude: $latitude, Longitude: $longitude',
      );

      /// API call
      final response = await _controller.checkIn(
        selfie: selfie,
        latitude: latitude,
        longitude: longitude,
      );

      if (myRequestId != _activeRequestId) {
        // Superseded while the API call was in flight - discard.
        return;
      }

      _response = response;

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
      if (myRequestId != _activeRequestId) {
        return;
      }

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

    if (myRequestId != _activeRequestId) {
      return;
    }

    notifyListeners();
  }

  /// Location-only check-in — used for LOCATION_BASED organizations.
  /// No selfie / camera step involved.
  Future<void> submitLocationCheckIn({Position? prefetchedPosition}) async {
    final int myRequestId = ++_activeRequestId;

    _status = CheckInStatus.loading;
    _errorMessage = '';
    _isAlreadyCheckedIn = false;

    notifyListeners();

    try {
      final position = prefetchedPosition ?? await _getLocation();

      if (myRequestId != _activeRequestId) {
        return;
      }

      if (position == null) {
        _status = CheckInStatus.failure;
        _errorMessage =
            'Location permission is required to check in. Please enable location and try again.';
        notifyListeners();
        return;
      }

      final latitude = position.latitude;

      final longitude = position.longitude;

      debugPrint(
        'LOCATION CHECK-IN -> Latitude: $latitude, Longitude: $longitude',
      );

      final locationResponse = await _controller.checkInLocation(
        latitude: latitude,
        longitude: longitude,
      );

      if (myRequestId != _activeRequestId) {
        return;
      }

      _locationResponse = locationResponse;

      final message = _locationResponse?.message ?? '';

      if (message.toLowerCase().contains('already checked in')) {
        _isAlreadyCheckedIn = true;
        _status = CheckInStatus.success;
      } else if (_locationResponse!.success) {
        _status = CheckInStatus.success;
      } else {
        _status = CheckInStatus.failure;
        _errorMessage = message.isNotEmpty ? message : 'Check-in failed';
      }
    } catch (e) {
      if (myRequestId != _activeRequestId) {
        return;
      }

      final msg = e.toString().replaceFirst('Exception: ', '');

      if (msg.toLowerCase().contains('already checked in')) {
        _isAlreadyCheckedIn = true;
        _status = CheckInStatus.success;
      } else {
        _status = CheckInStatus.failure;
        _errorMessage = msg.isNotEmpty ? msg : 'Something went wrong';
      }
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

    _status = CheckInStatus.idle;
    _response = null;
    _locationResponse = null;
    _errorMessage = '';
    _isAlreadyCheckedIn = false;
    notifyListeners();
  }
}
