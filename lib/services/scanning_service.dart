import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/scannings.dart';

class ScanningService {
  ScanningService._();

  static final ScanningService instance = ScanningService._();

  final _collection = FirebaseFirestore.instance.collection('scannings');

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (kDebugMode) {
        debugPrint('[ScanningService] Location services are disabled');
      }
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (kDebugMode) {
          debugPrint('[ScanningService] Location permissions are denied');
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (kDebugMode) {
        debugPrint(
          '[ScanningService] Location permissions are permanently denied',
        );
      }
      return false;
    }

    return true;
  }

  /// Get current location coordinates
  Future<Map<String, double>?> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      return {'latitude': position.latitude, 'longitude': position.longitude};
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ScanningService] Error getting location: $e');
      }
      return null;
    }
  }

  /// Create a new scanning record
  Future<Scanning> createScanning({
    required String studentId,
    required String subscriptionId,
    required String scannedBy,
    String? deviceInfo,
    String? notes,
  }) async {
    try {
      // Get current location
      final location = await getCurrentLocation();

      final now = DateTime.now();
      final docRef = _collection.doc();

      final scanning = Scanning(
        id: docRef.id,
        studentId: studentId,
        subscriptionId: subscriptionId,
        scannedAt: now,
        scannedBy: scannedBy,
        latitude: location?['latitude'],
        longitude: location?['longitude'],
        createdAt: now,
        deviceInfo: deviceInfo,
        notes: notes,
      );

      await docRef.set(scanning.toMap());

      if (kDebugMode) {
        debugPrint('[ScanningService] Created scanning ${docRef.id}');
        if (location != null) {
          debugPrint('[ScanningService] Location: ${scanning.locationString}');
        }
      }

      return scanning;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ScanningService] createScanning error: $e');
      }
      rethrow;
    }
  }

  /// Get scannings for a specific student
  Stream<List<Scanning>> streamStudentScannings(String studentId) {
    return _collection
        .where('studentId', isEqualTo: studentId)
        .orderBy('scannedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            return Scanning.fromMap(data);
          }).toList();
        });
  }

  /// Get last scan for a student
  Future<Scanning?> getLastScan(String studentId) async {
    try {
      final snapshot = await _collection
          .where('studentId', isEqualTo: studentId)
          .orderBy('scannedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final data = Map<String, dynamic>.from(snapshot.docs.first.data());
      data['id'] = snapshot.docs.first.id;
      return Scanning.fromMap(data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ScanningService] getLastScan error: $e');
      }
      return null;
    }
  }

  /// Get scannings for a specific subscription
  Stream<List<Scanning>> streamSubscriptionScannings(String subscriptionId) {
    return _collection
        .where('subscriptionId', isEqualTo: subscriptionId)
        .orderBy('scannedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            return Scanning.fromMap(data);
          }).toList();
        });
  }

  /// Fetch scannings for a specific subscription (one-time)
  Future<List<Scanning>> fetchSubscriptionScannings(
    String subscriptionId,
  ) async {
    try {
      final snapshot = await _collection
          .where('subscriptionId', isEqualTo: subscriptionId)
          .orderBy('scannedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return Scanning.fromMap(data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ScanningService] fetchSubscriptionScannings error: $e');
      }
      rethrow;
    }
  }

  /// Get total scan count for a student
  Future<int> getStudentScanCount(String studentId) async {
    try {
      final snapshot = await _collection
          .where('studentId', isEqualTo: studentId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ScanningService] getStudentScanCount error: $e');
      }
      return 0;
    }
  }

  /// Delete a scanning record
  Future<void> deleteScanning(String id) async {
    try {
      await _collection.doc(id).delete();
      if (kDebugMode) {
        debugPrint('[ScanningService] Deleted scanning $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ScanningService] deleteScanning error: $e');
      }
      rethrow;
    }
  }

  /// Get all scannings (admin only)
  Stream<List<Scanning>> streamAllScannings() {
    return _collection.orderBy('scannedAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return Scanning.fromMap(data);
      }).toList();
    });
  }
}
