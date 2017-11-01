import 'dart:collection' show IterableBase, SplayTreeSet;
import 'package:built_collection/built_collection.dart'
    show BuiltList, BuiltSet, SetBuilder;
import 'package:built_collection/src/iterable.dart';
import 'package:built_value/built_value.dart' show Builder, Built;
import 'package:collection/collection.dart' show binarySearch;
import 'package:quiver/core.dart' show hash4, hashObjects;
import 'indexed_set.dart';
import 'subset.dart';

/// A Superset is the counterpart to [Subset].
///
/// As a [built class](https://pub.dartlang.org/packages/built_collection), it
/// is immutable. This class implements the interface of [BuiltSet] and the
/// non-modifying part of [IndexedSet], using [int] as the index type.
///
/// Internally, the elements are stored in an ordered list. Every call to
/// [index], [contains] and [lookup] performs a binary search on that list,
/// resulting in an O(log n) runtime for these methods.
///
/// Iteration order is guaranteed to be in ascending order according to the
/// comparator used. All methods use the provided comparator to determine object
/// equality.
class Superset<E> extends IterableBase<E>
    implements
        Built<Superset<E>, SupersetBuilder<E>>,
        BuiltIterable<E>,
        BuiltSet<E> {
  /// Used to look up objects in [_elements].
  final Comparator<E> _compare;

  /// User-provided callback. Should not be called directly, use [_checkElement]
  /// instead.
  final bool Function(Object) _isValidElement;

  /// Calls [_isValidElement], or uses an `is E` check as fallback.
  bool _checkElement(Object o) =>
      _isValidElement != null ? _isValidElement(o) : o is E;

  /// The elements of this set, ordered according to [_compare].
  final List<E> _elements;

  /// [hashCode] is computed lazy, and cached here.
  int _hashCode;

  /// Creates a Superset with the elements from `iterable` and the default
  /// `compare` and `isValidElement` functions.
  factory Superset([Iterable<E> iterable = const []]) =>
      (new SupersetBuilder<E>()..addAll(iterable)).build();

  /// Assumes the `_elements` argument is ordered according to `_compare` and
  /// only contains elements allowed by `_isValidElement`.
  Superset._withOrderedElements(
      this._compare, this._isValidElement, this._elements);

  /*
   * From IndexedSet
   */

  /// As [IndexedSet.containsKey].
  bool containsKey(int index) => 0 <= index && index < _elements.length;

  /// Returns the index of `element`, if `element` is in this set.
  ///
  /// Otherwise, returns `-1`.
  int index(E element) {
    if (!_checkElement(element)) return -1;
    return binarySearch(_elements, element, compare: _compare);
  }

  /// As [IndexedSet.operator[]].
  E operator [](int index) =>
      index != null && containsKey(index) ? _elements[index] : null;

  /*
   * From Iterable
   */

  @override
  E get first => _elements.first;

  @override
  bool get isEmpty => _elements.isEmpty;

  @override
  Iterator<E> get iterator => _elements.iterator;

  @override
  E get last => _elements.last;

  @override
  int get length => _elements.length;

  /// Alias of [operator[]].
  @override
  E elementAt(int index) => this[index];

  /*
   * From BuiltSet
   */

  /// As [BuiltSet.asSet].
  @override
  Set<E> asSet() => new _UnmodifiableSupersetView(this);

  /// As [BuiltSet.contains].
  @override
  bool contains(Object element) {
    if (element is! E) return false;
    return index(element) != -1;
  }

  /// As [BuiltSet.containsAll].
  @override
  bool containsAll(Iterable<E> elements) => elements.every(contains);

  /// As [BuiltSet.difference]. Uses `compare` and `isValidElement` of this.
  @override
  Superset<E> difference(Superset<Object> other) =>
      new Superset<E>._withOrderedElements(_compare, _isValidElement,
          new List.unmodifiable(_elements.where((el) => !other.contains(el))));

  /// As [BuiltSet.intersection]. Uses `compare` and `isValidElement` of this.
  @override
  Superset<E> intersection(Superset<Object> other) =>
      new Superset<E>._withOrderedElements(_compare, _isValidElement,
          new List.unmodifiable(_elements.where((el) => other.contains(el))));

  /// As [BuiltSet.lookup].
  @override
  E lookup(Object object) {
    if (object is! E) return null;
    final i = index(object);
    if (i == -1) return null;
    return _elements[i];
  }

  /// As [BuiltSet.toBuiltList].
  @override
  BuiltList<E> toBuiltList() => new BuiltList<E>(this);

  /// As [BuiltSet.toBuiltSet].
  @override
  BuiltSet<E> toBuiltSet() => new BuiltSet<E>(this);

  /// As [BuiltSet.union]. Uses `compare` and `isValidElement` of this.
  ///
  /// Throws an [ArgumentError] if `other` contains an element that gets
  /// rejected by `isValidElement` of this set.
  @override
  Superset<E> union(Superset<E> other) => (toBuilder()..addAll(other)).build();

  /*
   * From Built
   */

  /// As [BuiltSet.rebuild].
  @override
  Superset<E> rebuild(void updates(SupersetBuilder<E> builder)) =>
      (toBuilder()..update(updates)).build();

  /// As [BuiltSet.toBuilder].
  @override
  SupersetBuilder<E> toBuilder() =>
      new SupersetBuilder<E>(compare: _compare, isValidElement: _isValidElement)
        ..replace(this);

  // Equality and hashCode

  /// As [BuiltSet.hashCode].
  @override
  int get hashCode => _hashCode ??=
      hash4(index, _compare, _isValidElement, hashObjects(_elements));

  /// As [BuiltSet.operator==].
  @override
  bool operator ==(dynamic other) {
    if (identical(other, this)) return true;
    if (other is! Superset ||
        other._elementType != _elementType ||
        other._isValidElement != _isValidElement ||
        other._compare != _compare ||
        other.length != length ||
        other.hashCode != hashCode) return false;

    return containsAll(other);
  }

  Type get _elementType => E;
}

