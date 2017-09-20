import 'dart:collection';
import 'package:test/test.dart';
import 'package:indexed_set/indexed_set.dart';

void main() {
  group("IndexedSet with default `equals`, `isValidElement` and `values`", () {
    group("with elements [10, 20, 15]:", () {
      IndexedSet<String, num> s;
      setUp(() => s = new IndexedSet<String, num>((num n) => n.toString())
        ..addAll([10, 20, 15]));

      test("iterator contains all elements",
          () => expect(s, unorderedEquals([10, 20, 15])));

      test("length is correct", () {
        expect(s.length, equals(3));
        s.remove(10);
        expect(s.length, equals(2));
        s..add(4)..add(5);
        expect(s.length, equals(4));
      });

      group("operator[]", () {
        test("succeeds for present elements", () {
          expect(s["10"], equals(10));
          expect(s["20"], equals(20));
          expect(s["15"], equals(15));
        });
        test("returns null for missing elements", () => expect(s["3"], isNull));
      });

      group("add", () {
        test("actually adds the element to the set", () {
          s.add(12);
          expect(s.contains(12), isTrue);
        });
        test("returns true if set was mutated", () {
          expect(s.add(12), isTrue);
          expect(s.add(12), isFalse);
          expect(s.add(20), isFalse);
        });
      });

      group("contains", () {
        test("succeeds for present elements", () {
          expect(s.contains(10), isTrue);
          expect(s.contains(20), isTrue);
          expect(s.contains(15), isTrue);
        });
        test("fails for missings elements",
            () => expect(s.contains(3), isFalse));
      });

      group("containsKey", () {
        test("succeeds for present indexes", () {
          expect(s.containsKey("10"), isTrue);
          expect(s.containsKey("20"), isTrue);
          expect(s.containsKey("15"), isTrue);
        });
        test("fails for missings indexes",
            () => expect(s.containsKey("3"), isFalse));
      });

      test("clear deletes all elements", () {
        s.clear();
        expect(s, isEmpty);
      });

      group("lookup", () {
        test("succeeds for present elements", () {
          expect(s.lookup(10), equals(10));
          expect(s.lookup(20), equals(20));
          expect(s.lookup(15), equals(15));
        });
        test("returns null for missing elements",
            () => expect(s.lookup(3), isNull));
      });

      group("remove", () {
        test("actually removes elements", () {
          s..remove(10)..remove(20);
          expect(s.contains(10), isFalse);
          expect(s.contains(20), isFalse);
        });
        test("returns true for present elements", () {
          expect(s.remove(10), isTrue);
          expect(s.remove(20), isTrue);
          expect(s.remove(15), isTrue);
        });
        test("returns null for missing elements",
            () => expect(s.remove(3), isFalse));
      });

      group("toSet", () {
        test("contains the same elements",
            () => expect(s.toSet(), unorderedEquals(s)));
        test("returns set with same behaviour", () {
          final s2 = s.toSet();
          expect(s2, const isInstanceOf<IndexedSet<String, num>>());
          expect(s2.index, equals(s.index));
        });
      });
    });
  });

  group("IndexedSet with partially defined and colliding `index`:", () {
    final exc = new ArgumentError("dummy exception");
    bool isValidElement(int n) => n < 100;
    String index(int n) => isValidElement(n) ? (n % 2).toString() : throw exc;

    IndexedSet<String, int> s;
    setUp(() =>
        s = new IndexedSet<String, int>(index, isValidElement: isValidElement));

    group("add", () {
      test("rejects duplicate indexes", () {
        s.add(1);
        expect(() => s.add(3),
            throwsA(const isInstanceOf<DuplicateIndexException>()));
      });
      test("prefers custom exception from `index` over generic one", () {
        expect(() => s.add(100), throwsA(exc));
      });
    });

    test("contains differentiates between objects with same index", () {
      s.add(1);
      expect(s.contains(1), isTrue);
      expect(s.contains(3), isFalse);
    });

    test("lookup differentiates between objects with same index", () {
      s.add(1);
      expect(s.lookup(1), equals(1));
      expect(s.lookup(3), isNull);
    });

    group("remove", () {
      test("actually removes the element", () {
        s.add(1);
        expect(s.remove(1), isTrue);
        expect(s.contains(1), isFalse);
      });
      test("differentiates between objects with same index", () {
        s.add(1);
        expect(s.remove(3), isFalse);
        expect(s.contains(1), isTrue);
      });
    });
  });

  group("IndexedSet with underlying `SplayTreeMap`", () {
    IndexedSet<String, int> s;
    setUp(() => s = new IndexedSet<String, int>.using(
        (int n) => n.toString(),
        () => new SplayTreeMap<String, int>(
            (String s1, String s2) => int.parse(s1).compareTo(int.parse(s2)))));

    test("iterates over elements in ascending order", () {
      s..addAll([40, 5, 12, 3]);
      expect(s, orderedEquals([3, 5, 12, 40]));
    });
  });
}
