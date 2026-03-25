import 'package:changsure/data/models/address_model.dart';

class CustomerModel {
  final int id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  CustomerModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.avatarUrl,
  });

  String get fullName => '$firstName $lastName';

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] ?? 0,
      firstName: json['firstname'] ?? '',
      lastName: json['lastname'] ?? '',
      email: json['email'],
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
    );
  }

  /// 👇 สำหรับ PATCH / PUT profile
  Map<String, dynamic> toJson() {
    return {
      'firstname': firstName,
      'lastname': lastName,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
    };
  }

  CustomerModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? avatarUrl,
  }) {
    return CustomerModel(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

}

class ReviewBody {
  final int id;
  final int bookingId;
  final int customerId;
  final int serviceId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final List<ReviewImageBody> images;

  ReviewBody({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.serviceId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.images,
  });

  factory ReviewBody.fromJson(Map<String, dynamic> json) {
    return ReviewBody(
      id: json['id'],
      bookingId: json['booking_id'],
      customerId: json['customer_id'],
      serviceId: json['service_id'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
      images: (json['images'] as List<dynamic>)
          .map((e) => ReviewImageBody.fromJson(e))
          .toList(),
    );
  }
}

class ReviewImageBody {
  final int id;
  final int reviewId;
  final String imageUrl;

  ReviewImageBody({
    required this.id,
    required this.reviewId,
    required this.imageUrl,
  });

  factory ReviewImageBody.fromJson(Map<String, dynamic> json) {
    return ReviewImageBody(
      id: json['id'],
      reviewId: json['review_id'],
      imageUrl: json['image_url'],
    );
  }
}

class CreateReviewRequest {
  final int rating;
  final String? comment;
  final List<String>? images;

  CreateReviewRequest({
    required this.rating,
    this.comment,
     this.images,
  });

  Map<String, dynamic> toJson() {
    return {
      "rating": rating,
      "comment": comment,
      "images": images,
    };
  }
}


