class BreakResponse {
  final bool success;
  final String message;

  BreakResponse({required this.success, required this.message});

  factory BreakResponse.fromJson(Map<String, dynamic> json) {
    return BreakResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}