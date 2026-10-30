import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/check_in.dart';

/// Firestore service for daily check-in lists.
///
/// Each day gets a single document in the `checkins` collection with ID
/// formatted as `YYYY-MM-DD`. Entries are stored as an array field for
/// simplicity and atomic updates.
class CheckInService {
  CheckInService._();
  static final CheckInService instance = CheckInService._();

  final _collection = FirebaseFirestore.instance.collection('checkins');

  // ── Helpers ──

  String _todayId() => CheckInList.idForDate(DateTime.now());

  // ── Create / Append ──

  /// Add a student to today's check-in list. Creates the document if it
  /// doesn't exist yet. Returns the new [CheckInEntry].
  Future<CheckInEntry> addEntry({
    required String studentId,
    required String studentName,
    String? studentPhotoUrl,
    required String subscriptionId,
    required String scannedBy,
    required String scannedByName,
    required CheckInPeriod period,
    String? notes,
  }) async {
    final docId = _todayId();
    final docRef = _collection.doc(docId);
    final now = DateTime.now();

    return FirebaseFirestore.instance
        .runTransaction<CheckInEntry>((tx) async {
          final snap = await tx.get(docRef);

          List<CheckInEntry> existingEntries = [];
          if (snap.exists) {
            final data = snap.data()!;
            existingEntries =
                (data['entries'] as List<dynamic>?)
                    ?.map(
                      (e) => CheckInEntry.fromMap(e as Map<String, dynamic>),
                    )
                    .toList() ??
                [];
          }

          // Filter entries for the same period to calculate arrival order
          final periodEntries = existingEntries
              .where((e) => e.period == period)
              .toList();
          final arrivalOrder = periodEntries.length + 1;

          final entryId = '${docId}_${period.value}_$arrivalOrder';

          final entry = CheckInEntry(
            id: entryId,
            studentId: studentId,
            studentName: studentName,
            studentPhotoUrl: studentPhotoUrl,
            subscriptionId: subscriptionId,
            scannedBy: scannedBy,
            scannedByName: scannedByName,
            period: period,
            arrivalOrder: arrivalOrder,
            scannedAt: now,
            notes: notes,
            createdAt: now,
          );

          final allEntries = [...existingEntries, entry];
          final uniqueStudents = allEntries
              .map((e) => e.studentId)
              .toSet()
              .length;

          final listData = {
            'id': docId,
            'date': CheckInList.idForDate(now),
            'entries': allEntries.map((e) => e.toMap()).toList(),
            'totalStudents': uniqueStudents,
            'createdAt': snap.exists
                ? snap.data()!['createdAt']
                : now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          };

          tx.set(docRef, listData);
          return entry;
        })
        .then((entry) {
          if (kDebugMode) {
            debugPrint(
              '[CheckInService] ✅ Added ${entry.studentName} (order #${entry.arrivalOrder})',
            );
          }
          return entry;
        });
  }

  // ── Read ──

  /// Stream today's check-in list in realtime.
  Stream<CheckInList?> streamTodayCheckIns() {
    return _collection.doc(_todayId()).snapshots().map((snap) {
      if (!snap.exists) return null;
      return CheckInList.fromMap(snap.data()!);
    });
  }

  /// Fetch today's check-in list once.
  Future<CheckInList?> fetchTodayCheckIns() async {
    final snap = await _collection.doc(_todayId()).get();
    if (!snap.exists) return null;
    return CheckInList.fromMap(snap.data()!);
  }

  /// Stream check-in history (all days), newest first.
  Stream<List<CheckInList>> streamCheckInHistory({int limit = 30}) {
    return _collection
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => CheckInList.fromMap(d.data())).toList(),
        );
  }

  /// Fetch a specific day's check-in list.
  Future<CheckInList?> fetchCheckInsForDate(DateTime date) async {
    final docId = CheckInList.idForDate(date);
    final snap = await _collection.doc(docId).get();
    if (!snap.exists) return null;
    return CheckInList.fromMap(snap.data()!);
  }

  // ── Delete ──

  /// Remove a single entry from today's list.
  Future<void> removeEntry(String entryId) async {
    final docRef = _collection.doc(_todayId());
    final snap = await docRef.get();
    if (!snap.exists) return;

    final list = CheckInList.fromMap(snap.data()!);
    final filtered = list.entries.where((e) => e.id != entryId).toList();
    final uniqueStudents = filtered.map((e) => e.studentId).toSet().length;

    await docRef.update({
      'entries': filtered.map((e) => e.toMap()).toList(),
      'totalStudents': uniqueStudents,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