/// [Builder class]((https://pub.dartlang.org/packages/built_collection)) for
/// [Superset]. Implements the [SetBuilder] interface.
///
/// `compare` and `isValidElement` have to be provided when instantiating the
/// builder. The default comparator is [Comparable.compare], which will fail at
/// runtime if `E` does not implement [Comparable]. The default `isValidElement`
/// rejects all objects that are not `E` instances.
class SupersetBuilder<E>
    implements Builder<Superset<E>, SupersetBuilder<E>>, SetBuilder<E> {
  /// Used to sort [_elements].
  final Comparator<E> _compare;

  /// Optional callback. Should not be called directly, use [_checkElement]
  /// instead.
  final bool Function(Object) _isValidElement;

  /// Calls [_isValidElement], or uses an `is E` check as fallback.
  bool _checkElement(Object o) =>
      _isValidElement != null ? _isValidElement(o) : o is E;

  /// The current elements of this builder, ordered according to [_compare].
  SplayTreeSet<E> _elements;

  /// If [build] is called several times without changes to the builder, the
  /// same superset can be reused; it is cached here.
  Superset<E> _lastBuilt;

  SupersetBuilder(
      {Comparator<E> compare, bool isValidElement(Object potentialKey)})
      : _compare = compare ?? Comparable.compare,
        _isValidElement = isValidElement,
        _elements = new SplayTreeSet<E>(compare ?? Comparable.compare) {
    if (E == dynamic)
      throw new UnsupportedError('explicit element type required, '
          'for example "new SupersetBuilder<String>"');
  }

  /*
   * From Builder
   */

  @override
  Superset<E> build() {
    if (_lastBuilt == null) {
      _lastBuilt = new Superset<E>._withOrderedElements(
          _compare, _isValidElement, new List<E>.unmodifiable(_elements));
    }
    return _lastBuilt;
  }

  /// As [SetBuilder.replace].
  @override
  void replace(Iterable<Object> iterable) {
    if (iterable is Superset<E>) {
      _elements
        ..clear()
        ..addAll(iterable);
      _lastBuilt = iterable;
      return;
    }

    final elements = new SplayTreeSet<E>(_compare);
    var count = 0;
    for (final el in iterable) {
      if (!_checkElement(el))
        throw new ArgumentError.value(iterable, 'iterable',
            'element $count rejected by `isValidElement`');
      count++;
      elements.add(el);
    }
    _elements = elements;
    _markAsModified();
  }

  @override
  void update(void updates(SupersetBuilder<E> b)) => updates(this);

  /*
   * From SetBuilder
   */

  /// As [SetBuilder.add].
  @override
  void add(E element) {
    if (!_checkElement(element))
      throw new ArgumentError.value(element, 'rejected by `isValidElement`');
    _elements.add(element);
    _markAsModified();
  }

  /// As [SetBuilder.addAll]. Iterates over `elements` twice.
  @override
  void addAll(Iterable<E> elements) {
    var count = 0;
    for (final el in elements) {
      if (!_checkElement(el))
        throw new ArgumentError.value(elements, 'iterable',
            'element $count rejected by `isValidElement`');
      count++;
    }
    _elements.addAll(elements);
    _markAsModified();
  }

  /// As [SetBuilder.clear].
  @override
  void clear() {
    _elements.clear();
    _markAsModified();
  }

  /// As [SetBuilder.expand].
  @override
  void expand(Iterable<E> Function(E) f) => replace(_elements.expand<E>(f));

  /// As [SetBuilder.map].
  @override
  void map(E Function(E) f) => replace(_elements.map<E>(f));

  /// As [SetBuilder.remove].
  @override
  void remove(Object object) {
    if (!_checkElement(object)) return;
    if (_elements.remove(object)) _markAsModified();
  }

  /// As [SetBuilder.removeAll].
  @override
  void removeAll(Iterable<Object> iterable) => iterable.forEach(remove);

  /// As [SetBuilder.removeWhere].
  @override
  void removeWhere(bool Function(E) f) => retainWhere((E el) => !f(el));

  /// As [SetBuilder.retainAll].
  @override
  void retainAll(Iterable<Object> elements) {
    final lengthBefore = _elements.length;
    _elements.retainAll(elements);
    if (_elements.length != lengthBefore) _markAsModified();
  }

  /// As [SetBuilder.retainWhere]. Alias of [SupersetBuilder.where].
  @override
  void retainWhere(bool Function(E) f) {
    final lengthBefore = _elements.length;
    _elements.retainWhere(f);
    if (_elements.length != lengthBefore) _markAsModified();
  }

  /// As [SetBuilder.skip].
  @override
  void skip(int n) => replace(_elements.skip(n));

  /// As [SetBuilder.skipWhile].
  @override
  void skipWhile(bool Function(E) test) => replace(_elements.skipWhile(test));

  /// As [SetBuilder.take].
  @override
  void take(int n) => replace(_elements.take(n));

  /// As [SetBuilder.takeWhile].
  @override
  void takeWhile(bool Function(E) test) => replace(_elements.takeWhile(test));

  /// As [BuiltSet.where]. Alias of [SupersetBuilder.retainWhere].
  @override
  void where(bool Function(E) f) => retainWhere(f);

  void _markAsModified() => _lastBuilt = null;
}

class _UnmodifiableSupersetView<E> extends Subset<E> {
  final Superset<E> _superset;

  _UnmodifiableSupersetView(this._superset) : super(_superset);

  int index(E element) => _superset.index(element);
}
