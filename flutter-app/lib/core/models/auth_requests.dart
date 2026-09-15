/// Authentication request models matching ASP.NET Core backend DTOs.
class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'email': email.trim(),
        'password': password,
      };
}

class RegisterParentRequest {
  final String fullName;
  final String email;
  final String password;
  final String? phoneNumber;

  const RegisterParentRequest({
    required this.fullName,
    required this.email,
    required this.password,
    this.phoneNumber,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName.trim(),
        'email': email.trim(),
        'password': password,
        if (phoneNumber != null && phoneNumber!.trim().isNotEmpty)
          'phoneNumber': phoneNumber!.trim(),
      };
}
