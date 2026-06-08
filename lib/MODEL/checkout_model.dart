class CheckOutResponse {
  final bool success;
  final String message;
  final int attendanceId;
  final double distanceMeter;
  final String workingHours;

  CheckOutResponse({
    required this.success,
    required this.message,
    required this.attendanceId,
    required this.distanceMeter,
    required this.workingHours,
  });

  factory CheckOutResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return CheckOutResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      attendanceId:
          json['attendance_id'] ?? 0,
      distanceMeter:
          (json['distance_meter'] ?? 0)
              .toDouble(),
      workingHours:
          json['working_hours'] ?? '',
    );
  }
}