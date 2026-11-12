import 'dart:convert';
import 'dart:typed_data';

import 'package:busin_core/busin_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Today's riders on this phone (ADR 0014): each one's day key and what the result card shows. Valid for one school
/// day only; [keyFor] refuses any other day.
class Roster {
  Roster({required this.day, required this.downloadedAt, required List<RiderKey> riders})
      : _byId = {for (final r in riders) r.studentId: r};

  /// The school day the keys are for (a plain date).
  final DateTime day;
  final DateTime downloadedAt;
  final Map<String, RiderKey> _byId;

  int get length => _byId.length;

  RiderKey? rider(String studentId) => _byId[studentId];

  /// The day key of [studentId] for [date], or null when they are not on the list or it is another day.
  Uint8List? keyFor(String studentId, DateTime date) => _sameDay(date, day) ? _byId[studentId]?.dayKey : null;

  bool isFor(DateTime date) => _sameDay(date, day);

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Map<String, dynamic> toJson() => {
        'day': QrCodeGenerator.dateLabel(day),
        'downloaded_at': downloadedAt.toUtc().toIso8601String(),
        'riders': [
          for (final r in _byId.values)
            {
              'student_id': r.studentId,
              'day_key': base64.encode(r.dayKey),
              'full_name': r.fullName,
              'avatar_url': r.avatarUrl,
              'matricule': r.matricule,
              'stop_id': r.stopId,
              'day': QrCodeGenerator.dateLabel(r.day),
            },
        ],
      };

  factory Roster.fromJson(Map<String, dynamic> json) {
    final parts = (json['day'] as String).split('-').map(int.parse).toList();
    return Roster(
      day: DateTime(parts[0], parts[1], parts[2]),
      downloadedAt: DateTime.parse(json['downloaded_at'] as String),
      riders: (json['riders'] as List).cast<Map<String, dynamic>>().map(RiderKey.fromJson).toList(),
    );
  }

  /// Builds today's roster from a download; the day comes from the rows (the server's school day).
  factory Roster.fromDownload(List<RiderKey> riders, {required DateTime today, required DateTime now}) {
    final day = riders.isEmpty ? today : DateTime(riders.first.day.year, riders.first.day.month, riders.first.day.day);
    return Roster(day: day, downloadedAt: now, riders: riders);
  }
}

/// Where the roster is kept. The keys are secrets, so secure storage; one roster per signed-in staff member.
abstract interface class RosterStore {
  Future<Roster?> load(String userId);
  Future<void> save(String userId, Roster roster);
  Future<void> clear();
}

class SecureRosterStore implements RosterStore {
  SecureRosterStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _prefix = 'roster.';

  @override
  Future<Roster?> load(String userId) async {
    final raw = await _storage.read(key: '$_prefix$userId');
    if (raw == null) return null;
    try {
      return Roster.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Damaged or from another version: forget it, the next download replaces it.
      await _storage.delete(key: '$_prefix$userId');
      return null;
    }
  }

  @override
  Future<void> save(String userId, Roster roster) => _storage.write(key: '$_prefix$userId', value: jsonEncode(roster.toJson()));

  @override
  Future<void> clear() async {
    final all = await _storage.readAll();
    for (final key in all.keys.where((k) => k.startsWith(_prefix))) {
      await _storage.delete(key: key);
    }
  }
}
