import 'package:cloud_firestore/cloud_firestore.dart';

/// Captures the moderator/admin review observation for a subscription.
class ReviewObservation {
  final String reviewerUserId;
  final DateTime observedAt;
  final String? message;

  const ReviewObservation({
    required this.reviewerUserId,
    required this.observedAt,
    this.message,
  });

  bool get hasMessage => message != null && message!.trim().isNotEmpty;

  ReviewObservation copyWith({
    String? reviewerUserId,
    DateTime? observedAt,
    String? message,
  }) => ReviewObservation(
        reviewerUserId: reviewerUserId ?? this.reviewerUserId,
        observedAt: observedAt ?? this.observedAt,
        message: message ?? this.message,
      );

  Map<String, dynamic> toMap() => {
        'reviewedByUserId': reviewerUserId,
        'reviewedAt': observedAt.toIso8601String(),
        'observation': message,
      };

  factory ReviewObservation.fromMap(Map<String, dynamic> map) {
    return ReviewObservation(
      reviewerUserId: map['reviewedByUserId'] as String,
      observedAt: _parseDateTime(map['reviewedAt']),
      message: map['observation'] as String?,
    );
  }

  /// Helper method to parse DateTime from Firestore Timestamp or String
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    throw ArgumentError('Cannot parse DateTime from type ${value.runtimeType}');
  }
}
