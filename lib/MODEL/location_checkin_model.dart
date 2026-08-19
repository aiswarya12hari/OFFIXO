class LocationCheckInResponse {
  final bool success;
  final String message;
  final int attendanceId;
  final double distanceMeter;
  final String shiftName;

  LocationCheckInResponse({
    required this.success,
    required this.message,
    required this.attendanceId,
    required this.distanceMeter,
    required this.shiftName,
  });

  factory LocationCheckInResponse.fromJson(Map<String, dynamic> json) {
    return LocationCheckInResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      attendanceId: json['attendance_id'] ?? 0,
      distanceMeter: double.tryParse(json['distance_meter'].toString()) ?? 0.0,
      shiftName: json['shift_name'] ?? '',
    );
  }
}