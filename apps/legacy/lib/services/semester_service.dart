import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/semester_config.dart';

class SemesterService {
  SemesterService._();

  static final SemesterService instance = SemesterService._();

  final _collection = FirebaseFirestore.instance.collection('semesters');

  /// Fetch all semester configurations
  Stream<List<SemesterConfig>> streamAllSemesters() {
    return _collection
        .orderBy('year', descending: true)
        .orderBy('semester')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return SemesterConfig.fromMap(data);
          }).toList();
        });
  }

  /// Fetch all semester configurations (one-time)
  Future<List<SemesterConfig>> fetchAllSemesters() async {
    try {
      final snapshot = await _collection
          .orderBy('year', descending: true)
          .orderBy('semester')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return SemesterConfig.fromMap(data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SemesterService] fetchAllSemesters error: $e');
      }
      rethrow;
    }
  }

  /// Fetch a specific semester configuration
  Future<SemesterConfig?> fetchSemesterById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      data['id'] = doc.id;
      return SemesterConfig.fromMap(data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SemesterService] fetchSemesterById error: $e');
      }
      rethrow;
    }
  }

  /// Create a new semester configuration
  Future<SemesterConfig> createSemester(
    SemesterConfig config,
    String userId,
  ) async {
    try {
      // Use generated ID
      final id = SemesterConfig.generateId(config.semester, config.year);

      // Check if semester already exists
      final existing = await fetchSemesterById(id);
      if (existing != null) {
        throw Exception(
          'Semester ${config.semester.label} ${config.year} already exists',
        );
      }

      final now = DateTime.now();
      final newConfig = config.copyWith(
        id: id,
        createdBy: userId,
        createdAt: now,
        updatedAt: now,
        updatedBy: [],
      );

      await _collection.doc(id).set(newConfig.toMap());

      if (kDebugMode) {
        debugPrint('[SemesterService] Created semester: $id');
      }

      return newConfig;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SemesterService] createSemester error: $e');
      }
      rethrow;
    }
  }

  /// Update an existing semester configuration
  Future<SemesterConfig> updateSemester(
    SemesterConfig config,
    String userId,
  ) async {
    try {
      final now = DateTime.now();

      // Check if user is already in the updatedBy list
      final updatedByList = List<String>.from(config.updatedBy);
      if (!updatedByList.contains(userId)) {
        updatedByList.add(userId);
      }

      final updatedConfig = config.copyWith(
        updatedAt: now,
        updatedBy: updatedByList,
      );

      await _collection.doc(config.id).update(updatedConfig.toMap());

      if (kDebugMode) {
        debugPrint('[SemesterService] Updated semester: ${config.id}');
      }

      return updatedConfig;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SemesterService] updateSemester error: $e');
      }
      rethrow;
    }
  }

  /// Delete a semester configuration
  Future<void> deleteSemester(String id) async {
    try {
      await _collection.doc(id).delete();

      if (kDebugMode) {
        debugPrint('[SemesterService] Deleted semester: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SemesterService] deleteSemester error: $e');
      }
      rethrow;
    }
  }

  /// Fetch semesters for a specific year
  Future<List<SemesterConfig>> fetchSemestersByYear(int year) async {
    try {
      final snapshot = await _collection
          .where('year', isEqualTo: year)
          .orderBy('semester')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return SemesterConfig.fromMap(data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SemesterService] fetchSemestersByYear error: $e');
      }
      rethrow;
    }
  }

  /// Fetch active semester (current date falls within the semester dates)
  Future<SemesterConfig?> fetchActiveSemester() async {
    try {
      final allSemesters = await fetchAllSemesters();

      for (final semester in allSemesters) {
        if (semester.isActive) {
          return semester;
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SemesterService] fetchActiveSemester error: $e');
      }
      rethrow;
    }
  }
}
