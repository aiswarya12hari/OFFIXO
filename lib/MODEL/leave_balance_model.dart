class LeaveBalanceModel {
  final int leaveTypeId;
  final String leaveTypeName;
  final String leaveTypeCode;
  final double totalAllocated;
  final double usedLeaves;
  final double remainingBalance;

  LeaveBalanceModel({
    required this.leaveTypeId,
    required this.leaveTypeName,
    required this.leaveTypeCode,
    required this.totalAllocated,
    required this.usedLeaves,
    required this.remainingBalance,
  });

  factory LeaveBalanceModel.fromJson(Map<String, dynamic> json) {
    return LeaveBalanceModel(
      leaveTypeId: json['leave_type_id'],
      leaveTypeName: json['leave_type_name'],
      leaveTypeCode: json['leave_type_code'],
      totalAllocated: (json['total_allocated'] as num).toDouble(),
      usedLeaves: (json['used_leaves'] as num).toDouble(),
      remainingBalance: (json['remaining_balance'] as num).toDouble(),
    );
  }
}