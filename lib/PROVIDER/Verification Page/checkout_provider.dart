import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:offixo/CONTROLLER/checkout_controller.dart';
import 'package:offixo/MODEL/checkout_model.dart';

enum CheckOutStatus {
  idle,
  loading,
  success,
  failure,
}

class CheckOutProvider
    extends ChangeNotifier {
  final CheckOutController
      _controller =
      CheckOutController();

  CheckOutStatus _status =
      CheckOutStatus.idle;

  CheckOutResponse? _response;

  String _errorMessage = '';

  CheckOutStatus get status =>
      _status;

  CheckOutResponse? get response =>
      _response;

  String get errorMessage =>
      _errorMessage;

  bool get isLoading =>
      _status ==
      CheckOutStatus.loading;

  bool get isSuccess =>
      _status ==
      CheckOutStatus.success;

  Future<Position?> _getLocation() async {
    try {
      bool serviceEnabled =
          await Geolocator
              .isLocationServiceEnabled();

      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission =
          await Geolocator
              .checkPermission();

      if (permission ==
          LocationPermission
              .denied) {
        permission =
            await Geolocator
                .requestPermission();

        if (permission ==
            LocationPermission
                .denied) {
          return null;
        }
      }

      if (permission ==
          LocationPermission
              .deniedForever) {
                await Geolocator.openAppSettings();
        return null;
      }

      return await Geolocator
          .getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('LOCATION ERROR: $e');
      return null;
    }
  }

  Future<void> submitCheckOut({
    required File selfie,
  }) async {
    _status =
        CheckOutStatus.loading;

    _errorMessage = '';

    notifyListeners();

    try {
      final position =
          await _getLocation();

      final latitude =
          position?.latitude ??
              0.0;

      final longitude =
          position?.longitude ??
              0.0;

      _response =
          await _controller
              .checkOut(
        selfie: selfie,
        latitude: latitude,
        longitude: longitude,
      );

      if (_response!.success) {
        _status =
            CheckOutStatus
                .success;
      } else {
        _status =
            CheckOutStatus
                .failure;

        _errorMessage =
            _response!.message;
      }
    } catch (e) {
      _status =
          CheckOutStatus.failure;

      _errorMessage = e
          .toString()
          .replaceFirst(
            'Exception: ',
            '',
          );
    }

    notifyListeners();
  }

  void reset() {
    _status =
        CheckOutStatus.idle;

    _response = null;

    _errorMessage = '';

    notifyListeners();
  }
}