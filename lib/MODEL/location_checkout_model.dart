class AttendanceSession {
  final int id;
  final int member;
  final int branch;
  final int organization;
  final String attendanceDate;
  final String checkinTime;
  final String? checkoutTime;
  final String status;
  final String workingHours;
  final int shift;
  final String shiftName;
  final String workingHoursDisplay;
  final String totalWorkingHoursToday;
  final List<dynamic> breaks;

  AttendanceSession({
    required this.id,
    required this.member,
    required this.branch,
    required this.organization,
    required this.attendanceDate,
    required this.checkinTime,
    required this.checkoutTime,
    required this.status,
    required this.workingHours,
    required this.shift,
    required this.shiftName,
    required this.workingHoursDisplay,
    required this.totalWorkingHoursToday,
    required this.breaks,
  });

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    return AttendanceSession(
      id: json['id'] ?? 0,
      member: json['member'] ?? 0,
      branch: json['branch'] ?? 0,
      organization: json['organization'] ?? 0,
      attendanceDate: json['attendance_date'] ?? '',
      checkinTime: json['checkin_time'] ?? '',
      checkoutTime: json['checkout_time'],
      status: json['status'] ?? '',
      workingHours: json['working_hours'] ?? '',
      shift: json['shift'] ?? 0,
      shiftName: json['shift_name'] ?? '',
      workingHoursDisplay: json['working_hours_display'] ?? '',
      totalWorkingHoursToday: json['total_working_hours_today'] ?? '',
      breaks: json['breaks'] ?? [],
    );
  }
}

class LocationCheckOutResponse {
  final bool success;
  final String message;
  final int attendanceId;
  final double distanceMeter;
  final String totalWorkingHoursToday;
  final List<AttendanceSession> allSessionsToday;

  LocationCheckOutResponse({
    required this.success,
    required this.message,
    required this.attendanceId,
    required this.distanceMeter,
    required this.totalWorkingHoursToday,
    required this.allSessionsToday,
  });

  factory LocationCheckOutResponse.fromJson(Map<String, dynamic> json) {
    return LocationCheckOutResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      attendanceId: json['attendance_id'] ?? 0,
      distanceMeter: double.tryParse(json['distance_meter'].toString()) ?? 0.0,
      totalWorkingHoursToday: json['total_working_hours_today'] ?? '',
      allSessionsToday: (json['all_sessions_today'] as List<dynamic>? ?? [])
          .map((e) => AttendanceSession.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}