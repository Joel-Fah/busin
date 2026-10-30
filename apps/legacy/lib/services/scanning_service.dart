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
    if (kDebugMode) {
      debugPrint('[ScanningService] ========== CREATING STREAM ==========');
      debugPrint('[ScanningService] Student ID: $studentId');
      debugPrint('[ScanningService] Collection: scannings');
      debugPrint('[ScanningService] Query: where(studentId == $studentId).orderBy(scannedAt, desc)');
    }

    try {
      return _collection
          .where('studentId', isEqualTo: studentId)
          .orderBy('scannedAt', descending: true)
          .snapshots()
          .handleError((error) {
            if (kDebugMode) {
              debugPrint('[ScanningService] ❌❌❌ STREAM ERROR ❌❌❌');
              debugPrint('[ScanningService] Error: $error');
              debugPrint('[ScanningService] Error Type: ${error.runtimeType}');
              debugPrint('[ScanningService] This might be due to missing Firestore index');
              debugPrint('[ScanningService] Create composite index: studentId (Asc) + scannedAt (Desc)');
              debugPrint('[ScanningService] ========================================');
            }
          })
          .map((snapshot) {
            if (kDebugMode) {
              debugPrint('[ScanningService] ========== SNAPSHOT RECEIVED ==========');
              debugPrint('[ScanningService] Timestamp: ${DateTime.now()}');
              debugPrint('[ScanningService] Number of documents: ${snapshot.docs.length}');
              debugPrint('[ScanningService] Snapshot metadata:');
              debugPrint('[ScanningService]   - isFromCache: ${snapshot.metadata.isFromCache}');
              debugPrint('[ScanningService]   - hasPendingWrites: ${snapshot.metadata.hasPendingWrites}');

              if (snapshot.docs.isNotEmpty) {
                debugPrint('[ScanningService] First document data:');
                final firstDoc = snapshot.docs.first;
                debugPrint('[ScanningService]   - Doc ID: ${firstDoc.id}');
                debugPrint('[ScanningService]   - Doc Data: ${firstDoc.data()}');
              } else {
                debugPrint('[ScanningService] ⚠️⚠️⚠️ EMPTY SNAPSHOT ⚠️⚠️⚠️');
                debugPrint('[ScanningService] No documents found for studentId: $studentId');
                debugPrint('[ScanningService] Please verify:');
                debugPrint('[ScanningService]   1. Scans exist in Firestore "scannings" collection');
                debugPrint('[ScanningService]   2. Documents have field "studentId" = "$studentId"');
                debugPrint('[ScanningService]   3. Field name spelling is correct (case-sensitive)');
              }
            }

            final scannings = snapshot.docs.map((doc) {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = doc.id;

              if (kDebugMode && snapshot.docs.indexOf(doc) == 0) {
                debugPrint('[ScanningService] Parsing first document to Scanning object...');
              }

              return Scanning.fromMap(data);
            }).toList();

            // Sort manually if needed
            scannings.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));

            if (kDebugMode) {
              debugPrint('[ScanningService] ✅ Returning ${scannings.length} scanning(s)');
              debugPrint('[ScanningService] ========================================');
            }

            return scannings;
          });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ScanningService] ❌ EXCEPTION while setting up stream: $e');
        debugPrint('[ScanningService] Attempting fallback without orderBy...');
      }

      // Return a stream without orderBy if index doesn't exist
      return _collection
          .where('studentId', isEqualTo: studentId)
          .snapshots()
          .map((snapshot) {
            if (kDebugMode) {
              debugPrint('[ScanningService] Fallback: Received ${snapshot.docs.length} documents (no orderBy)');
            }

            final scannings = snapshot.docs.map((doc) {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = doc.id;
              return Scanning.fromMap(data);
            }).toList();

            // Sort manually
            scannings.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));

            return scannings;
          });
    }
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

  /// Get total scan count performed by a staff member
  Future<int> getStaffScanCount(String staffId) async {
    try {
      final snapshot = await _collection
          .where('scannedBy', isEqualTo: staffId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ScanningService] getStaffScanCount error: $e');
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
