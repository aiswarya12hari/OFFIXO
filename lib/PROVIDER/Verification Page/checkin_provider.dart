// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:offixo/CONTROLLER/checkin_controller.dart';
// import 'package:offixo/MODEL/checkin_model.dart';

// enum CheckInStatus { idle, loading, success, failure }

// class CheckInProvider extends ChangeNotifier {
//   final CheckInController _controller = CheckInController();

//   CheckInStatus _status = CheckInStatus.idle;

//   CheckInResponse? _response;

//   String _errorMessage = '';

//   bool _isAlreadyCheckedIn = false;

//   CheckInStatus get status => _status;

//   CheckInResponse? get response => _response;

//   String get errorMessage => _errorMessage;

//   bool get isAlreadyCheckedIn => _isAlreadyCheckedIn;

//   bool get isLoading => _status == CheckInStatus.loading;

//   bool get isSuccess => _status == CheckInStatus.success;

//   Future<Position?> _getLocation() async {
//     try {
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

//       if (!serviceEnabled) {
//         await Geolocator.openLocationSettings();
//         return null;
//       }

//       LocationPermission permission = await Geolocator.checkPermission();

//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();

//         if (permission == LocationPermission.denied) {
//           return null;
//         }
//       }

//       if (permission == LocationPermission.deniedForever) {
//         await Geolocator.openAppSettings();
//         return null;
//       }

//       return await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//     } catch (e) {
//       return null;
//     }
//   }

//   Future<void> submitCheckIn({required File selfie}) async {
//     _status = CheckInStatus.loading;
//     _errorMessage = '';
//     _isAlreadyCheckedIn = false;

//     notifyListeners();

//     try {
//       /// Get location
//       final position = await _getLocation();

//       final latitude = position?.latitude ?? 0.0;

//       final longitude = position?.longitude ?? 0.0;

//       debugPrint('CHECK-IN LOCATION -> Latitude: $latitude, Longitude: $longitude');

//       /// API call
//       _response = await _controller.checkIn(
//         selfie: selfie,
//         latitude: latitude,
//         longitude: longitude,
//       );
//       debugPrint('====================');
//       debugPrint('SUCCESS: ${_response?.success}');
//       debugPrint('FACE VERIFIED: ${_response?.faceVerified}');
//       debugPrint('LOCATION VERIFIED: ${_response?.locationVerified}');
//       debugPrint('MESSAGE: ${_response?.message}');
//       debugPrint('====================');

//       final message = _response?.message ?? '';

//       /// Already checked in
//       if (message.toLowerCase().contains('already checked in')) {
//         _isAlreadyCheckedIn = true;
//         _status = CheckInStatus.success;
//       }
//       /// SUCCESS
//       else if (_response!.success &&
//           _response!.faceVerified &&
//           _response!.locationVerified) {
//         _status = CheckInStatus.success;
//       }
//       /// FAILURE WITH REASON
//       else {
//         _status = CheckInStatus.failure;

//         _errorMessage = message.isNotEmpty ? message : 'Check-in failed';
//       }
//     } catch (e) {
//       final msg = e.toString().replaceFirst('Exception: ', '');

//       /// Already checked in
//       if (msg.toLowerCase().contains('already checked in')) {
//         _isAlreadyCheckedIn = true;
//         _status = CheckInStatus.success;
//       } else {
//         _status = CheckInStatus.failure;

//         /// SHOW API MESSAGE FROM BACKEND
//         _errorMessage = msg.isNotEmpty ? msg : 'Something went wrong';
//       }
//     }

//     notifyListeners();
//   }

//   void reset() {
//     _status = CheckInStatus.idle;
//     _response = null;
//     _errorMessage = '';
//     _isAlreadyCheckedIn = false;
//     print("ERROR MESSAGE: $_errorMessage");
//     print("RESPONSE MESSAGE: ${_response?.message}");
//     notifyListeners();
//   }
// }


// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:offixo/CONTROLLER/checkin_controller.dart';
// import 'package:offixo/MODEL/checkin_model.dart';

// enum CheckInStatus { idle, loading, success, failure }

// class CheckInProvider extends ChangeNotifier {
//   final CheckInController _controller = CheckInController();

