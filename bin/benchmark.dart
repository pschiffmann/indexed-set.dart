/// This script compares the execution times of the methods [Set.difference],
/// [Set.intersection] and [Set.union] for the classes [HashSet] and [Subset].
///
/// The set elements are randomly chosen [int]s in the range `0..max` for max in
/// [ranges].

import 'dart:collection';
import 'dart:math';
import 'package:indexed_set/indexed_set.dart' show Superset, Subset;
import 'package:text_table/text_table.dart';

/// This many sets will be created in each iteration.
const int numberOfSets = 100;

const List<int> ranges = const [10, 100, 250, 500, 1000, 2000, 4000, 8000];

const List<double> percentFilled = const [
  0.0,
  0.1,
  0.2,
  0.3,
  0.4,
  0.5,
  0.6,
  0.7,
  0.8,
  0.9,
  1.0
];

const Map<String, Function> methods = const {
  'difference': pairwiseDifference,
  'intersection': pairwiseIntersection,
  'union': pairwiseUnion,
  'contains': randomContains,
  'add': randomAdd,
  'remove': randomRemove
};

abstract class BenchmarkEnvironment {
  final Random rng = new Random(4);
  final int maxValue;

  /// Creates [numberOfSets] sets, each containing [elementsPerSet] elements
  /// from the range 0..[maxValue].
  List<Set<int>> generateFilledSets({int maxValue, int elementsPerSet});

  /// Returns a [HashSet] with [count] random elements in range 0..[maxValue].
  HashSet<int> _uniqueInts(int maxValue, int count) {
    final result = new HashSet<int>();
    while (result.length < count) {
      result.add(rng.nextInt(maxValue));
    }
    return result;
  }
}

class SubsetEnvironment extends BenchmarkEnvironment {
  @override
  List<Set<int>> generateFilledSets({int maxValue, int elementsPerSet}) {
    final superset = new Superset<int>(new Iterable.generate(maxValue));
    final result = new List(numberOfSets);
    for (var i = 0; i < result.length; i++) {
      result[i] = new Subset<int>(superset)
        ..addAll(_uniqueInts(maxValue, elementsPerSet));
    }
    return result;
  }
}

class HashSetEnvironment extends BenchmarkEnvironment {
  @override
  List<Set<int>> generateFilledSets({int maxValue, int elementsPerSet}) {
    final result = new List(numberOfSets);
    for (var i = 0; i < result.length; i++) {
      result[i] = _uniqueInts(maxValue, elementsPerSet);
    }
    return result;
  }
}

/// Used by [generateFilledSets] to generate test data.
final rng = new Random(4);

/// Creates [numberOfSets] sets, each containing [elementsPerSet] elements
/// from the range 0..[maxValue]. [type] must be either [HashSet] or [Subset].
List<Set<int>> generateFilledSets(Type type,
    {int maxValue, int elementsPerSet}) {
  Set<int> Function() factory;
  if (type == HashSet) {
    factory = () => new HashSet<int>();
  } else if (type == Subset) {
    final superset = new Superset<int>(new Iterable.generate(maxValue));
    factory = () => new Subset<int>(superset);
  } else {
    throw new ArgumentError.value(type, 'must be HashSet or Subset');
  }

  final result = new List(numberOfSets);
  for (var i = 0; i < numberOfSets; i++) {
    final current = result[i] = factory();
    while (current.length < elementsPerSet) {
      current.add(rng.nextInt(maxValue));
    }
  }
  return result;
}

Duration execute10Times(void Function() callback) {
  final watch = new Stopwatch();
  Duration duration;
  for (var i = 0; i < 10; i++) {
    watch
      ..reset()
      ..start();
    callback();
    watch.stop();
    if (duration == null || duration > watch.elapsed) {
      duration = watch.elapsed;
    }
  }
  return duration;
}

void benchmark(
    String name, Type type, void callback(List<Set<int>> sets, int maxValue)) {
  /// Creates a table with columns: max elements, 0%, 10%, ..., 100%.
  final table = new Table(
      ['max elements']
        ..addAll(percentFilled.map((p) => '${(p * 100).truncate()}%')),
      globalAlign: Align.right,
      border: Border.simple);

  for (final maxValue in ranges) {
    final row = <Object>[maxValue];
    for (final percent in percentFilled) {
      final sets = generateFilledSets(type,
          maxValue: maxValue, elementsPerSet: (maxValue * percent).truncate());

      final duration = execute10Times(() => callback(sets, maxValue));
      row.add('${duration.inMicroseconds}us');
    }
    table.row(row);
  }
  print('Evaluating $name on $type:');
  print(table);
}

void main() {
  methods.forEach((name, callback) {
    for (final type in const [HashSet, Subset]) {
      benchmark(name, type, callback);
    }
  });
}

/*
 * benchmark functions
 */

void pairwiseDifference(List<Set<int>> sets, int maxValue) {
  for (final lhs in sets) {
    // ignore: prefer_foreach
    for (final rhs in sets) {
      lhs.difference(rhs);
    }
  }
}

void pairwiseIntersection(List<Set<int>> sets, int maxValue) {
  for (final lhs in sets) {
    // ignore: prefer_foreach
    for (final rhs in sets) {
      lhs.intersection(rhs);
    }
  }
}

void pairwiseUnion(List<Set<int>> sets, int maxValue) {
  for (final lhs in sets) {
    // ignore: prefer_foreach
    for (final rhs in sets) {
      lhs.union(rhs);
    }
  }
}

void randomContains(List<Set<int>> sets, int maxValue) {
  for (final s in sets) {
    for (var i = 0; i < 100; i++) {
      s.lookup(rng.nextInt(maxValue * 2));
    }
  }
}

void randomAdd(List<Set<int>> sets, int maxValue) {
  for (final s in sets) {
    for (var i = 0; i < 100; i++) {
      s.add(rng.nextInt(maxValue));
    }
  }
}

void randomRemove(List<Set<int>> sets, int maxValue) {
  for (final s in sets) {
    for (var i = 0; i < 100; i++) {
      s.remove(rng.nextInt(maxValue * 2));
    }
  }
}
