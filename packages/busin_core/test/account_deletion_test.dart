import 'package:busin_core/busin_core.dart';
import 'package:test/test.dart';

void main() {
  test('reads a scheduled deletion and who asked', () {
    final mine = ScheduledDeletion.fromJson({'due_at': '2026-11-23T08:00:00Z', 'requested_at': '2026-11-16T08:00:00Z', 'requested_by': 'self'});
    expect(mine.dueAt, DateTime.utc(2026, 11, 23, 8));
    expect(mine.byPlatform, isFalse);
    expect(ScheduledDeletion.fromJson({'due_at': '2026-11-23T08:00:00Z', 'requested_by': 'platform'}).byPlatform, isTrue);
  });
}
