class Scanning {
  final String id;
  final String studentId;
  final String subscriptionId;
  final DateTime scannedAt;
  final String scannedBy; // Staff/Admin ID who performed the scan

  // Location data (GPS coordinates)
  final double? latitude;
  final double? longitude;

  // Metadata
  final DateTime createdAt;
  final String? deviceInfo; // Optional: device used for scanning
  final String? notes; // Optional: any notes about the scan

  Scanning({
    required this.id,
    required this.studentId,
    required this.subscriptionId,
    required this.scannedAt,
    required this.scannedBy,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.deviceInfo,
    this.notes,
  });

  factory Scanning.fromMap(Map<String, dynamic> map) {
    return Scanning(
      id: map['id'] as String,
      studentId: map['studentId'] as String,
      subscriptionId: map['subscriptionId'] as String,
      scannedAt: map['scannedAt'] is String
          ? DateTime.parse(map['scannedAt'])
          : (map['scannedAt'] as DateTime),
      scannedBy: map['scannedBy'] as String,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'])
          : (map['createdAt'] as DateTime),
      deviceInfo: map['deviceInfo'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'subscriptionId': subscriptionId,
      'scannedAt': scannedAt.toIso8601String(),
      'scannedBy': scannedBy,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'deviceInfo': deviceInfo,
      'notes': notes,
    };
  }

  /// Create a copy with updated fields
  Scanning copyWith({
    String? id,
    String? studentId,
    String? subscriptionId,
    DateTime? scannedAt,
    String? scannedBy,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    String? deviceInfo,
    String? notes,
  }) {
    return Scanning(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      scannedAt: scannedAt ?? this.scannedAt,
      scannedBy: scannedBy ?? this.scannedBy,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      notes: notes ?? this.notes,
    );
  }

  /// Check if scan has valid GPS coordinates
  bool get hasLocation => latitude != null && longitude != null;

  /// Get formatted location string
  String get locationString {
    if (!hasLocation) return 'Location unavailable';
    return '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}';
  }

  @override
  String toString() {
    return 'Scanning(id: $id, studentId: $studentId, subscriptionId: $subscriptionId, '
        'scannedAt: $scannedAt, scannedBy: $scannedBy, latitude: $latitude, '
        'longitude: $longitude, createdAt: $createdAt)';
  }
}

// Dummy data for testing purposes
final List<Scanning> dummyScannings = [
  Scanning(
    id: 'SCAN-001',
    studentId: 'STU-JOHN-DOE-A1B2',
    subscriptionId: 'SUB-2024F-JD-1734567890',
    scannedAt: DateTime.now().subtract(const Duration(hours: 1)),
    scannedBy: 'ADM-ADMIN-USER-C3D4',
    latitude: 3.8480,
    longitude: 11.5021,
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    deviceInfo: 'Android - Scanner App v1.0',
  ),
  Scanning(
    id: 'SCAN-002',
    studentId: 'STU-ALICE-BROWN-E5F6',
    subscriptionId: 'SUB-2024F-AB-1734567891',
    scannedAt: DateTime.now().subtract(const Duration(hours: 2)),
    scannedBy: 'ADM-ADMIN-USER-C3D4',
    latitude: 3.8667,
    longitude: 11.5167,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    deviceInfo: 'iOS - Scanner App v1.0',
  ),
  Scanning(
    id: 'SCAN-003',
    studentId: 'STU-JOHN-DOE-A1B2',
    subscriptionId: 'SUB-2024F-JD-1734567890',
    scannedAt: DateTime.now().subtract(const Duration(days: 1)),
    scannedBy: 'ADM-ADMIN-USER-C3D4',
    latitude: 3.8480,
    longitude: 11.5021,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

