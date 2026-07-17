class ReviewModel {
  final String id;
  final String customerId;
  final String userName;
  final String? userImage;
  final double rating;
  final String comment;
  final DateTime date;

  ReviewModel({
    required this.id,
    required this.customerId,
    required this.userName,
    this.userImage,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final customerMap = json['customer'] as Map<String, dynamic>?;
    final userName = customerMap?['name'] as String? ?? 'Anonymous';
    final userImage = customerMap?['image'] as String?;

    return ReviewModel(
      id: json['id'] as String,
      customerId: json['customerId'] as String? ?? json['customer_id'] as String? ?? '',
      userName: userName,
      userImage: userImage,
      rating: (json['rating'] is String) ? double.parse(json['rating']) : (json['rating'] as num).toDouble(),
      comment: json['comment'] as String? ?? '',
      date: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
