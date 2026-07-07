class UserModel {
  final String id;
  final String name;
  final String email;
  final String? role;
  final Map<String, dynamic>? address;

  UserModel({required this.id, required this.name, required this.email, this.role, this.address});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String?,
      address: json['address'] != null ? Map<String, dynamic>.from(json['address'] as Map) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'address': address,
      };
}
