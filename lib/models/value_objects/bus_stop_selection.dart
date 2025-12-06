import 'package:equatable/equatable.dart';

/// Value object representing the stop a subscription is tied to.
class BusStop extends Equatable {
  final String id;
  final String name;

  const BusStop({required this.id, required this.name})
      : assert(id != ''),
        assert(name != '');

  bool get isValid => id.trim().isNotEmpty && name.trim().isNotEmpty;

  Map<String, dynamic> toMap() => {
        'stopId': id,
        'stopName': name,
      };

  factory BusStop.fromMap(Map<String, dynamic> map) => BusStop(
        id: map['stopId'] as String,
        name: map['stopName'] as String,
      );

  static BusStop? maybeFromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final stopId = map['stopId'] as String?;
    final stopName = map['stopName'] as String?;
    if (stopId == null || stopName == null) return null;
    if (stopId.isEmpty || stopName.isEmpty) return null;
    return BusStop(id: stopId, name: stopName);
  }

  BusStop copyWith({String? id, String? name}) => BusStop(
        id: id ?? this.id,
        name: name ?? this.name,
      );

  @override
  List<Object> get props => [id, name];
}

// Dummy bus stops
List<BusStop> dummyBusStops = [
  BusStop(id: 'stop_001', name: 'Shell Nsimeyong'),
  BusStop(id: 'stop_002', name: 'Obili'),
  BusStop(id: 'stop_003', name: 'Vogt'),
  BusStop(id: 'stop_004', name: 'Poste Centrale'),
  BusStop(id: 'stop_005', name: 'Bata Nlongkak'),
  BusStop(id: 'stop_006', name: 'Etoudi Palais'),
  BusStop(id: 'stop_007', name: 'ICT University (Campus)'),
];