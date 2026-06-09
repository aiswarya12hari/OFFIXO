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

//       /// API call
//       _response = await _controller.checkIn(
//         selfie: selfie,
//         latitude: latitude,
//         longitude: longitude,
        
//       );
//       debugPrint('====================');
// debugPrint('SUCCESS: ${_response?.success}');
// debugPrint('FACE VERIFIED: ${_response?.faceVerified}');
// debugPrint('LOCATION VERIFIED: ${_response?.locationVerified}');
// debugPrint('MESSAGE: ${_response?.message}');
// debugPrint('====================');

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
      print('📍 FETCHING LOCATION...');
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        return null;
      }
      
      print('✅ Location services are enabled');

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        print('⚠️ Location permission denied, requesting...');
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          print('❌ Location permission denied by user');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permission denied forever');
        return null;
      }
      
      print('✅ Location permission granted');

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // ✅ PRINT LATITUDE & LONGITUDE HERE
      print('📍 LOCATION FOUND:');
      print('   Latitude: ${position.latitude}');
      print('   Longitude: ${position.longitude}');
      print('   Accuracy: ${position.accuracy} meters');
      print('   Altitude: ${position.altitude}');
      
      return position;
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  Future<void> submitCheckIn({required File selfie}) async {
    print('\n🟢 ===== CHECK-IN PROCESS STARTED =====');
    
    _status = CheckInStatus.loading;
    _errorMessage = '';
    _isAlreadyCheckedIn = false;

    notifyListeners();

    try {
      /// Get location
      final position = await _getLocation();

      final latitude = position?.latitude ?? 0.0;
      final longitude = position?.longitude ?? 0.0;
      
      // ✅ PRINT VALUES BEING SENT TO API
      print('\n📤 SENDING TO CHECK-IN API:');
      print('   Latitude: $latitude');
      print('   Longitude: $longitude');
      print('   Selfie path: ${selfie.path}');
      print('   Selfie exists: ${selfie.existsSync()}');

      /// API call
      _response = await _controller.checkIn(
        selfie: selfie,
        latitude: latitude,
        longitude: longitude,
      );
      
      print('\n📥 CHECK-IN API RESPONSE:');
      debugPrint('====================');
      debugPrint('SUCCESS: ${_response?.success}');
      debugPrint('FACE VERIFIED: ${_response?.faceVerified}');
      debugPrint('LOCATION VERIFIED: ${_response?.locationVerified}');
      debugPrint('MESSAGE: ${_response?.message}');
      debugPrint('====================');

      final message = _response?.message ?? '';

      /// Already checked in
      if (message.toLowerCase().contains('already checked in')) {
        print('⚠️ User already checked in today');
        _isAlreadyCheckedIn = true;
        _status = CheckInStatus.success;
      }
      /// SUCCESS
      else if (_response!.success &&
          _response!.faceVerified &&
          _response!.locationVerified) {
        print('✅ CHECK-IN SUCCESSFUL!');
        _status = CheckInStatus.success;
      }
      /// FAILURE WITH REASON
      else {
        print('❌ CHECK-IN FAILED: $message');
        _status = CheckInStatus.failure;
        _errorMessage = message.isNotEmpty ? message : 'Check-in failed';
      }
    } catch (e) {
      print('❌ CHECK-IN EXCEPTION: $e');
      final msg = e.toString().replaceFirst('Exception: ', '');

      /// Already checked in
      if (msg.toLowerCase().contains('already checked in')) {
        print('⚠️ User already checked in (from exception)');
        _isAlreadyCheckedIn = true;
        _status = CheckInStatus.success;
      } else {
        _status = CheckInStatus.failure;
        /// SHOW API MESSAGE FROM BACKEND
        _errorMessage = msg.isNotEmpty ? msg : 'Something went wrong';
        print('❌ Error message: $_errorMessage');
      }
    }
    
    print('🟢 ===== CHECK-IN PROCESS ENDED =====\n');
    notifyListeners();
  }

  void reset() {
    print('🔄 Resetting CheckInProvider');
    _status = CheckInStatus.idle;
    _response = null;
    _errorMessage = '';
    _isAlreadyCheckedIn = false;
    print("ERROR MESSAGE: $_errorMessage");
    print("RESPONSE MESSAGE: ${_response?.message}");
    notifyListeners();
  }
}