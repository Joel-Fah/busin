import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/value_objects/bus_stop_selection.dart';
import '../utils/supabase_storage.dart';

class BusStopService {
  BusStopService._();

  static final BusStopService instance = BusStopService._();

  final _collection = FirebaseFirestore.instance.collection('stops');
  static const String _storageBucket = 'busin-bucket';

  /// Helper method to extract file path from URL or return null
  String? _extractStoragePathFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    try {
      final uri = Uri.parse(url);
      // Extract path after bucket name in Supabase URL
      // Expected format: /storage/v1/object/public/{bucket}/{path}
      final pathSegments = uri.pathSegments;

      // Find bucket name index
      final bucketIndex = pathSegments.indexOf(_storageBucket);
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        // Return everything after the bucket name (including 'stops/...')
        return pathSegments.sublist(bucketIndex + 1).join('/');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BusStopService] Error parsing URL: $e');
      }
    }
    return null;
  }

  /// Helper method to delete image from Supabase storage
  Future<void> _deleteImageFromStorage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;

    final storagePath = _extractStoragePathFromUrl(imageUrl);
    if (storagePath == null) return;

    try {
      final storage = Supabase.instance.client.storage.from(_storageBucket);
      await storage.remove([storagePath]);
      if (kDebugMode) {
        debugPrint('[BusStopService] Deleted image: $storagePath');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BusStopService] Error deleting image: $e');
      }
      // Don't rethrow - we don't want to fail the operation if image deletion fails
    }
  }

  /// Helper method to upload image to Supabase storage
  Future<String?> _uploadImage(String? localPath, String stopId) async {
    if (localPath == null || localPath.isEmpty) return null;

    // Check if it's already a URL (not a local file)
    if (localPath.startsWith('http://') || localPath.startsWith('https://')) {
      return localPath;
    }

    try {
      final file = File(localPath);
      if (!await file.exists()) {
        if (kDebugMode) {
          debugPrint('[BusStopService] File not found: $localPath');
        }
        return null;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = localPath.split('.').last;
      // Upload in stops folder: stops/{stopId}/{timestamp}.{extension}
      final objectPath = 'stops/$stopId/$timestamp.$extension';

      final publicUrl = await uploadFileToSupabaseStorage(
        file: file,
        bucket: _storageBucket,
        objectPath: objectPath,
        upsert: true,
      );

      if (kDebugMode) {
        debugPrint('[BusStopService] Uploaded image: $publicUrl');
      }

      return publicUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BusStopService] Error uploading image: $e');
      }
      rethrow;
    }
  }

  /// Create a new bus stop
  Future<BusStop> createBusStop(BusStop stop, String currentUserId) async {
    try {
      // Generate document reference and ID
      final docRef = _collection.doc();
      final stopId = docRef.id;
      final now = DateTime.now();

      // Upload image to Supabase if provided
      String? uploadedImageUrl;
      if (stop.pickupImageUrl != null && stop.pickupImageUrl!.isNotEmpty) {
        uploadedImageUrl = await _uploadImage(stop.pickupImageUrl, stopId);
      }

      // Create stop with metadata
      final newStop = BusStop(
        id: stopId,
        name: stop.name,
        pickupImageUrl: uploadedImageUrl,
        mapEmbedUrl: stop.mapEmbedUrl,
        createdAt: now,
        updatedAt: now,
        createdBy: currentUserId,
        updatedBy: const [],
      );

      // Save to Firestore
      await docRef.set(newStop.toMap());

      if (kDebugMode) {
        debugPrint('[BusStopService] Created bus stop $stopId');
      }

      return newStop;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BusStopService] createBusStop error: $e');
      }
      rethrow;
    }
  }

  /// Update an existing bus stop
  Future<void> updateBusStop(BusStop stop, String currentUserId) async {
    try {
      // Fetch the current stop to get the old image URL and metadata
      final currentDoc = await _collection.doc(stop.id).get();
      final currentData = currentDoc.data();
      final oldImageUrl = currentData?['pickupImageUrl'] as String?;

      // Handle image update
      String? newImageUrl = stop.pickupImageUrl;

      // If there's a new local image path, upload it
      if (newImageUrl != null &&
          newImageUrl.isNotEmpty &&
          !newImageUrl.startsWith('http://') &&
          !newImageUrl.startsWith('https://')) {
        // Upload the new image
        newImageUrl = await _uploadImage(newImageUrl, stop.id);

        // Delete the old image if it exists and is different
        if (oldImageUrl != null && oldImageUrl != newImageUrl) {
          await _deleteImageFromStorage(oldImageUrl);
        }
      } else if (newImageUrl == null || newImageUrl.isEmpty) {
        // If the new image is null/empty, delete the old one
        if (oldImageUrl != null) {
          await _deleteImageFromStorage(oldImageUrl);
        }
      }

      // Handle updatedBy list - only add if not already the last updater
      List<String> updatedByList = List<String>.from(stop.updatedBy);
      if (updatedByList.isEmpty || updatedByList.last != currentUserId) {
        updatedByList.add(currentUserId);
      }

      // Update the stop with the new image URL, updatedAt, and updatedBy
      final updatedStop = stop.copyWith(
        pickupImageUrl: newImageUrl,
        updatedAt: DateTime.now(),
        updatedBy: updatedByList,
      );

      await _collection.doc(stop.id).update(updatedStop.toMap());

      if (kDebugMode) {
        debugPrint('[BusStopService] Updated bus stop ${stop.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BusStopService] updateBusStop error: $e');
      }
      rethrow;
    }
  }

  /// Delete a bus stop
  Future<void> deleteBusStop(String id) async {
    try {
      // Fetch the stop to get the image URL before deletion
      final doc = await _collection.doc(id).get();
      final data = doc.data();
      final imageUrl = data?['pickupImageUrl'] as String?;

      // Delete the image from Supabase storage if it exists
      if (imageUrl != null) {
        await _deleteImageFromStorage(imageUrl);
      }

      // Delete the document from Firestore
      await _collection.doc(id).delete();

      if (kDebugMode) {
        debugPrint('[BusStopService] Deleted bus stop $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BusStopService] deleteBusStop error: $e');
      }
      rethrow;
    }
  }

  /// Fetch a single bus stop by ID
  Future<BusStop?> fetchBusStop(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;

      final map = Map<String, dynamic>.from(doc.data()!);
      map['stopId'] = doc.id;
      return BusStop.fromMap(map);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BusStopService] fetchBusStop error: $e');
      }
      rethrow;
    }
  }

  /// Watch all bus stops (real-time updates)
  Stream<List<BusStop>> watchBusStops() {
    return _collection
        .orderBy('stopName')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['stopId'] = doc.id;
        return BusStop.fromMap(data);
      }).toList();
    });
  }

  /// Fetch all bus stops once
  Future<List<BusStop>> fetchAllBusStops() async {
    try {
      final snapshot = await _collection.orderBy('stopName').get();
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['stopId'] = doc.id;
        return BusStop.fromMap(data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BusStopService] fetchAllBusStops error: $e');
      }
      rethrow;
    }
  }

  /// Search bus stops by name
  Future<List<BusStop>> searchBusStops(String query) async {
    try {
      final snapshot = await _collection
          .orderBy('stopName')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .get();

      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['stopId'] = doc.id;
        return BusStop.fromMap(data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BusStopService] searchBusStops error: $e');
      }
      rethrow;
    }
  }
}

