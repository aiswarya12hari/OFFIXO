import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart'
    as http;
import 'package:offixo/CONFIG/api_config.dart';
import 'package:offixo/MODEL/checkout_model.dart';
import 'package:offixo/SERVICES/shared_preference_service.dart';

class CheckOutController {
  Future<CheckOutResponse> checkOut({
    required File selfie,
    required double latitude,
    required double longitude,
  }) async {
    final token =
        await SharedPreferenceService
            .getAccessToken();

    final request =
        http.MultipartRequest(
      'POST',
      Uri.parse(
        ApiConfig.checkOutUrl,
      ),
    );

    request.headers[
        'Authorization'] =
        'Bearer $token';

    request.fields['latitude'] =
        latitude.toString();

    request.fields['longitude'] =
        longitude.toString();

    request.files.add(
      await http.MultipartFile
          .fromPath(
        'selfie',
        selfie.path,
      ),
    );

    final streamedResponse =
        await request.send();

    final response =
        await http.Response.fromStream(
      streamedResponse,
    );

    final json = jsonDecode(
      response.body,
    );

    if (response.statusCode ==
            200 ||
        response.statusCode ==
            201) {
      return CheckOutResponse
          .fromJson(json);
    } else {
      throw Exception(
        json['message'] ??
            'Check-out failed',
      );
    }
  }
}