import 'dart:typed_data';

import 'package:busin_app/busin_app.dart';
import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/subscription/proof_picker.dart';
import 'package:busin_student/src/subscription/subscription_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

Uint8List bytes(List<int> head, {int length = 64}) => Uint8List.fromList([...head, ...List.filled(length - head.length, 0)]);

void main() {
  group('sniffImageType', () {
    test('recognises JPEG, PNG and WebP by their first bytes', () {
      expect(sniffImageType(bytes([0xFF, 0xD8, 0xFF, 0xE0])), 'image/jpeg');
      expect(sniffImageType(bytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])), 'image/png');
      expect(sniffImageType(bytes([0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50])), 'image/webp');
    });

    test('does not trust anything else, whatever the file is called', () {
      expect(sniffImageType(bytes([0x25, 0x50, 0x44, 0x46])), isNull, reason: 'a PDF');
      expect(sniffImageType(bytes([0x47, 0x49, 0x46, 0x38])), isNull, reason: 'a GIF');
      expect(sniffImageType(Uint8List(0)), isNull);
      expect(sniffImageType(bytes([0xFF, 0xD8])), isNull, reason: 'too short to be sure');
    });
  });

  group('checkProof', () {
    test('accepts a photo and reports its real type', () {
      final proof = checkProof(bytes([0xFF, 0xD8, 0xFF, 0xE0]));
      expect(proof.contentType, 'image/jpeg');
    });

    test('refuses the wrong type and the too large', () {
      expect(() => checkProof(bytes([0x25, 0x50, 0x44, 0x46])), throwsA(isA<ProofException>().having((e) => e.problem, 'problem', ProofProblem.type)));
      expect(
        () => checkProof(bytes([0xFF, 0xD8, 0xFF, 0xE0], length: ProofRules.maxBytes + 1)),
        throwsA(isA<ProofException>().having((e) => e.problem, 'problem', ProofProblem.tooLarge)),
      );
    });
  });

  group('subscriptionToShow', () {
    test('a live request wins over a newer rejected one', () {
      final shown = subscriptionToShow([
        subscription(id: 'new', status: SubscriptionStatus.rejected),
        subscription(id: 'old', status: SubscriptionStatus.approved),
      ], 'sem1');
      expect(shown?.id, 'old');
    });

    test('otherwise the newest request for the semester', () {
      final shown = subscriptionToShow([
        subscription(id: 'a', status: SubscriptionStatus.rejected),
        subscription(id: 'b', status: SubscriptionStatus.expired),
      ], 'sem1');
      expect(shown?.id, 'a');
    });

    test('ignores other semesters, and is null when there is nothing', () {
      expect(subscriptionToShow([subscription(semesterId: 'other')], 'sem1'), isNull);
      expect(subscriptionToShow(const [], 'sem1'), isNull);
    });
  });

  group('SchoolClock', () {
    const clock = SchoolClock();

    test('uses the school day, not the UTC day', () {
      // 23:30 UTC on 4 November is already 5 November in Douala (UTC+1).
      expect(clock.today('Africa/Douala', now: DateTime.utc(2026, 11, 4, 23, 30)), DateTime(2026, 11, 5));
      expect(clock.today('Africa/Douala', now: DateTime.utc(2026, 11, 4, 22, 59)), DateTime(2026, 11, 4));
    });

    test('follows daylight saving where a school has it', () {
      // New York is UTC-4 in summer and UTC-5 in winter.
      expect(clock.today('America/New_York', now: DateTime.utc(2026, 7, 1, 3, 30)), DateTime(2026, 6, 30));
      expect(clock.today('America/New_York', now: DateTime.utc(2026, 12, 1, 4, 30)), DateTime(2026, 11, 30));
    });

    test('an unknown zone falls back to UTC instead of failing', () {
      expect(clock.today('Nowhere/Land', now: DateTime.utc(2026, 11, 4, 23, 30)), DateTime(2026, 11, 4));
    });
  });

  test('failureFor sorts what a repository throws into what the screen explains', () {
    expect(failureFor(const Conflict('x')), SubscribeFailure.alreadyRequested);
    expect(failureFor(const Offline('x')), SubscribeFailure.offline);
    expect(failureFor(const ProofRejected(Invalid('x'))), SubscribeFailure.rejectedFile, reason: 'only the upload refusing the photo blames the file');
    expect(failureFor(const Invalid('x')), SubscribeFailure.other, reason: 'a refused request is not about the photo');
    expect(failureFor(const Invalid('x', reason: 'missing_reference')), SubscribeFailure.unavailable);
    expect(failureFor(const NotAllowed('x')), SubscribeFailure.other);
    // The server's short reasons say what is wrong (ADR: reasons come from our own functions).
    expect(failureFor(const Invalid('x', reason: 'proof_required')), SubscribeFailure.proofRequired);
    expect(failureFor(const Invalid('x', reason: 'proof_missing')), SubscribeFailure.proofRequired);
    expect(failureFor(const Conflict('x', reason: 'semester_ended')), SubscribeFailure.semesterEnded);
    expect(failureFor(const Invalid('x', reason: 'something_else')), SubscribeFailure.other, reason: 'not about the file');
    expect(failureFor(StateError('x')), SubscribeFailure.other);
  });
}
