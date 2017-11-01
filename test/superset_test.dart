import 'package:test/test.dart';
import 'package:indexed_set/indexed_set.dart';

void main() {
  group("SupersetBuilder with default `compare` and `isValidElement`:", () {
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

    group("replace()", () {
      test("replaces the previous contents of the builder", () {
        builder.add("a");
        builder.replace(["b", "c"]);
        expect(builder.build(), orderedEquals(["b", "c"]));
      });

      test("does not mutate the builder if the iterable is invalid", () {
        builder.add("a");
        expect(() => builder.replace(["don't add this", 123]),
            throwsArgumentError);
        expect(builder.build(), orderedEquals(["a"]));
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
        expect(
            () => builder.addAll(["don't add this", 123]), throwsArgumentError);
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
      builder.addAll(["a", "b", "c", "d"]);
      builder.removeAll(["c", "z", null, "d"]);
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
}
