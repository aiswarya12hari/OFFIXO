class ProfileModel {
  final int id;
  final String empNo;
  final String firstName;
  final String lastName;
  final String email;
  final String memberType;
  final String designation;
  final String phoneNumber;
  final String bloodGroup;
  final String gender;
  final String dateOfBirth;
  final String presentAddress;
  final String proofDocument;
  final bool isBiometricEnabled;
  final String faceImage1;
  final String faceImage2;
  final String faceImage3;
  final String faceImage4;
  final bool allowManualEntry;
  final bool isActive;
  final String organizationName;
  final String organizationType;
  final String organizationOwner;
  final String organizationAddress;
  final String organizationPhone;
  final String startDate;
  final String createdAt;
  final String updatedAt;

  ProfileModel({
    required this.id,
    required this.empNo,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.memberType,
    required this.designation,
    required this.phoneNumber,
    required this.bloodGroup,
    required this.gender,
    required this.dateOfBirth,
    required this.presentAddress,
    required this.proofDocument,
    required this.isBiometricEnabled,
    required this.faceImage1,
    required this.faceImage2,
    required this.faceImage3,
    required this.faceImage4,
    required this.allowManualEntry,
    required this.isActive,
    required this.organizationName,
    required this.organizationType,
    required this.organizationOwner,
    required this.organizationAddress,
    required this.organizationPhone,
    required this.startDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final member =
        json['member'] ?? {};

    final organization =
        member['organization'] ?? {};

    return ProfileModel(
      id: member['id'] ?? 0,
      empNo:
          member['emp_no'] ?? '',
      firstName:
          member['first_name'] ?? '',
      lastName:
          member['last_name'] ?? '',
      email:
          member['email'] ?? '',
      memberType:
          member['member_type'] ?? '',
      designation:
          member['designation'] ?? '',
      phoneNumber:
          member['phone_number'] ?? '',
      bloodGroup:
          member['blood_group'] ?? '',
      gender:
          member['gender'] ?? '',
      dateOfBirth:
          member['date_of_birth'] ?? '',
      presentAddress:
          member['present_address'] ?? '',
      proofDocument:
          member['proof_document'] ?? '',
      isBiometricEnabled:
          member['is_biometric_enabled'] ??
              false,
      faceImage1:
          member['face_image_1'] ?? '',
      faceImage2:
          member['face_image_2'] ?? '',
      faceImage3:
          member['face_image_3'] ?? '',
      faceImage4:
          member['face_image_4'] ?? '',
      allowManualEntry:
          member['allow_manual_entry'] ??
              false,
      isActive:
          member['is_active'] ?? false,
      organizationName:
          organization['name'] ?? '',
      organizationType:
          organization['organization_type'] ??
              '',
      organizationOwner:
          organization['organization_owner'] ??
              '',
      organizationAddress:
          organization['organization_address'] ??
              '',
      organizationPhone:
          organization['organization_phone'] ??
              '',
      startDate:
          member['start_date'] ?? '',
      createdAt:
          member['created_at'] ?? '',
      updatedAt:
          member['updated_at'] ?? '',
    );
  }

  String get fullName =>
      '$firstName $lastName';

  String get faceImage =>
      faceImage1;
}