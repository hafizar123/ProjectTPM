class UserModel {
  final String email;
  final String username;
  final String? avatarBase64;

  UserModel({
    required this.email,
    required this.username,
    this.avatarBase64,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      avatarBase64: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'avatar_url': avatarBase64,
    };
  }
}
