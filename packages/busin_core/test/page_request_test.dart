import 'package:busin_core/busin_core.dart';
import 'package:test/test.dart';

void main() {
  group('PageRequest', () {
    test('starts at the first row with a default size', () {
      const page = PageRequest();
      expect(page.offset, 0);
      expect(page.limit, PageRequest.defaultLimit);
      expect(page.lastIndex, 19);
    });

    test('the next slice follows on without overlap', () {
      const page = PageRequest(limit: 10, offset: 30);
      expect(page.lastIndex, 39);
      expect(page.next.offset, 40);
      expect(page.next.limit, 10);
    });

    test('refuses a size that would load too much', () {
      expect(() => PageRequest(limit: PageRequest.maxLimit + 1), throwsA(isA<AssertionError>()));
      expect(() => PageRequest(limit: 0), throwsA(isA<AssertionError>()));
      expect(() => PageRequest(offset: -1), throwsA(isA<AssertionError>()));
    });
  });

  group('RepositoryException', () {
    test('has a type per kind of problem and a readable description', () {
      const problems = <RepositoryException>[
        NotAllowed('a'),
        NotFound('b'),
        Conflict('c'),
        Invalid('d'),
        Offline('e'),
        Unexpected('f'),
      ];
      expect(problems.map((p) => p.runtimeType).toSet().length, 6);
      expect(const NotFound('stop').toString(), 'NotFound: stop');
    });
  });
}
