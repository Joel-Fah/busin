import 'package:equatable/equatable.dart';

/// Value object representing the stop a subscription is tied to.
class BusStopSelection extends Equatable {
  final String id;
  final String name;

  const BusStopSelection({required this.id, required this.name})
      : assert(id != ''),
        assert(name != '');

  bool get isValid => id.trim().isNotEmpty && name.trim().isNotEmpty;

  Map<String, dynamic> toMap() => {
        'stopId': id,
        'stopName': name,
      };

  factory BusStopSelection.fromMap(Map<String, dynamic> map) => BusStopSelection(
        id: map['stopId'] as String,
        name: map['stopName'] as String,
      );

  static BusStopSelection? maybeFromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final stopId = map['stopId'] as String?;
    final stopName = map['stopName'] as String?;
    if (stopId == null || stopName == null) return null;
    if (stopId.isEmpty || stopName.isEmpty) return null;
    return BusStopSelection(id: stopId, name: stopName);
  }

  BusStopSelection copyWith({String? id, String? name}) => BusStopSelection(
        id: id ?? this.id,
        name: name ?? this.name,
      );

  @override
  List<Object> get props => [id, name];
}

