import 'dart:async';

import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/auth/auth_service.dart';
import 'package:busin_student/src/providers.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

Profile profile({
  String id = 'u1',
  UserRole role = UserRole.student,
  AccountStatus status = AccountStatus.verified,
}) =>
    Profile(
      id: id,
      schoolId: 's1',
      email: '$id@school.edu',
      fullName: 'Test Person',
      role: role,
      status: status,
      createdAt: DateTime.utc(2026, 11, 1),
      updatedAt: DateTime.utc(2026, 11, 1),
    );

/// A fake sign-in that also plays the server: [accounts] maps the Google account used to the profile it gets.
class FakeAuthService implements AuthService {
  FakeAuthService({String? signedInAs, this.failWith}) : _userId = signedInAs;

  String? _userId;
  SignInFailure? failWith;
  int signOuts = 0;
  final _changes = StreamController<String?>.broadcast();
  String nextUserId = 'u1';

  @override
  String? get currentUserId => _userId;

  @override
  Stream<String?> get userIdChanges async* {
    yield _userId;
    yield* _changes.stream;
  }

  @override
  Future<void> signInWithGoogle() async {
    if (failWith != null) throw SignInException(failWith!);
    _userId = nextUserId;
    _changes.add(_userId);
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    _userId = null;
    _changes.add(null);
  }
}

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository(this.byId);

  final Map<String, Profile> byId;
  Object? error;

  @override
  Future<Profile> getProfile(String userId) async {
    if (error != null) throw error!;
    return byId[userId] ?? (throw const NotFound('profile'));
  }
}

List<Override> overridesFor(FakeAuthService auth, FakeProfileRepository profiles) => [
      authServiceProvider.overrideWithValue(auth),
      profileRepositoryProvider.overrideWithValue(profiles),
    ];
