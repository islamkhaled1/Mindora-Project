/// Strongly typed models for the Doctor Linking flow.
///
/// Maps directly to the ASP.NET Core backend:
/// - Request: `Mindora.Application.Features.Children.LinkDoctor.LinkDoctorByCodeRequest`
/// - Response: `Mindora.Application.Features.Children.Models.DoctorAssignmentDto`

class LinkDoctorRequest {
  final String doctorCode;

  const LinkDoctorRequest({required this.doctorCode});

  /// Safely strips any typed/pasted 'DR-', duplicate 'DR-DR-', spaces, and normalizes to uppercase.
  /// Example: "DR-7B6780AA" -> "7B6780AA"
  /// Example: "DR-DR-7B6780AA" -> "7B6780AA"
  /// Example: "  dr- 7b6780aa  " -> "7B6780AA"
  /// Example: "7B6780AA" -> "7B6780AA"
  static String cleanCodePart(String input) {
    var s = input.trim().toUpperCase().replaceAll(' ', '');
    while (s.startsWith('DR-') || s.startsWith('DR')) {
      if (s.startsWith('DR-')) {
        s = s.substring(3);
      } else if (s.startsWith('DR')) {
        s = s.substring(2);
      }
    }
    return s;
  }

  /// Builds the complete backend code value: DR-{codePart}
  static String formatFullCode(String input) {
    final part = cleanCodePart(input);
    if (part.isEmpty) return '';
    return 'DR-$part';
  }

  /// Validates whether the code part is valid alphanumeric (4-32 characters).
  static bool isValidCodePart(String input) {
    final part = cleanCodePart(input);
    if (part.isEmpty || part.length < 4 || part.length > 32) return false;
    final regex = RegExp(r'^[A-Z0-9]{4,32}$');
    return regex.hasMatch(part);
  }

  /// Normalizes doctor referral code for backend submission.
  static String normalizeCode(String input) {
    return formatFullCode(input);
  }

  /// Validates whether the code meets format requirements.
  static bool isValidCode(String input) {
    return isValidCodePart(input);
  }

  Map<String, dynamic> toJson() {
    return {
      'doctorCode': formatFullCode(doctorCode),
    };
  }

  @override
  String toString() => 'LinkDoctorRequest(doctorCode: ${formatFullCode(doctorCode)})';
}

class DoctorAssignmentModel {
  final String id;
  final String doctorId;
  final String childId;
  final String? parentId;
  final DateTime assignedAtUtc;
  final bool isActive;
  final String status;
  final String? specialization;
  final String? clinicName;
  final String? doctorName;

  const DoctorAssignmentModel({
    required this.id,
    required this.doctorId,
    required this.childId,
    this.parentId,
    required this.assignedAtUtc,
    required this.isActive,
    this.status = 'Pending',
    this.specialization,
    this.clinicName,
    this.doctorName,
  });

  factory DoctorAssignmentModel.fromJson(Map<String, dynamic> json) {
    return DoctorAssignmentModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      doctorId: (json['doctorId'] ?? json['DoctorId'] ?? '').toString(),
      childId: (json['childId'] ?? json['ChildId'] ?? '').toString(),
      parentId: (json['parentId'] ?? json['ParentId'])?.toString(),
      assignedAtUtc: json['createdAtUtc'] != null || json['CreatedAtUtc'] != null
          ? DateTime.tryParse((json['createdAtUtc'] ?? json['CreatedAtUtc']).toString()) ??
              DateTime.now().toUtc()
          : (json['assignedAtUtc'] != null || json['AssignedAtUtc'] != null
              ? DateTime.tryParse((json['assignedAtUtc'] ?? json['AssignedAtUtc']).toString()) ??
                  DateTime.now().toUtc()
              : DateTime.now().toUtc()),
      isActive: (json['isActive'] ?? json['IsActive'] ?? true) as bool,
      status: (json['status'] ?? json['Status'] ?? 'Pending').toString(),
      specialization: (json['specialization'] ?? json['Specialization'])?.toString(),
      clinicName: (json['clinicName'] ?? json['ClinicName'])?.toString(),
      doctorName: (json['doctorName'] ?? json['DoctorName'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorId': doctorId,
      'childId': childId,
      'parentId': parentId,
      'assignedAtUtc': assignedAtUtc.toIso8601String(),
      'isActive': isActive,
      'status': status,
      'specialization': specialization,
      'clinicName': clinicName,
      'doctorName': doctorName,
    };
  }

  @override
  String toString() {
    return 'DoctorAssignmentModel(id: $id, doctorName: $doctorName, clinicName: $clinicName, specialization: $specialization, isActive: $isActive)';
  }
}
