class AttendanceStatusModel {
  final String checkInTime;
  final String checkOutTime;
  final bool isCurrentlyActive;
  final String currentSessionDuration;
  final String totalWorkingHours;

  AttendanceStatusModel({
    required this.checkInTime,
    required this.checkOutTime,
    required this.isCurrentlyActive,
    required this.currentSessionDuration,
    required this.totalWorkingHours,
  });

  factory AttendanceStatusModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AttendanceStatusModel(
      checkInTime:
          json['checkin_time'] ?? '--:--',

      checkOutTime:
          json['checkout_time'] ?? '--:--',

      isCurrentlyActive:
          json['is_currently_active'] ?? false,

      currentSessionDuration:
          json['current_session_duration'] ??
              '00:00:00',

      totalWorkingHours:
          json['total_working_hours'] ??
              '00:00:00',
    );
  }
}