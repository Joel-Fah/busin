import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/bus_update.dart';

class UpdateService {
  UpdateService._();

  static final UpdateService instance = UpdateService._();

  final _collection = FirebaseFirestore.instance.collection('updates');

  /// Submit a new update
  Future<BusUpdate> createUpdate({
    required String authorId,
    required String authorName,
    String? authorPhotoUrl,
    required BusUpdateType type,
    required String message,
  }) async {
    try {
      final now = DateTime.now();
      final docRef = _collection.doc();

      final update = BusUpdate(
        id: docRef.id,
        authorId: authorId,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
        type: type,
        message: message.trim(),
        createdAt: now,
      );

      await docRef.set(update.toMap());

      if (kDebugMode) {
        debugPrint('[UpdateService] Created update ${docRef.id}');
      }

      return update;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UpdateService] createUpdate error: $e');
      }
      rethrow;
    }
  }

  /// Stream today's updates in real-time, ordered by most recent first
  Stream<List<BusUpdate>> streamTodayUpdates() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    if (kDebugMode) {
      debugPrint('[UpdateService] Streaming today\'s updates');
      debugPrint('[UpdateService] Start: ${startOfDay.toIso8601String()}');
      debugPrint('[UpdateService] End: ${endOfDay.toIso8601String()}');
    }

    return _collection
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: startOfDay.toIso8601String(),
        )
        .where('createdAt', isLessThan: endOfDay.toIso8601String())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          if (kDebugMode) {
            debugPrint('[UpdateService] ❌ Stream error: $error');
          }
        })
        .map((snapshot) {
          if (kDebugMode) {
            debugPrint(
              '[UpdateService] Snapshot received: ${snapshot.docs.length} updates',
            );
          }
          return snapshot.docs
              .map((doc) => BusUpdate.fromMap(doc.data()))
              .toList();
        });
  }

  /// Stream all updates (for admin/staff overview)
  Stream<List<BusUpdate>> streamAllUpdates({int limit = 50}) {
    return _collection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .handleError((error) {
          if (kDebugMode) {
            debugPrint('[UpdateService] ❌ Stream all error: $error');
          }
        })
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => BusUpdate.fromMap(doc.data()))
              .toList();
        });
  }

  /// Get the count of today's updates (for badge)
  Stream<int> streamTodayUpdateCount() {
    return streamTodayUpdates().map((updates) => updates.length);
  }

  /// Delete an update (by the author or admin)
  Future<void> deleteUpdate(String updateId) async {
    try {
      await _collection.doc(updateId).delete();
      if (kDebugMode) {
        debugPrint('[UpdateService] Deleted update $updateId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UpdateService] deleteUpdate error: $e');
      }
      rethrow;
    }
  }
}
