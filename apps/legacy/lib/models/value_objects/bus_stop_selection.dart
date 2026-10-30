import 'package:equatable/equatable.dart';

/// Value object representing the stop a subscription is tied to.
class BusStop extends Equatable {
  final String id;
  final String name;
  final String? pickupImageUrl;
  final String? mapEmbedUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final List<String> updatedBy;

  const BusStop({
    required this.id,
    required this.name,
    this.pickupImageUrl,
    this.mapEmbedUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.updatedBy = const [],
  }) : assert(name != '');

  bool get isValid => id.isNotEmpty && id.trim().isNotEmpty && name.trim().isNotEmpty;

  bool get hasImage =>
      pickupImageUrl != null && pickupImageUrl!.trim().isNotEmpty;

  bool get hasMapEmbed =>
      mapEmbedUrl != null && mapEmbedUrl!.trim().isNotEmpty;

  Map<String, dynamic> toMap() => {
    'stopId': id,
    'stopName': name,
    if (pickupImageUrl != null) 'pickupImageUrl': pickupImageUrl,
    if (mapEmbedUrl != null) 'mapEmbedUrl': mapEmbedUrl,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'createdBy': createdBy,
    'updatedBy': updatedBy,
  };

  factory BusStop.fromMap(Map<String, dynamic> map) => BusStop(
    id: map['stopId'] as String,
    name: map['stopName'] as String,
    pickupImageUrl: map['pickupImageUrl'] as String?,
    mapEmbedUrl: map['mapEmbedUrl'] as String?,
    createdAt: DateTime.parse(map['createdAt'] as String),
    updatedAt: DateTime.parse(map['updatedAt'] as String),
    createdBy: map['createdBy'] as String,
    updatedBy: map['updatedBy'] != null
        ? List<String>.from(map['updatedBy'] as List)
        : [],
  );

  static BusStop? maybeFromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final stopId = map['stopId'] as String?;
    final stopName = map['stopName'] as String?;
    if (stopId == null || stopName == null) return null;
    if (stopId.isEmpty || stopName.isEmpty) return null;

    try {
      return BusStop(
        id: stopId,
        name: stopName,
        pickupImageUrl: map['pickupImageUrl'] as String?,
        mapEmbedUrl: map['mapEmbedUrl'] as String?,
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : DateTime.now(),
        updatedAt: map['updatedAt'] != null
            ? DateTime.parse(map['updatedAt'] as String)
            : DateTime.now(),
        createdBy: (map['createdBy'] as String?) ?? 'unknown',
        updatedBy: map['updatedBy'] != null
            ? List<String>.from(map['updatedBy'] as List)
            : [],
      );
    } catch (e) {
      return null;
    }
  }

  BusStop copyWith({
    String? id,
    String? name,
    String? pickupImageUrl,
    String? mapEmbedUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    List<String>? updatedBy,
  }) => BusStop(
    id: id ?? this.id,
    name: name ?? this.name,
    pickupImageUrl: pickupImageUrl ?? this.pickupImageUrl,
    mapEmbedUrl: mapEmbedUrl ?? this.mapEmbedUrl,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    createdBy: createdBy ?? this.createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    pickupImageUrl,
    mapEmbedUrl,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
  ];
}

// Dummy bus stops
List<BusStop> dummyBusStops = [
  BusStop(
    id: 'stop_001',
    name: 'Shell Nsimeyong',
    pickupImageUrl: 'https://example.com/stops/shell_nsimeyong.jpg',
    mapEmbedUrl: 'https://maps.app.goo.gl/xyz123',
    createdAt: DateTime(2024, 1, 15),
    updatedAt: DateTime(2024, 1, 15),
    createdBy: 'user_123',
  ),
  BusStop(
    id: 'stop_002',
    name: 'Obili',
    createdAt: DateTime(2024, 1, 16),
    updatedAt: DateTime(2024, 1, 16),
    createdBy: 'user_123',
  ),
  BusStop(
    id: 'stop_003',
    name: 'Vogt',
    pickupImageUrl: 'https://example.com/stops/vogt.jpg',
    createdAt: DateTime(2024, 1, 17),
    updatedAt: DateTime(2024, 1, 17),
    createdBy: 'user_456',
    updatedBy: ['user_456', 'user_123'],
  ),
  BusStop(
    id: 'stop_004',
    name: 'Poste Centrale',
    mapEmbedUrl: 'https://maps.app.goo.gl/F9Mn2rJWcizkAu9h9',
    createdAt: DateTime(2024, 1, 18),
    updatedAt: DateTime(2024, 1, 18),
    createdBy: 'user_123',
  ),
  BusStop(
    id: 'stop_005',
    name: 'Bata Nlongkak',
    createdAt: DateTime(2024, 1, 19),
    updatedAt: DateTime(2024, 1, 19),
    createdBy: 'user_789',
  ),
  BusStop(
    id: 'stop_006',
    name: 'Etoudi Palais',
    createdAt: DateTime(2024, 1, 20),
    updatedAt: DateTime(2024, 1, 20),
    createdBy: 'user_123',
  ),
  BusStop(
    id: 'stop_007',
    name: 'ICT University (Campus)',
    pickupImageUrl: 'https://example.com/stops/ict_campus.jpg',
    mapEmbedUrl: 'https://maps.app.goo.gl/abc456',
    createdAt: DateTime(2024, 1, 21),
    updatedAt: DateTime(2024, 1, 21),
    createdBy: 'user_456',
    updatedBy: ['user_456'],
  ),
];
