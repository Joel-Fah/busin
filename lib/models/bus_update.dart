/// Represents the different types of updates students can submit
enum BusUpdateType {
  busLocation('bus_location'),
  payment('payment'),
  delay('delay'),
  general('general');

  final String value;
  const BusUpdateType(this.value);

  /// Parse a string value into a [BusUpdateType]
  static BusUpdateType from(String value) {
    return BusUpdateType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BusUpdateType.general,
    );
  }

  /// Human-readable label (English)
  String get labelEn {
    switch (this) {
      case BusUpdateType.busLocation:
        return 'Bus location update';
      case BusUpdateType.payment:
        return 'Payments update';
      case BusUpdateType.delay:
        return 'Delay update';
      case BusUpdateType.general:
        return 'General update';
    }
  }

  /// Human-readable label (French)
  String get labelFr {
    switch (this) {
      case BusUpdateType.busLocation:
        return 'Mise à jour de la position du bus';
      case BusUpdateType.payment:
        return 'Mise à jour des paiements';
      case BusUpdateType.delay:
        return 'Mise à jour de retard';
      case BusUpdateType.general:
        return 'Mise à jour générale';
    }
  }

  /// Get the label based on locale
  String label(String languageCode) {
    return languageCode == 'en' ? labelEn : labelFr;
  }

  /// Default prefill message for bus location type (English)
  String get prefillMessageEn {
    switch (this) {
      case BusUpdateType.busLocation:
        return 'The bus is currently at ';
      case BusUpdateType.payment:
        return '';
      case BusUpdateType.delay:
        return '';
      case BusUpdateType.general:
        return '';
    }
  }

  /// Default prefill message for bus location type (French)
  String get prefillMessageFr {
    switch (this) {
      case BusUpdateType.busLocation:
        return 'Le bus est actuellement à ';
      case BusUpdateType.payment:
        return '';
      case BusUpdateType.delay:
        return '';
      case BusUpdateType.general:
        return '';
    }
  }

  /// Get the prefill message based on locale
  String prefillMessage(String languageCode) {
    return languageCode == 'en' ? prefillMessageEn : prefillMessageFr;
  }

  /// Hint text for the input field (English)
  String get hintTextEn {
    switch (this) {
      case BusUpdateType.busLocation:
        return 'Enter street name or location...';
      case BusUpdateType.payment:
        return 'Share a payment update...';
      case BusUpdateType.delay:
        return 'Describe the delay situation...';
      case BusUpdateType.general:
        return 'Write your update...';
    }
  }

  /// Hint text for the input field (French)
  String get hintTextFr {
    switch (this) {
      case BusUpdateType.busLocation:
        return 'Entrez le nom de la rue ou le lieu...';
      case BusUpdateType.payment:
        return 'Partagez une mise à jour de paiement...';
      case BusUpdateType.delay:
        return 'Décrivez la situation de retard...';
      case BusUpdateType.general:
        return 'Écrivez votre mise à jour...';
    }
  }

  /// Get hint text based on locale
  String hintText(String languageCode) {
    return languageCode == 'en' ? hintTextEn : hintTextFr;
  }
}

/// Model representing a single bus update submitted by a student
class BusUpdate {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final BusUpdateType type;
  final String message;
  final DateTime createdAt;

  BusUpdate({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.type,
    required this.message,
    required this.createdAt,
  });

  factory BusUpdate.fromMap(Map<String, dynamic> map) {
    return BusUpdate(
      id: map['id'] as String,
      authorId: map['authorId'] as String,
      authorName: map['authorName'] as String,
      authorPhotoUrl: map['authorPhotoUrl'] as String?,
      type: BusUpdateType.from(map['type'] as String),
      message: map['message'] as String,
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'])
          : (map['createdAt'] as DateTime),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'type': type.value,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  BusUpdate copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorPhotoUrl,
    BusUpdateType? type,
    String? message,
    DateTime? createdAt,
  }) {
    return BusUpdate(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      type: type ?? this.type,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if this update was created today
  bool get isToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
  }

  @override
  String toString() =>
      'BusUpdate(id: $id, type: ${type.value}, message: $message, createdAt: $createdAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusUpdate && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
