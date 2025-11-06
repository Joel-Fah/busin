class Scanning {
  final String studentId;
  final String subscriptionId; // Links to a BusSubscription
  final DateTime scanTime;
  final String location;
  final String scannedBy;

  Scanning({
    required this.studentId,
    required this.subscriptionId,
    required this.scanTime,
    required this.location,
    required this.scannedBy,
  });

  factory Scanning.fromMap(Map<String, dynamic> map) {
    return Scanning(
      studentId: map['studentId'],
      subscriptionId: map['subscriptionId'],
      scanTime: DateTime.parse(map['scanTime']),
      location: map['location'],
      scannedBy: map['scannedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'subscriptionId': subscriptionId,
      'scanTime': scanTime.toIso8601String(),
      'location': location,
      'scannedBy': scannedBy,
    };
  }

  @override
  String toString() {
    return 'Scanning(studentId: $studentId, subscriptionId: $subscriptionId, scanTime: $scanTime, location: $location, scannedBy: $scannedBy)';
  }
}


// Dummy data for testing purposes
final List<Scanning> dummyScannings = [
  Scanning(
    studentId: 'S123456',
    subscriptionId: 'SUB001',
    scanTime: DateTime.now().subtract(Duration(hours: 1)),
    location: 'Shelle Nsimeyong',
    scannedBy: 'Staff001',
  ),
  Scanning(
    studentId: 'S789012',
    subscriptionId: 'SUB002',
    scanTime: DateTime.now().subtract(Duration(hours: 2)),
    location: 'Poste Centrale',
    scannedBy: 'Staff002',
  ),
];