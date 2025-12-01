class RegisterRequest {
  final String email;
  final String password;
  final String confirmPassword;
  final String role;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      "email": email,
      "password": password,
      "confirm_password": confirmPassword,
      "role": role,
    };
  }
}
