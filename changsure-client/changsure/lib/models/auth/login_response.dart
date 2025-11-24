class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final int createdAt;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.createdAt,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json["access_token"] ?? "",
      refreshToken: json["refresh_token"] ?? "",
      createdAt: json["created_at"] ?? 0,
    );
  }
}