//   CheckInStatus _status = CheckInStatus.idle;

//   CheckInResponse? _response;

//   String _errorMessage = '';

//   bool _isAlreadyCheckedIn = false;

//   CheckInStatus get status => _status;

//   CheckInResponse? get response => _response;

//   String get errorMessage => _errorMessage;

//   bool get isAlreadyCheckedIn => _isAlreadyCheckedIn;

//   bool get isLoading => _status == CheckInStatus.loading;

//   bool get isSuccess => _status == CheckInStatus.success;

//   Future<Position?> _getLocation() async {
//     try {
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

//       if (!serviceEnabled) {
//         await Geolocator.openLocationSettings();
//         return null;
//       }

//       LocationPermission permission = await Geolocator.checkPermission();

//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();

//         if (permission == LocationPermission.denied) {
//           return null;
//         }
//       }

//       if (permission == LocationPermission.deniedForever) {
//         await Geolocator.openAppSettings();
//         return null;
//       }

//       return await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//     } catch (e) {
//       return null;
//     }
//   }

//   Future<void> submitCheckIn({required File selfie}) async {
//     _status = CheckInStatus.loading;
//     _errorMessage = '';
//     _isAlreadyCheckedIn = false;

//     notifyListeners();

//     try {
//       /// Get location FIRST - must succeed before hitting the API
//       final position = await _getLocation();

//       if (position == null) {
//         _status = CheckInStatus.failure;
//         _errorMessage =
//             'Location permission is required to check in. Please enable location and try again.';
//         notifyListeners();
//         return;
//       }

//       final latitude = position.latitude;

//       final longitude = position.longitude;

//       debugPrint(
//         'CHECK-IN LOCATION -> Latitude: $latitude, Longitude: $longitude',
//       );

//       /// API call
//       _response = await _controller.checkIn(
//         selfie: selfie,
//         latitude: latitude,
//         longitude: longitude,
//       );
//       debugPrint('====================');
//       debugPrint('SUCCESS: ${_response?.success}');
//       debugPrint('FACE VERIFIED: ${_response?.faceVerified}');
//       debugPrint('LOCATION VERIFIED: ${_response?.locationVerified}');
//       debugPrint('MESSAGE: ${_response?.message}');
//       debugPrint('====================');

//       final message = _response?.message ?? '';

//       /// Already checked in
//       if (message.toLowerCase().contains('already checked in')) {
//         _isAlreadyCheckedIn = true;
//         _status = CheckInStatus.success;
//       }
//       /// SUCCESS
//       else if (_response!.success &&
//           _response!.faceVerified &&
//           _response!.locationVerified) {
//         _status = CheckInStatus.success;
//       }
//       /// FAILURE WITH REASON
//       else {
//         _status = CheckInStatus.failure;

//         _errorMessage = message.isNotEmpty ? message : 'Check-in failed';
//       }
//     } catch (e) {
//       final msg = e.toString().replaceFirst('Exception: ', '');

//       /// Already checked in
//       if (msg.toLowerCase().contains('already checked in')) {
//         _isAlreadyCheckedIn = true;
//         _status = CheckInStatus.success;
//       } else {
//         _status = CheckInStatus.failure;

//         /// SHOW API MESSAGE FROM BACKEND
//         _errorMessage = msg.isNotEmpty ? msg : 'Something went wrong';
//       }
//     }

//     notifyListeners();
//   }

//   void reset() {
//     _status = CheckInStatus.idle;
//     _response = null;
//     _errorMessage = '';
//     _isAlreadyCheckedIn = false;
//     print("ERROR MESSAGE: $_errorMessage");
//     print("RESPONSE MESSAGE: ${_response?.message}");
//     notifyListeners();
//   }
// }

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

      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 6),
        );
      } catch (_) {
        /// Fresh fix timed out - fall back to last known position instead
        /// of blocking check-in entirely.
        return await Geolocator.getLastKnownPosition();
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
    _status = CheckInStatus.loading;
    _errorMessage = '';
    _isAlreadyCheckedIn = false;

    notifyListeners();

    try {
      /// Get location FIRST - must succeed before hitting the API
      final position = prefetchedPosition ?? await _getLocation();

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