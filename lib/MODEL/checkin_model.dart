// class CheckInResponse {
//   final bool success;
//   final String message;
//   final int attendanceId;
//   final double distanceMeter;
//   final bool locationVerified;
//   final bool faceVerified;

//   CheckInResponse({
//     required this.success,
//     required this.message,
//     required this.attendanceId,
//     required this.distanceMeter,
//     required this.locationVerified,
//     required this.faceVerified,
//   });

//   factory CheckInResponse.fromJson(Map<String, dynamic> json) {
//     return CheckInResponse(
//       success: json['success'] ?? false,
//       message: json['message'] ?? '',
//       attendanceId: json['attendance_id'] ?? 0,
//       distanceMeter: (json['distance_meter'] ?? 0).toDouble(),
//       locationVerified: json['location_verified'] ?? false,
//       faceVerified: json['face_verified'] ?? false,
//     );
//   }
// }

class CheckInResponse {
  final bool success;
  final String message;
  final int attendanceId;
  final double distanceMeter;
  final bool locationVerified;
  final bool faceVerified;

  CheckInResponse({
    required this.success,
    required this.message,
    required this.attendanceId,
    required this.distanceMeter,
    required this.locationVerified,
    required this.faceVerified,
  });

  factory CheckInResponse.fromJson(Map<String, dynamic> json) {
    return CheckInResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      attendanceId: json['attendance_id'] ?? 0,
      // ✅ Safe parse — handles int, double, or string from API
      distanceMeter: double.tryParse(json['distance_meter'].toString()) ?? 0.0,
      locationVerified: json['location_verified'] ?? false,
      faceVerified: json['face_verified'] ?? false,
    );
  }
}