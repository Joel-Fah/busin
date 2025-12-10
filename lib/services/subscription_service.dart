import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/subscription.dart';

class SubscriptionService {
  SubscriptionService._();

  static final SubscriptionService instance = SubscriptionService._();

  final _collection =
      FirebaseFirestore.instance.collection('subscriptions');

  Future<BusSubscription> createSubscription({
    required BusSubscription subscription,
    String? proofUrl,
  }) async {
    try {
      final docRef = subscription.id.isEmpty
          ? _collection.doc()
          : _collection.doc(subscription.id);
      var payload = subscription.id == docRef.id
          ? subscription
          : subscription.copyWith(id: docRef.id);

      if (proofUrl != null && proofUrl.isNotEmpty) {
        payload = payload.withProof(proofUrl);
      }

      final map = payload.toMap();
      await docRef.set(map);
      if (kDebugMode) {
        debugPrint('[SubscriptionService] Created subscription ${docRef.id}');
      }
      return payload;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SubscriptionService] createSubscription error: $e');
      }
      rethrow;
    }
  }

  Future<void> updateSubscription(BusSubscription subscription) async {
    try {
      final map = subscription
          .copyWith(updatedAt: DateTime.now())
          .toMap();
      await _collection.doc(subscription.id).update(map);
      if (kDebugMode) {
        debugPrint('[SubscriptionService] Updated subscription ${subscription.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SubscriptionService] updateSubscription error: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteSubscription(String id) async {
    try {
      await _collection.doc(id).delete();
      if (kDebugMode) {
        debugPrint('[SubscriptionService] Deleted subscription $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SubscriptionService] deleteSubscription error: $e');
      }
      rethrow;
    }
  }

  Stream<List<BusSubscription>> watchSubscriptions({
    String? studentId,
    BusSubscriptionStatus? status,
  }) {
    Query<Map<String, dynamic>> query =
        _collection.orderBy('createdAt', descending: true);
    if (studentId != null) {
      query = query.where('studentId', isEqualTo: studentId);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status.nameLower);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return BusSubscription.fromMap(data);
      }).toList();
    });
  }

  Future<BusSubscription?> fetchSubscription(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      final map = Map<String, dynamic>.from(doc.data()!);
      map['id'] = doc.id;
      return BusSubscription.fromMap(map);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SubscriptionService] fetchSubscription error: $e');
      }
      rethrow;
    }
  }
}
