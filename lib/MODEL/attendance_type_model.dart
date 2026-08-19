class AttendanceTypeModel {
  final int organizationId;
  final String organizationName;
  final String attendanceType;
  final String attendanceTypeDisplay;

  AttendanceTypeModel({
    required this.organizationId,
    required this.organizationName,
    required this.attendanceType,
    required this.attendanceTypeDisplay,
  });

  factory AttendanceTypeModel.fromJson(Map<String, dynamic> json) {
    return AttendanceTypeModel(
      organizationId: json['organization_id'] ?? 0,
      organizationName: json['organization_name'] ?? '',
      attendanceType: json['attendance_type'] ?? '',
      attendanceTypeDisplay: json['attendance_type_display'] ?? '',
    );
  }

  bool get isFaceBased => attendanceType == 'FACE_BASED';

  bool get isLocationBased => attendanceType == 'LOCATION_BASED';
}