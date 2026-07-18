import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:offixo/CONFIG/api_config.dart';
import 'package:offixo/MODEL/checkout_model.dart';
import 'package:offixo/SERVICES/shared_preference_service.dart';

class CheckOutController {
  Future<CheckOutResponse> checkOut({
    required File selfie,
    required double latitude,
    required double longitude,
  }) async {
    final token = await SharedPreferenceService.getAccessToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.checkOutUrl),
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
            'Check-out request timed out. Please check your internet connection and try again.',
          );
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      Map<String, dynamic> json;
      try {
        json = jsonDecode(response.body);
      } catch (_) {
        throw Exception(
          'Something went wrong while processing check-out. Please try again.',
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CheckOutResponse.fromJson(json);
      } else {
        throw Exception(json['message'] ?? 'Check-out failed');
      }
    } on TimeoutException {
      throw Exception(
        'Check-out request timed out. Please check your internet connection and try again.',
      );
    } on SocketException {
      throw Exception(
        'No internet connection. Please check your network and try again.',
      );
    } on http.ClientException {
      throw Exception('Connection lost while checking out. Please try again.');
    } catch (e) {
      /// If it's already a clean Exception (e.g. thrown above with a message
      /// from the backend), rethrow as-is. Otherwise wrap unknown low-level
      /// errors (socket aborts, TLS errors, etc.) into a friendly message.
      final msg = e.toString();

      if (msg.startsWith('Exception: ')) {
        rethrow;
      }

      throw Exception('Check-out failed. Please try again.');
    }
  }
}
