class RiderModel {
  final String profileId;
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final String? vehicleType;
  final bool isAvailable;
  final bool isVerified;

  RiderModel({
    required this.profileId,
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    this.vehicleType,
    required this.isAvailable,
    required this.isVerified,
  });

  factory RiderModel.fromSupabase(Map<String, dynamic> data) {
    final userMap = data['user'] as Map<String, dynamic>? ?? {};
    return RiderModel(
      profileId: data['id'] as String? ?? '',
      userId: data['user_id'] as String? ?? '',
      name: userMap['name'] as String? ?? 'Unnamed Rider',
      email: userMap['email'] as String? ?? '',
      phone: userMap['phone'] as String?,
      vehicleType: data['vehicle_type'] as String?,
      isAvailable: data['is_available'] as bool? ?? false,
      isVerified: data['is_verified'] as bool? ?? false,
    );
  }
}
