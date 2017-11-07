Dart indexed set
================

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

void main() {
  final frontendAccounts = new IndexedSet<String, Account>(
      (Account account) => account.system == System.frontend
          ? account.name
          : throw new ArgumentError('This set only stores frontend accounts'),
      isValidElement: (value) =>
          value is Account && value.system == System.frontend);

  frontendAccounts.add(new Account('pschiffmann', System.frontend));
  print(frontendAccounts['pschiffmann']);
}
```

Superset / Subset
-----------------

Both `Superset` and `Subset` are indexed sets that use `int` as the index type.
Supersets are immutable and store their elements in ascending order -- the first element will have index `0`, the last element index `set.length - 1`.
Subsets have to be taken from a superset, and can only contain elements that are also contained in the superset.
This allows the subsets to store their elements in a bit vector, which is both very space-efficient, and time-efficient for set operations (difference, intersection, union) on subsets of the same superset.
