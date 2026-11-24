class UserModel {
  final int userListId;
  final String fullName;
  final String roleName;
  final int roleId;
  final String email;
  final String phoneNumber;
  final int masterId;

  UserModel({
    required this.userListId,
    required this.fullName,
    required this.roleName,
    required this.roleId,
    required this.email,
    required this.phoneNumber,
    required this.masterId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userListId: json['userListId'] ?? 0,
      fullName: json['fullName'] ?? "",
      roleName: json['roleName'] ?? "",
      roleId: json['roleId'] ?? 0,
      email: json['email'] ?? "",
      phoneNumber: json['phoneNumber'] ?? "",
      masterId: json['masterId'] ?? 0,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'userListId': userListId,
      'fullName': fullName,
      'roleName': roleName,
      'roleId': roleId,
      'email': email,
      'phoneNumber': phoneNumber,
      'masterId': masterId,
    };
  }

  @override
  String toString() {
    return 'UserModel(id: $userListId, name: $fullName)';
  }
}
