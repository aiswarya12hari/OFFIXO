class LeaveTypeModel {
  final int id;
  final String name;
  final String code;

  LeaveTypeModel({
    required this.id,
    required this.name,
    required this.code,
  });

  factory LeaveTypeModel.fromJson(Map<String, dynamic> json) {
    return LeaveTypeModel(
      id: json['id'],
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }
}