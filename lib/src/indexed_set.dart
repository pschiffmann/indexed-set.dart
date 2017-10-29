import 'dart:collection' show HashMap, SetMixin;
import 'package:indexed_set/indexed_set.dart' show DuplicateIndexException;

/// An implementation of [Set] that computes an [index] for each of its
/// elements, and exposes this mapping through the `[]` operator.
///
/// To work correctly, `I` must retain the equality relation of `E`: For any two
/// possible set elements `e1` and `e2` it must hold that `e1 == e2` implies
/// `index(e1) == index(e2)`. You can customize the equality check for both `I`
/// and `E`, and you can exclude certain `E` instances with `isValidElement`.
///
/// All methods of this set that call `index` check potential elements with
/// `isValidElement` first, except [add], which calls `index` anyways. This
/// means that you can throw a custom error message in `index`, when `index`
/// is not defined for all possible instances of E, or is not a stable
/// equivalence relation.
///
/// Example:
///
///     enum System { frontend, backend }
///
///     class Account {
///       final String name;
///       final System system;
///
///       Account(this.name, this.system);
///
///       String toString() => '$system-account of $name';
///     }
///
///     void main() {
///       final fe = new Account('bob', System.frontend);
///       final be = new Account('bob', System.backend);
///       final frontendAccounts = new IndexedSet<String, Account>(
///           (Account account) => account.system == System.frontend
///               ? account.name
///               : throw new ArgumentError('This set only stores frontend accounts'),
///           isValidElement: (value) =>
///               value is Account && value.system == System.frontend);
///
///       frontendAccounts.add(fe);
///       print(frontendAccounts['bob']); // System.frontend-account of bob
///       print(frontendAccounts.contains(fe)); // true
///       print(frontendAccounts.contains(be)); // false
///       frontendAccounts.remove(be); // doesn't call `index`, so it doesn't throw
///       frontendAccounts.add(be); // throws 'This set only stores frontend accounts'
///     }
///
/// This implementation internally uses a [Map] to store key/value pairs, which
/// defaults to an unordered [HashMap]. The [IndexedSet.using] constructor lets
/// you use another map, for example if you want to change iteration order.
class IndexedSet<I, E> extends SetMixin<E> {
  /// Computes the index of a (potential) element.
  final I Function(E) _index;

  /// Determines equality of instances of E.
  final bool Function(E, E) _equals;

  /// Used in [contains], [lookup] and [remove] to reject values before they are
  /// even passed to [index].
  final bool Function(Object) _isValidElement;

  /// The elements of this set are stored solely as the values of this map.
  final Map<I, E> _values;

  /// Instantiates [_values]. Needed by [toSet].
  final Map<I, E> Function() _valuesConstructor;

  @override
  Iterator<E> get iterator => _values.values.iterator;

  @override
  int get length => _values.length;

  /// Creates an unordered indexed set.
  ///
  /// `areElementsEqual` and `areIndexesEqual` both default to [identical].
  /// `isValidElement` defaults to checking that `potentialKey` is an `E`.
  IndexedSet(
    I Function(E) index, {
    bool areElementsEqual(E e1, E e2),
    bool isValidElement(Object potentialKey),
    bool areIndexesEqual(I i1, I i2),
  })
      : this.using(index, () => new HashMap<I, E>(equals: areIndexesEqual),
            areElementsEqual: areElementsEqual, isValidElement: isValidElement);

  /// Creates an indexed set that uses `base` to store index/element pairs.
  ///
  /// Use `base` to adjust the behaviour of this object: For example, pass in
  /// a [LinkedHashMap] constructor to iterate over elements in insertion order.
  /// If you need a custom `areIndexesEqual`, pass it directly to the map.
  ///
  /// Throws an [ArgumentError] if the call to `values` returns a non-empty map.
  IndexedSet.using(
    I Function(E) index,
    Map<I, E> Function() base, {
    bool areElementsEqual(E e1, E e2),
    bool isValidElement(Object potentialKey),
  })
      : _index = index,
        _equals = areElementsEqual ?? identical,
        _isValidElement = isValidElement ?? ((Object o) => o is E),
        _values = base(),
        _valuesConstructor = base {
    if (_values.isNotEmpty)
      throw new ArgumentError.value(
          _values, 'values', 'The returned map must be empty');
  }

  /// Returns the element referenced by _index_, or null if no such element
  /// exists in this set.
  ///
  /// This set allows `null` as a key. To check whether an element with _index_
  /// is present in this set, use [containsKey].
  E operator [](I index) => _values[index];

  /// Adds `element` to the set.
  ///
  /// Returns `true` if `element` (or an equal value) was not yet in the set.
  /// Returns `false` if a value equal to `element` already is in the set, and
  /// the set is not changed.
  ///
  /// Throws a [DuplicateIndexException] when the set contains an element with
  /// equal index, which is not equal to `element` according to the provided
  /// equality callback.
  @override
  bool add(E element) {
    final i = index(element);

    if (!_isValidElement(element)) return false;
    if (!_values.containsKey(i)) {
      _values[i] = element;
      return true;
    }
    if (_equals(element, _values[i])) return false;

    throw new DuplicateIndexException(i, _values[i], element);
  }

  @override
  bool contains(Object value) =>
      _isValidElement(value) && _equals(value, _values[index(value)]);

  /// Returns true if this set contains an element whose index is equal to the
  /// given value.
  bool containsKey(I index) => _values.containsKey(index);

  @override
  void clear() => _values.clear();

  /// Computes the index of a (potential) element.
  I index(E element) => _index(element);

  @override
  E lookup(Object value) {
    if (!_isValidElement(value)) return null;
    final i = index(value);
    if (!_values.containsKey(i)) return null;
    final element = _values[i];
    return _equals(value, element) ? element : null;
  }

  @override
  bool remove(Object element) {
    if (!_isValidElement(element)) return false;
    final i = index(element);
    if (!_values.containsKey(i) || !_equals(element, _values[i])) return false;
    _values.remove(i);
    return true;
  }

  @override
  IndexedSet<I, E> toSet() => new IndexedSet.using(index, _valuesConstructor,
      areElementsEqual: _equals, isValidElement: _isValidElement)
    ..addAll(this);
}
