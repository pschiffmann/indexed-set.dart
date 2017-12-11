import 'dart:collection';
import 'package:indexed_set/indexed_set.dart' show DuplicateIndexException;

/// An implementation of [Set] that computes an [index] for each of its
/// elements, and exposes this mapping through the `[]` operator.
///
/// To work correctly, `I` must retain the equality relation of `E`: For any two
/// possible set elements `e1` and `e2` it must hold that `e1 == e2` implies
/// `index(e1) == index(e2)`. You can customize the equality check for both `I`
/// and `E`, and you can exclude certain `E` instances with `isValidElement`.
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
///     final frontendAccounts = new IndexedSet<String, Account>(
///         (Account acc) => acc.name,
///         isValidElement: (Account acc) => acc.system == System.frontend);
///
/// This implementation internally uses a [Map] to store key/value pairs, which
/// defaults to an unordered [HashMap]. The [IndexedSet.using] constructor lets
/// you use another map, for example if you want to change iteration order.
class IndexedSet<I, E> extends SetMixin<E> {
  /// Computes the index of a (potential) element.
  final I Function(E) _index;

  /// User-provided callback that returns `true` if two [E] instances are
  /// considered equal. Can be `null`. Used by [_elementsEqual].
  final bool Function(E, E) _comparator;

  /// User-provided callback that returns `true` if the [E] instance is allowed
  /// in this set. Can be `null`. Used by [_validElement].
  final bool Function(E) _filter;

  /// The elements of this set are stored solely as the values of this map.
  final Map<I, E> _values;

  /// Instantiates [_values]. The factory needs to be kept to be used by
  /// [toSet].
  final Map<I, E> Function() _valuesFactory;

  @override
  Iterator<E> get iterator => _values.values.iterator;

  @override
  int get length => _values.length;

  /// Creates an unordered indexed set.
  ///
  /// If `areElementsEqual` or `areIndexesEqual` are omitted, the objects are
  /// compared with `operator==`.
  IndexedSet(
    I Function(E) index, {
    bool areElementsEqual(E e1, E e2),
    bool isValidElement(E element),
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
  /// Throws an [ArgumentError] if the call to `base` returns a non-empty map.
  IndexedSet.using(
    I Function(E) index,
    Map<I, E> Function() base, {
    bool areElementsEqual(E e1, E e2),
    bool isValidElement(E element),
  })
      : _index = index,
        _comparator = areElementsEqual,
        _filter = isValidElement,
        _values = base(),
        _valuesFactory = base {
    if (_values.isNotEmpty)
      throw new ArgumentError.value(
          base, 'base', 'The returned map must be empty');
  }

  /// Returns the element referenced by _index_.
  ///
  /// If no such element exists in this set, the behaviour depends on the
  /// underlying map. The default [HashMap] returns `null` in this case.
  ///
  /// This set allows `null` as an element. To check whether an element with
  /// _index_ is present in this set, use [containsKey].
  E operator [](I index) => _values[index];

  /// Adds `element` to the set.
  ///
  /// Returns `true` if `element` (or an equal value) was not yet in the set.
  /// Returns `false` if a value equal to `element` already is in the set, and
  /// the set is not changed.
  ///
  /// Throws a [DuplicateIndexException] when the set contains an element with
  /// equal index, which is not equal to `element` according to
  /// `areElementsEqual`.
  @override
  bool add(E element) {
    if (!_validElement(element)) return false;

    final i = index(element);
    if (!_values.containsKey(i)) {
      _values[i] = element;
      return true;
    }
    if (_elementsEqual(element, _values[i])) return false;

    throw new DuplicateIndexException(i, _values[i], element);
  }

  @override
  bool contains(Object value) =>
      _validElement(value) && _elementsEqual(value, _values[index(value)]);

  /// Returns `true` if this set contains an element whose index is equal to the
  /// given value.
  bool containsKey(I index) => _values.containsKey(index);

  @override
  void clear() => _values.clear();

  /// Computes the index of a (potential) element.
  I index(E element) => _index(element);

  @override
  E lookup(Object value) {
    if (!_validElement(value)) return null;
    final i = index(value);
    if (!_values.containsKey(i)) return null;
    final element = _values[i];
    return _elementsEqual(value, element) ? element : null;
  }

  @override
  bool remove(Object element) {
    if (!_validElement(element)) return false;
    final i = index(element);
    if (!_values.containsKey(i) || !_elementsEqual(element, _values[i]))
      return false;
    _values.remove(i);
    return true;
  }

  @override
  IndexedSet<I, E> toSet() => new IndexedSet.using(index, _valuesFactory,
      areElementsEqual: _comparator, isValidElement: _filter)
    .._values.addAll(_values);

  /// Returns `true` if `e1` and `e2` are considered equal.
  bool _elementsEqual(E e1, E e2) =>
      _comparator != null ? _comparator(e1, e2) : e1 == e2;

  /// Returns true if `value` could possibly be in this set.
  bool _validElement(Object element) =>
      element is E && (_filter != null ? _filter(element) : true);
}
