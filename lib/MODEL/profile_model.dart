class ProfileModel {
  final String firstName;
  final String lastName;
  final String email;
  final String designation;
  final String phoneNumber;
  final String organizationName;
  final String faceImage;

  ProfileModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.designation,
    required this.phoneNumber,
    required this.organizationName,
    required this.faceImage,
  });

  factory ProfileModel.fromJson(
      Map<String, dynamic> json) {
    final member =
        json['member'] ?? {};

    return ProfileModel(
      firstName:
          member['first_name'] ??
              '',
      lastName:
          member['last_name'] ??
              '',
      email:
          member['email'] ?? '',
      designation:
          member['designation'] ??
              '',
      phoneNumber:
          member['phone_number'] ??
              '',
      organizationName:
          member['organization']
                  ?['name'] ??
              '',
      faceImage:
          member['face_image_1'] ??
              '',
    );
  }

  String get fullName =>
      '$firstName $lastName';
}