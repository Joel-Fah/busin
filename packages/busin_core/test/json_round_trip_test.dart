import 'package:busin_core/busin_core.dart';
import 'package:test/test.dart';

void main() {
  final created = DateTime.utc(2026, 11, 1, 8, 30);

  test('a profile reads back as it was written', () {
    final profile = Profile(
      id: 'u1',
      schoolId: 's1',
      email: 'a@school.edu',
      fullName: 'Ada Lovelace',
      role: UserRole.student,
      status: AccountStatus.verified,
      createdAt: created,
      updatedAt: created,
      phone: '677123456',
      matricule: 'ICT2026-0001',
      department: 'Computer Science',
      program: 'Bachelor',
      departmentId: 'd1',
      programId: 'p1',
      avatarUrl: 'https://example.com/a.png',
    );
    expect(Profile.fromJson(profile.toJson()), profile);
    final bare = Profile(id: 'u2', schoolId: 's1', email: 'b@school.edu', fullName: 'B', role: UserRole.staff, status: AccountStatus.pending, createdAt: created, updatedAt: created);
    expect(Profile.fromJson(bare.toJson()), bare);
  });

  test('a school reads back, active or not', () {
    const school = School(id: 's1', name: 'Test University', shortName: 'TU', timezone: 'Africa/Douala', isActive: true);
    expect(School.fromJson(school.toJson()), school);
    const inactive = School(id: 's2', name: 'Other', timezone: 'UTC', isActive: false);
    expect(School.fromJson(inactive.toJson()), inactive);
  });

  test('a semester keeps its calendar days', () {
    final semester = Semester(id: 'm1', schoolId: 's1', name: SemesterName.fall, year: 2026, startDate: DateTime.utc(2026, 9, 7), endDate: DateTime.utc(2027, 1, 29));
    expect(Semester.fromJson(semester.toJson()), semester);
  });

  test('a stop keeps its position', () {
    final stop = Stop(id: 'st1', schoolId: 's1', name: 'Etoudi palace road', location: GeoPoint(3.8975, 11.5189), active: true, photoPath: 's1/stop.webp');
    expect(Stop.fromJson(stop.toJson()), stop);
  });

  test('a subscription reads back with and without a review', () {
    final pending = Subscription(id: 'x1', schoolId: 's1', studentId: 'u1', semesterId: 'm1', stopId: 'st1', status: SubscriptionStatus.pending, createdAt: created, updatedAt: created);
    expect(Subscription.fromJson(pending.toJson()), pending);
    final reviewed = Subscription(
      id: 'x2',
      schoolId: 's1',
      studentId: 'u1',
      semesterId: 'm1',
      stopId: 'st1',
      status: SubscriptionStatus.revoked,
      proofPath: 's1/u1/proof.jpg',
      reviewNote: 'Receipt reversed',
      reviewedBy: 'a1',
      reviewedAt: created.add(const Duration(days: 1)),
      createdAt: created,
      updatedAt: created,
    );
    expect(Subscription.fromJson(reviewed.toJson()), reviewed);
  });
}
