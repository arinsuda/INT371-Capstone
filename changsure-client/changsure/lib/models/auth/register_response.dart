class RegisterResponse {
  final int userId;
  final String email;
  final String role;
  final int createdAt;

  RegisterResponse({
    required this.userId,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      userId: json["user_id"] ?? 0,
      email: json["email"] ?? "",
      role: json["role"] ?? "",
      createdAt: json["created_at"] ?? 0,
    );
  }
}
