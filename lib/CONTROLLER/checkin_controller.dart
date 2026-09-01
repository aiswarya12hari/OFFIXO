import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:offixo/CONFIG/api_config.dart';
import 'package:offixo/MODEL/checkin_model.dart';
import 'package:offixo/MODEL/location_checkin_model.dart';
import 'package:offixo/SERVICES/shared_preference_service.dart';

class CheckInController {
  Future<CheckInResponse> checkIn({
    required File selfie,
    required double latitude,
    required double longitude,
  }) async {
    final token = await SharedPreferenceService.getAccessToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.checkInUrl),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();

    request.files.add(await http.MultipartFile.fromPath('selfie', selfie.path));

    try {
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException(
            'Check-in request timed out. Please check your internet connection and try again.',
          );
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      print(response.body);
      print(response.statusCode);
      print(latitude);
      print(longitude);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return CheckInResponse.fromJson(json);
      } else {
        // Parse backend error message cleanly
        final json = jsonDecode(response.body);

        // Handle validation errors (400 with field-specific messages)
        if (response.statusCode == 400) {
          // Extract validation error messages
          final errorMessages = <String>[];
          json.forEach((field, errors) {
            if (errors is List) {
              errorMessages.addAll(errors.map((e) => e.toString()));
            } else if (errors is String) {
              errorMessages.add(errors);
            }
          });

          final msg = errorMessages.isNotEmpty
              ? errorMessages.join(', ')
              : (json['message'] ?? 'Check-in failed');
          throw Exception(msg);
        }

        final msg = json['message'] ?? 'Check-in failed';
        throw Exception(msg);
      }
    } on TimeoutException {
      throw Exception(
        'Check-in request timed out. Please check your internet connection and try again.',
      );
    } on SocketException {
      throw Exception(
        'No internet connection. Please check your network and try again.',
      );
    } on http.ClientException {
      throw Exception('Connection lost while checking in. Please try again.');
    } catch (e) {
      /// If it's already a clean Exception (e.g. thrown above with a message
      /// from the backend/validation), rethrow as-is. Otherwise wrap unknown
      /// low-level errors (socket aborts, TLS errors, JSON decode failures,
      /// etc.) into a friendly message.
      final msg = e.toString();

      if (msg.startsWith('Exception: ')) {
        rethrow;
      }

      throw Exception('Check-in failed. Please try again.');
    }
  }

  /// Location-only check-in (no selfie) — used for organizations whose
  /// attendance type is LOCATION_BASED.
  Future<LocationCheckInResponse> checkInLocation({
    required double latitude,
    required double longitude,
  }) async {
    final token = await SharedPreferenceService.getAccessToken();

    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.locationCheckInUrl),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException(
                'Check-in request timed out. Please check your internet connection and try again.',
              );
            },
          );

      print(response.body);
      print(response.statusCode);

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return LocationCheckInResponse.fromJson(json);
      } else {
        if (response.statusCode == 400) {
          final errorMessages = <String>[];
          json.forEach((field, errors) {
            if (errors is List) {
              errorMessages.addAll(errors.map((e) => e.toString()));
            } else if (errors is String) {
              errorMessages.add(errors);
            }
          });

          final msg = errorMessages.isNotEmpty
              ? errorMessages.join(', ')
              : (json['message'] ?? 'Check-in failed');
          throw Exception(msg);
        }

        final msg = json['message'] ?? 'Check-in failed';
        throw Exception(msg);
      }
    } on TimeoutException {
      throw Exception(
        'Check-in request timed out. Please check your internet connection and try again.',
      );
    } on SocketException {
      throw Exception(
        'No internet connection. Please check your network and try again.',
      );
    } on http.ClientException {
      throw Exception('Connection lost while checking in. Please try again.');
    } catch (e) {
      final msg = e.toString();

      if (msg.startsWith('Exception: ')) {
        rethrow;
      }

      throw Exception('Check-in failed. Please try again.');
    }
  }
}
