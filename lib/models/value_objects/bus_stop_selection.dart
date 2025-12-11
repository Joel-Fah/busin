import 'package:equatable/equatable.dart';

/// Value object representing the stop a subscription is tied to.
class BusStop extends Equatable {
  final String id;
  final String name;
  final String? pickupImageUrl;
  final String? mapEmbedUrl;

  const BusStop({
    required this.id,
    required this.name,
    this.pickupImageUrl,
    this.mapEmbedUrl,
  }) : assert(id != ''),
       assert(name != '');

  bool get isValid => id.trim().isNotEmpty && name.trim().isNotEmpty;


  bool get hasImage =>
      pickupImageUrl != null && pickupImageUrl!.trim().isNotEmpty;

  bool get hasMapEmbed =>
      mapEmbedUrl != null && mapEmbedUrl!.trim().isNotEmpty;

  Map<String, dynamic> toMap() => {
    'stopId': id,
    'stopName': name,
    if (pickupImageUrl != null) 'pickupImageUrl': pickupImageUrl,
    if (mapEmbedUrl != null) 'mapEmbedUrl': mapEmbedUrl,
  };

  factory BusStop.fromMap(Map<String, dynamic> map) => BusStop(
    id: map['stopId'] as String,
    name: map['stopName'] as String,
    pickupImageUrl: map['pickupImageUrl'] as String?,
    mapEmbedUrl: map['mapEmbedUrl'] as String?,
  );

  static BusStop? maybeFromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final stopId = map['stopId'] as String?;
    final stopName = map['stopName'] as String?;
    if (stopId == null || stopName == null) return null;
    if (stopId.isEmpty || stopName.isEmpty) return null;
    return BusStop(
      id: stopId,
      name: stopName,
      pickupImageUrl: map['pickupImageUrl'] as String?,
      mapEmbedUrl: map['mapEmbedUrl'] as String?,
    );
  }

  BusStop copyWith({
    String? id,
    String? name,
    String? pickupImageUrl,
    String? mapEmbedUrl,
  }) => BusStop(
    id: id ?? this.id,
    name: name ?? this.name,
    pickupImageUrl: pickupImageUrl ?? this.pickupImageUrl,
    mapEmbedUrl: mapEmbedUrl ?? this.mapEmbedUrl,
  );

  @override
  List<Object?> get props => [id, name, pickupImageUrl, mapEmbedUrl];
}

// Dummy bus stops
List<BusStop> dummyBusStops = [
  BusStop(
    id: 'stop_001',
    name: 'Shell Nsimeyong',
    pickupImageUrl: 'https://example.com/stops/shell_nsimeyong.jpg',
    mapEmbedUrl: 'https://maps.app.goo.gl/xyz123',
  ),
  BusStop(
    id: 'stop_002',
    name: 'Obili',
  ),
  BusStop(
    id: 'stop_003',
    name: 'Vogt',
    pickupImageUrl: 'https://example.com/stops/vogt.jpg',
  ),
  BusStop(
    id: 'stop_004',
    name: 'Poste Centrale',
    mapEmbedUrl: 'https://maps.app.goo.gl/F9Mn2rJWcizkAu9h9',
  ),
  BusStop(id: 'stop_005', name: 'Bata Nlongkak'),
  BusStop(
    id: 'stop_006',
    name: 'Etoudi Palais',
  ),
  BusStop(
    id: 'stop_007',
    name: 'ICT University (Campus)',
    pickupImageUrl: 'https://example.com/stops/ict_campus.jpg',
    mapEmbedUrl: 'https://maps.app.goo.gl/abc456',
  ),
];
