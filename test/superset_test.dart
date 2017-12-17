import 'package:test/test.dart';
import 'package:indexed_set/indexed_set.dart';
import 'package:built_collection/built_collection.dart';

void main() {
  group("SupersetBuilder with default `comparator` and `isValidElement`:", () {
    SupersetBuilder<String> builder;
    setUp(() => builder = new SupersetBuilder<String>());

    test("throws when instantiated without generic type", () {
      expect(() => new SupersetBuilder(), throwsUnsupportedError);
    });

    group("build()", () {
      test("actually builds", () {
        final s = builder.build();
        expect(s, const isInstanceOf<Superset<String>>());
      });

      test("reuses the same superset if the builder didn't change", () {
        final s1 = builder.build();
        final s2 = builder.build();
        expect(s1, same(s2));
      });
    });

    group("withComparator()", () {
      test("overrides sort behaviour", () {
        builder
          ..withComparator((a, b) => -Comparable.compare(a, b))
          ..addAll(["a", "b", "c", "d"]);
        expect(builder.build(), orderedEquals(["d", "c", "b", "a"]));
      });

      test("reorders already present elements", () {
        builder
          ..addAll(["a", "b", "c", "d"])
          ..withComparator((a, b) => -Comparable.compare(a, b));
        expect(builder.build(), orderedEquals(["d", "c", "b", "a"]));
      });

      test("filters already present elements with `isValidElement`", () {
        builder
          ..addAll(["a", "aa", "b", "bb"])
          ..withComparator(
              (a, b) => -Comparable.compare(a, b), (s) => s.length == 1);
        expect(builder.build(), orderedEquals(["b", "a"]));
      });
    });

    group("replace()", () {
      test("replaces the previous contents of the builder", () {
        builder
          ..add("a")
          ..replace(["b", "c"]);
        expect(builder.build(), orderedEquals(["b", "c"]));
      });

      test("does not mutate the builder if the iterable is invalid", () {
        builder.add("a");
        expect(() => builder.replace(["don't add this", 123]),
            throwsArgumentError);
        expect(builder.build(), orderedEquals(["a"]));
      });

      test("reuses a parameter of type Superset", () {
        builder.add("a");
        final s = builder.build();
        builder
          ..clear()
          ..replace(s);
        expect(builder.build(), same(s));
      });
    });

    group("add()", () {
      test("adds element to builder", () {
        builder.add("a");
        expect(builder.build(), orderedEquals(["a"]));
      });

      test("throws ArgumentError on null", () {
        expect(() => builder.add(null), throwsArgumentError);
      });
    });

    group("addAll()", () {
      test("adds elements to builder", () {
        builder.addAll(["a", "b"]);
        expect(builder.build(), orderedEquals(["a", "b"]));
      });

      test("throws ArgumentError on null", () {
        expect(() => builder.addAll(["a", null]), throwsArgumentError);
      });

      test("does not mutate the builder if the iterable is invalid", () {
        builder.add("a");
        expect(() => builder.addAll(["don't add this", null]),
            throwsArgumentError);
        expect(builder.build(), orderedEquals(["a"]));
      });
    });

    test("clear() removes all elements", () {
      builder
        ..add("a")
        ..clear();
      expect(builder.build(), isEmpty);
    });

    group("expand()", () {
      test("replaces previous builder contents with callback result", () {
        builder
          ..addAll(["a", "b"])
          ..expand((s) => ["${s}1", "${s}2"]);
        expect(builder.build(), orderedEquals(["a1", "a2", "b1", "b2"]));
      });

      test("does not mutate the builder if the callback result is invalid", () {
        expect(
            () => builder
              ..add("a")
              ..expand((s) => [null]),
            throwsArgumentError);
        expect(builder.build(), orderedEquals(["a"]));
      });
    });

    group("map()", () {
      test("replaces previous builder contents with callback result", () {
        builder
          ..addAll(["a", "aa"])
          ..map((s) => "${s.length}");
        expect(builder.build(), orderedEquals(["1", "2"]));
      });

      test("does not mutate the builder if the callback result is invalid", () {
        expect(
            () => builder
              ..add("a")
              ..map((s) => null),
            throwsArgumentError);
        expect(builder.build(), orderedEquals(["a"]));
      });
    });

    group("remove()", () {
      test("removes the element", () {
        builder
          ..add("a")
          ..remove("a");
        expect(builder.build(), isEmpty);
      });

      test("ignores parameters that are not in the builder", () {
        builder
          ..add("a")
          ..remove("b");
        expect(builder.build(), orderedEquals(["a"]));
      });

      test("ignores parameters that can't be in the set", () {
        builder
          ..add("a")
          ..remove(null);
        expect(builder.build(), orderedEquals(["a"]));
      });
    });

    test("removeAll() removes all passed in elements", () {
      builder
        ..addAll(["a", "b", "c", "d"])
        ..removeAll(["c", "z", null, "d"]);
      expect(builder.build(), orderedEquals(["a", "b"]));
    });

    test("removeWhere() removes elements where the test callback returns true",
        () {
      builder
        ..addAll(["a", "aa", "b", "bb"])
        ..removeWhere((s) => s.length == 1);
      expect(builder.build(), orderedEquals(["aa", "bb"]));
    });

    test("retainAll() removes all elements not contained in the parameter", () {
      builder
        ..addAll(["a", "b", "c", "d"])
        ..retainAll(["a", "z", null, "b"]);
      expect(builder.build(), orderedEquals(["a", "b"]));
    });

    test("retainWhere() removes elements where the test callback returns false",
        () {
      builder
        ..addAll(["a", "aa", "b", "bb"])
        ..retainWhere((s) => s.length == 1);
      expect(builder.build(), orderedEquals(["a", "b"]));
    });

    test("skip() removes the first n elements", () {
      builder
        ..addAll(["a", "b", "c", "d"])
        ..skip(2);
      expect(builder.build(), orderedEquals(["c", "d"]));
    });

    test(
        "skipWhile() removes elements in iteration order "
        "while the test callback returns true", () {
      builder
        ..addAll(["a", "b", "cc", "z"])
        ..skipWhile((s) => s.length == 1);
      expect(builder.build(), orderedEquals(["cc", "z"]));
    });

    test("take() keeps only the first n elements", () {
      builder
        ..addAll(["a", "b", "c", "d"])
        ..take(2);
      expect(builder.build(), orderedEquals(["a", "b"]));
    });

    test(
        "takeWhile() keeps elements in iteration order "
        "until the test callback returns false", () {
      builder
        ..addAll(["a", "b", "cc", "z"])
        ..takeWhile((s) => s.length == 1);
      expect(builder.build(), orderedEquals(["a", "b"]));
    });
  });

  group("Superset with default `comparator` and `isValidElement`:", () {
    Superset<String> s;

    setUp(() => s = new Superset<String>(["a", "b", "c", "d"]));

    test("containsKey() returns true for ints in range 0..length-1", () {
      expect(s.containsKey(-1), isFalse);
      expect(s.containsKey(0), isTrue);
      expect(s.containsKey(3), isTrue);
      expect(s.containsKey(4), isFalse);
    });

    group("index()", () {
      test("returns the correct index for elements of the set", () {
        expect(s.index("a"), equals(0));
        expect(s.index("d"), equals(3));
      });

      test("returns -1 for objects not in the set", () {
        expect(s.index("z"), equals(-1));
      });

      test("returns -1 for null", () {
        expect(s.index(null), equals(-1));
      });
    });

    group("operator[]", () {
      test("returns the element for valid indexes", () {
        expect(s[0], equals("a"));
      });

      test("returns null for out-of-range indexes", () {
        expect(s[-1], isNull);
        expect(s[4], isNull);
      });

      test("returns null for null parameter", () {
        expect(s[null], isNull);
      });
    });

    group("contains()", () {
      test("returns true for elements of the set", () {
        expect(s.contains("a"), isTrue);
      });

      test("returns false for objects not in the set", () {
        expect(s.contains("z"), isFalse);
      });

      test("returns false for objects of the wrong type", () {
        // ignore: iterable_contains_unrelated_type
        expect(s.contains(4), isFalse);
        expect(s.contains(null), isFalse);
      });
    });

    test(
        "difference() returns new superset containing only elements from "
        "this that are not in other", () {
      expect(s.difference(new Superset<String>(["a", "c", "z"])),
          orderedEquals(["b", "d"]));
    });

    test(
        "intersection() returns new superset containing all elements from "
        "this that are also in other", () {
      expect(s.intersection(new Superset<String>(["a", "c", "z"])),
          orderedEquals(["a", "c"]));
    });

    group("lookup()", () {
      test("finds elements that are in the set", () {
        expect(s.lookup("a"), equals("a"));
      });

      test("returns null for objects not in the set", () {
        expect(s.lookup(4), isNull);
        expect(s.lookup(null), isNull);
      });
    });

    test(
        "union() returns new superset "
        "containing all elements from this and other", () {
      expect(s.union(new Superset<String>(["a", "z"])),
          orderedEquals(["a", "b", "c", "d", "z"]));
    });

    group("hashCode", () {
      test("is the same for Supersets with the same elements", () {
        expect(s.hashCode,
            equals(new Superset<String>(["a", "b", "c", "d"]).hashCode));
      });

      test("is the same for BuiltSets with the same elements", () {
        expect(s.hashCode,
            equals(new BuiltSet<String>(["a", "b", "c", "d"]).hashCode));
      });
    });

    group("operator==", () {
      test("returns true for Superset with equal elements", () {
        expect(s == new Superset<String>(["a", "b", "c", "d"]), isTrue);
      });

      test("returns true for BuiltSet with equal elements", () {
        expect(s == new BuiltSet<String>(["a", "b", "c", "d"]), isTrue);
      });

      test("returns false for Superset with different elements", () {
        expect(s == new Superset<String>(["a", "b", "c", "z"]), isFalse);
      });
    });
  });

  group("_UnmodifiableSupersetView", () {
    final s = new Superset<String>(["a", "b", "c", "d"]);
    final view = s.asSet();

    test("contains the same elements as its superset", () {
      expect(view, orderedEquals(s));
    });
  });
}
