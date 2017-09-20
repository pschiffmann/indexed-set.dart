Dart indexed set
================

Provides an `IndexedSet` class, an implementation of `Set` that computes an index for each of its elements, and exposes this mapping through the `[]` operator.

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

  frontendAccounts.add(new Account('bob', System.frontend));
  print(frontendAccounts['bob']); // System.frontend-account of bob
}
```
