import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility class for generating custom, human-readable IDs for Firestore documents
class IdGenerator {
  IdGenerator._();

  /// Generate subscription ID
  /// Format: SUB-{YEAR}{SEMESTER}-{STUDENT_INITIALS}-{TIMESTAMP}
  /// Example: SUB-2024F-JD-1734567890
  static String generateSubscriptionId({
    required String studentName,
    required int year,
    required String semester, // F (Fall), S (Spring), etc.
  }) {
    final initials = _extractInitials(studentName);
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000; // Unix timestamp in seconds
    return 'SUB-$year$semester-$initials-$timestamp';
  }

  /// Generate bus stop ID
  /// Format: STOP-{NAME_SLUG}-{SHORT_HASH}
  /// Example: STOP-POSTE-CENTRALE-A1B2
  static String generateBusStopId(String stopName) {
    final slug = _slugify(stopName);
    final hash = _generateShortHash();
    return 'STOP-$slug-$hash';
  }

  /// Generate user ID (student)
  /// Format: STU-{EMAIL_PREFIX}-{SHORT_HASH}
  /// Example: STU-JOHN-DOE-A1B2
  static String generateStudentId(String email) {
    final emailPrefix = email.split('@').first;
    final slug = _slugify(emailPrefix);
    final hash = _generateShortHash();
    return 'STU-$slug-$hash';
  }

  /// Generate user ID (admin)
  /// Format: ADM-{EMAIL_PREFIX}-{SHORT_HASH}
  /// Example: ADM-ADMIN-USER-A1B2
  static String generateAdminId(String email) {
    final emailPrefix = email.split('@').first;
    final slug = _slugify(emailPrefix);
    final hash = _generateShortHash();
    return 'ADM-$slug-$hash';
  }

  /// Generate semester ID
  /// Format: SEM-{YEAR}{SEMESTER}
  /// Example: SEM-2024F
  static String generateSemesterId(int year, String semester) {
    return 'SEM-$year$semester';
  }

  /// Extract initials from a name
  /// Example: "John Doe" -> "JD"
  static String _extractInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'XX';

    if (parts.length == 1) {
      // Single name, take first two letters
      return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
    }

    // Take first letter of each part (up to 3)
    final initials = parts.take(3).map((p) => p[0]).join();
    return initials.toUpperCase();
  }

  /// Convert string to URL-friendly slug
  /// Example: "Poste Centrale" -> "POSTE-CENTRALE"
  static String _slugify(String text) {
    return text
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '') // Remove special chars
        .replaceAll(RegExp(r'\s+'), '-') // Replace spaces with hyphens
        .replaceAll(RegExp(r'-+'), '-') // Replace multiple hyphens with single
        .substring(0, text.length.clamp(0, 20)); // Limit length
  }

  /// Generate a short hash based on timestamp
  /// Returns 4-character alphanumeric string
  static String _generateShortHash() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final hash = timestamp.hashCode.abs();
    final chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

    var result = '';
    var value = hash;
    for (var i = 0; i < 4; i++) {
      result += chars[value % chars.length];
      value ~/= chars.length;
    }

    return result;
  }

  /// Check if an ID already exists in Firestore collection
  static Future<bool> idExists(String collection, String id) async {
    final doc = await FirebaseFirestore.instance.collection(collection).doc(id).get();
    return doc.exists;
  }

  /// Generate unique ID with collision check
  /// If ID exists, append incremental suffix
  static Future<String> generateUniqueId({
    required String collection,
    required String baseId,
    int maxAttempts = 10,
  }) async {
    var currentId = baseId;
    var attempt = 0;

    while (attempt < maxAttempts) {
      final exists = await idExists(collection, currentId);
      if (!exists) {
        return currentId;
      }

      // Append incremental suffix
      attempt++;
      currentId = '$baseId-$attempt';
    }

    // Fallback to Firestore auto-generated ID if all attempts fail
    return FirebaseFirestore.instance.collection(collection).doc().id;
  }
}

