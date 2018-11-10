import 'package:indexed_set/indexed_set.dart';

enum System { frontend, backend }

class Account {
  final String name;
  final System system;

  Account(this.name, this.system);

  @override
  String toString() => '$system-account of $name';
}

/// Supports lookup of accounts by username.
final frontendAccounts = IndexedSet((Account acc) => acc.name,
    isValidElement: (Account acc) => acc.system == System.frontend);

void main() {
  frontendAccounts
    ..add(Account('Alice', System.frontend))
    ..add(Account('Bob', System.frontend));

  // Supports element access through the user-specified index
  print(frontendAccounts['Alice']);
}
