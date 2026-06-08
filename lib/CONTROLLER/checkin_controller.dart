import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:offixo/CONFIG/api_config.dart';
import 'package:offixo/MODEL/checkin_model.dart';
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

    request.files.add(
      await http.MultipartFile.fromPath('selfie', selfie.path),
    );

    final streamedResponse = await request.send();
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
  }
}