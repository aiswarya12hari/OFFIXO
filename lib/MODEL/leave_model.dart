class LeaveModel {
  final int id;
  final int member;
  final String memberName;
  final String memberEmpNo;
  final int leaveType;
  final String leaveTypeName;
  final String fromDate;
  final String toDate;
  final String session;
  final String numberOfDays;
  final String reason;
  final String status;
  final String appliedAt;
  final String? reviewedBy;
  final String? reviewedByName;
  final String? reviewedAt;
  final String? rejectionReason;

  LeaveModel({
    required this.id,
    required this.member,
    required this.memberName,
    required this.memberEmpNo,
    required this.leaveType,
    required this.leaveTypeName,
    required this.fromDate,
    required this.toDate,
    required this.session,
    required this.numberOfDays,
    required this.reason,
    required this.status,
    required this.appliedAt,
    this.reviewedBy,
    this.reviewedByName,
    this.reviewedAt,
    this.rejectionReason,
  });

  factory LeaveModel.fromJson(Map<String, dynamic> json) {
    return LeaveModel(
      id: json['id'],
      member: json['member'],
      memberName: json['member_name'],
      memberEmpNo: json['member_emp_no'],
      leaveType: json['leave_type'],
      leaveTypeName: json['leave_type_name'],
      fromDate: json['from_date'],
      toDate: json['to_date'],
      session: json['session'],
      numberOfDays: json['number_of_days'],
      reason: json['reason'],
      status: json['status'],
      appliedAt: json['applied_at'],
      reviewedBy: json['reviewed_by']?.toString(),
      reviewedByName: json['reviewed_by_name'],
      reviewedAt: json['reviewed_at'],
      rejectionReason: json['rejection_reason'],
    );
  }
}