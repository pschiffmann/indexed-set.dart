Dart indexed set
================

[![Build Status](https://travis-ci.com/pschiffmann/indexed-set.dart.svg?branch=master)](https://travis-ci.com/pschiffmann/indexed-set.dart)

This package provides an `IndexedSet` class, and a pair of `Superset`/`Subset` classes that implement the `IndexedSet` interface.

IndexedSet
----------

An `IndexedSet` adds a mapping mechanism to the `Set` interface.
A user-provided function `I index(E element)` calculates an index for each element.
The elements are then accessible through the `[]` operator.
This allows you to define cleaner APIs than if you used a `Map`, because the data structure can enforce integrity of the key/value mapping.

```dart
enum System { frontend, backend }

class Account {
  final String name;
  final System system;

  Account(this.name, this.system);

  String toString() => '$system-account of $name';
}

/// Supports lookup of accounts by username.
final frontendAccounts = new IndexedSet<String, Account>(
    (Account acc) => acc.name,
    isValidElement: (Account acc) => acc.system == System.frontend);
```

Superset / Subset
-----------------

Both `Superset` and `Subset` are indexed sets that use `int` as the index type.
A Superset is immutable and stores its elements in ascending order -- the first element will have index `0`, the last element index `set.length - 1`.
A Subset has to be taken from a superset, and can only contain elements that are also contained in the superset.

The idea was that subsets could store their elements in a bit vector, which would be very space-efficient, and time-efficient for set operations (difference, intersection, union) on subsets of the same superset. However, `Subset` is outperformed by a regular `HashSet` in most situations.
