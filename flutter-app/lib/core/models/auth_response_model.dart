/// Models for authentication responses strictly aligned with ASP.NET Core Mindora.Application.Features.Auth.

class AuthUserModel {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String profileId;

  const AuthUserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.profileId,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      email: (json['email'] ?? json['Email'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['FullName'] ?? '').toString(),
      role: (json['role'] ?? json['Role'] ?? '').toString(),
      profileId: (json['profileId'] ?? json['ProfileId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'role': role,
        'profileId': profileId,
      };
}

class AuthResponseModel {
  final String token;
  final DateTime? expiresAtUtc;
  final AuthUserModel user;
  final bool requiresEmailVerification;

  const AuthResponseModel({
    this.token = '',
    this.expiresAtUtc,
    this.user = const AuthUserModel(id: '', email: '', fullName: '', role: '', profileId: ''),
    this.requiresEmailVerification = false,
  });

  bool get hasToken => token.isNotEmpty;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final rawExpiry = json['expiresAtUtc'] ?? json['ExpiresAtUtc'];
    DateTime? parsedExpiry;
    if (rawExpiry != null) {
      parsedExpiry = DateTime.tryParse(rawExpiry.toString());
    }

    final rawUser = json['user'] ?? json['User'];
    final rawToken = json['token'] ?? json['Token'];
    final requiresVerification =
        json['requiresEmailVerification'] ?? json['RequiresEmailVerification'] ?? false;

    return AuthResponseModel(
      token: (rawToken ?? '').toString(),
      expiresAtUtc: parsedExpiry,
      user: rawUser != null && rawUser is Map
          ? AuthUserModel.fromJson(Map<String, dynamic>.from(rawUser))
          : const AuthUserModel(id: '', email: '', fullName: '', role: '', profileId: ''),
      requiresEmailVerification: requiresVerification is bool ? requiresVerification : false,
    );
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'expiresAtUtc': expiresAtUtc?.toIso8601String(),
        'user': user.toJson(),
        'requiresEmailVerification': requiresEmailVerification,
      };
}

class CurrentUserModel {
  final String userId;
  final String email;
  final String fullName;
  final String role;
  final String profileId;

  const CurrentUserModel({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.role,
    required this.profileId,
  });

  factory CurrentUserModel.fromJson(Map<String, dynamic> json) {
    return CurrentUserModel(
      userId: (json['userId'] ?? json['UserId'] ?? '').toString(),
      email: (json['email'] ?? json['Email'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['FullName'] ?? '').toString(),
      role: (json['role'] ?? json['Role'] ?? '').toString(),
      profileId: (json['profileId'] ?? json['ProfileId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'fullName': fullName,
        'role': role,
        'profileId': profileId,
      };
}

class ForgotPasswordResponseModel {
  final String message;
  final String status;
  final String? targetPlatform;

  const ForgotPasswordResponseModel({
    required this.message,
    required this.status,
    this.targetPlatform,
  });

  bool get isWrongPlatform => status == 'WrongPlatform';
  bool get canContinueReset => status == 'ContinueReset';

  factory ForgotPasswordResponseModel.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponseModel(
      message: (json['message'] ?? json['Message'] ?? '').toString(),
      status: (json['status'] ?? json['Status'] ?? 'ContinueReset').toString(),
      targetPlatform: json['targetPlatform']?.toString() ?? json['TargetPlatform']?.toString(),
    );
  }
}
