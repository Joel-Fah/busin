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

  factory ReviewObservation.fromMap(Map<String, dynamic> map) => ReviewObservation(
        reviewerUserId: map['reviewedByUserId'] as String,
        observedAt: DateTime.parse(map['reviewedAt'] as String),
        message: map['observation'] as String?,
      );
}

