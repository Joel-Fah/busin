import 'package:busin_core/busin_core.dart';

import 'scan_queue.dart';

/// What one round of sending achieved.
class SyncReport {
  const SyncReport({this.accepted = 0, this.refused = 0, this.offline = false});

  final int accepted;
  final int refused;

  /// The round stopped because there is no connection; the rest waits for the next one.
  final bool offline;
}

/// Sends the queued scans to the server, oldest first, each with the time it was made and its own id, so a scan sent
/// twice is recorded once (ADR 0014). Stops at the first sign of no connection; never drops a scan.
class ScanSyncer {
  ScanSyncer({required this.queue, required this.scans});

  final ScanQueue queue;
  final ScansRepository scans;
  bool _running = false;

  Future<SyncReport> run() async {
    if (_running) return const SyncReport();
    _running = true;
    var accepted = 0;
    var refused = 0;
    try {
      while (true) {
        final batch = await queue.pending(limit: 20);
        if (batch.isEmpty) break;
        for (final scan in batch) {
          try {
            final outcome = await scans.recordScan(
              tripId: scan.tripId,
              code: scan.code,
              stopId: scan.stopId,
              location: scan.lat == null || scan.lng == null ? null : GeoPoint(scan.lat!, scan.lng!),
              accuracyMeters: scan.accuracy,
              scannedAt: scan.scannedAt,
              clientId: scan.clientId,
            );
            switch (outcome) {
              case ScanAccepted():
                await queue.markAccepted(scan.clientId);
                accepted++;
              case ScanRefused(:final reason):
                await queue.markRefused(scan.clientId, reason.wire);
                refused++;
            }
          } on Offline {
            return SyncReport(accepted: accepted, refused: refused, offline: true);
          } on Conflict {
            // The trip was not running at that time (or the stop went away): the server will never take it.
            await queue.markRefused(scan.clientId, 'trip_not_running');
            refused++;
          } on Invalid {
            await queue.markRefused(scan.clientId, 'invalid_scan');
            refused++;
          } on NotFound {
            await queue.markRefused(scan.clientId, 'trip_not_found');
            refused++;
          } catch (_) {
            // Anything else (a refused session, a server hiccup): stop this round and try again later, a few times
            // at most for this scan.
            await queue.markAttempt(scan.clientId);
            return SyncReport(accepted: accepted, refused: refused);
          }
        }
      }
      return SyncReport(accepted: accepted, refused: refused);
    } finally {
      _running = false;
    }
  }
}
