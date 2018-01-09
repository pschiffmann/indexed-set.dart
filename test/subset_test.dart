import 'package:test/test.dart';
import 'package:indexed_set/indexed_set.dart';

void main() {
  group("Subset", () {
    final alphabet = new List.generate(
        26, (n) => new String.fromCharCode(n + "A".codeUnitAt(0)));
    final vowels = const ["A", "E", "I", "O", "U"];
    final first10 = const ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"];

    // Taken for vowels∘first10, ∘∈{∩, ∪, \}
    final difference = const ["O", "U"];
    final intersection = const ["A", "E", "I"];
    final union = const [
      "A",
      "B",
      "C",
      "D",
      "E",
      "F",
      "G",
      "H",
      "I",
      "J",
      "O",
      "U"
    ];

    final superset = new Superset<String>(alphabet);

    Subset<String> subset;
    setUp(() => subset = new Subset<String>(superset));

    group("iterator", () {
      test("visits all elements", () {
        subset.addAll(vowels);
        final it = subset.iterator;
        for (var i = 0; i < vowels.length; i++) {
          expect(it.moveNext(), isTrue);
          expect(it.current, equals(vowels[i]));
        }
        expect(it.moveNext(), isFalse);
      });

      group("detects concurrent modifications by", () {
        Iterator<String> it;
        setUp(() {
          subset.addAll(vowels);
          it = subset.iterator..moveNext();
        });

        test("add()", () {
          subset.add("X");
          expect(it.moveNext, throwsConcurrentModificationError);
          expect(it.current, equals("A"));
        });

        group("addAll() when called with", () {
          test("Iterable", () {
            subset.addAll(first10);
            expect(it.moveNext, throwsConcurrentModificationError);
            expect(it.current, equals("A"));
          });

          test("Subset", () {
            subset.addAll(new Subset<String>(superset)..addAll(first10));
            expect(it.moveNext, throwsConcurrentModificationError);
            expect(it.current, equals("A"));
          });
        });

        test("clear()", () {
          subset.clear();
          expect(it.moveNext, throwsConcurrentModificationError);
          expect(it.current, equals("A"));
        });

        test("remove()", () {
          subset.remove("A");
          expect(it.moveNext, throwsConcurrentModificationError);
          expect(it.current, equals("A"));
        });

        group("removeAll() when called with", () {
          test("Iterable", () {
            subset.removeAll(first10);
            expect(it.moveNext, throwsConcurrentModificationError);
            expect(it.current, equals("A"));
          });

          test("Subset", () {
            subset.removeAll(new Subset<String>(superset)..addAll(first10));
            expect(it.moveNext, throwsConcurrentModificationError);
            expect(it.current, equals("A"));
          });
        });

        group("retainAll() when called with", () {
          test("Iterable", () {
            subset.retainAll(first10);
            expect(it.moveNext, throwsConcurrentModificationError);
            expect(it.current, equals("A"));
          });

          test("Subset", () {
            subset.retainAll(new Subset<String>(superset)..addAll(first10));
            expect(it.moveNext, throwsConcurrentModificationError);
            expect(it.current, equals("A"));
          });
        });
      });
    });

    group("constructor", () {
      test("creates empty set with filled=false", () {
        expect(subset, isEmpty);
      });

      test("creates set containing all elements from superset with filled=true",
          () {
        expect(new Subset(superset, filled: true), orderedEquals(superset));
      });
    });

    group("add()", () {
      test("adds missing element", () {
        expect(subset.add("A"), isTrue);
        expect(subset.length, equals(1));
      });

      test("rejects elements not in the superset", () {
        expect(() => subset.add("a"), throwsArgumentError);
        expect(subset.contains("a"), isFalse);
        expect(subset.length, equals(0));
      });

      test("returns false if the element is already in the set", () {
        subset.add("A");
        expect(subset.add("A"), isFalse);
        expect(subset.length, equals(1));
      });
    });

    group("addAll() adds all elements from the argument", () {
      test("List", () {
        subset..addAll(vowels)..addAll(first10);
        expect(subset, orderedEquals(union));
        expect(subset.length, equals(union.length));
      });

      test("Subset", () {
        subset..addAll(vowels)..addAll(new Subset(superset)..addAll(first10));
        expect(subset, orderedEquals(union));
        expect(subset.length, equals(union.length));
      });
    });

    test("clear() removes all elements", () {
      subset
        ..addAll(vowels)
        ..clear();
      expect(subset.isEmpty, isTrue);
    });

    group("contains()", () {
      test("returns true for elements that are in the set", () {
        subset.addAll(vowels);
        expect(subset.contains("A"), isTrue);
      });

      test("returns false for elements that are not in the set", () {
        subset.addAll(vowels);
        expect(subset.contains("B"), isFalse);
      });

      test("returns false for objects that are not in the superset", () {
        subset.addAll(vowels);
        expect(subset.contains(null), isFalse);
        expect(subset.contains(65), isFalse);
      });
    });

    group("containsKey()", () {
      test("returns true for indexes that are in the set", () {
        subset.addAll(vowels);
        expect(subset.containsKey(0), isTrue);
      });

      test("returns false for indexes that are not in the set", () {
        subset.addAll(vowels);
        expect(subset.containsKey(1), isFalse);
      });
    });

    group("intersection() returns the intersection when called with a", () {
      test("HashSet", () {
        subset.addAll(vowels);
        final i = subset.intersection(new Set.from(first10));
        expect(i, orderedEquals(intersection));
        expect(i.length, equals(intersection.length));
      });

      test("Subset", () {
        subset.addAll(vowels);
        final i = subset.intersection(new Subset(superset)..addAll(first10));
        expect(i, orderedEquals(intersection));
        expect(i.length, equals(intersection.length));
      });
    });

    group("lookup()", () {
      test("finds an element if it is in the set", () {
        subset.addAll(vowels);
        expect(subset.lookup("A"), equals("A"));
      });

      test("returns null if no equal element is in the set", () {
        expect(subset.lookup("A"), isNull);
      });
    });

    group("remove()", () {
      test("removes an element if it is in the set", () {
        subset.addAll(vowels);
        expect(subset.remove("A"), isTrue);
        expect(subset.contains("A"), isFalse);
        expect(subset.length, equals(4));
      });

      test("returns false if the object was not in the set", () {
        expect(subset.remove("A"), isFalse);
        expect(subset.length, equals(0));
      });

      test("returns false if the object can't be in the set", () {
        expect(subset.remove(4), isFalse);
        expect(subset.length, equals(0));
      });
    });

    group("removeAll() removes all elements when called with a", () {
      test("HashSet", () {
        subset
          ..addAll(vowels)
          ..removeAll(new Set.from(first10));
        expect(subset, orderedEquals(difference));
        expect(subset.length, equals(difference.length));
      });

      test("Subset", () {
        subset
          ..addAll(vowels)
          ..removeAll(new Subset(superset)..addAll(first10));
        expect(subset, orderedEquals(difference));
        expect(subset.length, equals(difference.length));
      });
    });

    group("retainAll() removes all other elements when called with a", () {
      test("Hashset", () {
        subset
          ..addAll(vowels)
          ..retainAll(new Set.from(first10));
        expect(subset, orderedEquals(intersection));
        expect(subset.length, equals(intersection.length));
      });

      test("Subset", () {
        subset
          ..addAll(vowels)
          ..retainAll(new Subset(superset)..addAll(first10));
        expect(subset, orderedEquals(intersection));
        expect(subset.length, equals(intersection.length));
      });
    });

    test("toSet() creates exact copy", () {
      subset.addAll(vowels);
      final copy = subset.toSet();
      expect(copy, const isInstanceOf<Subset<String>>());
      expect(copy, orderedEquals(subset));
      expect(copy.length, equals(5));
    });
  });
}
