import 'dart:collection' show IterableBase, SplayTreeSet, SetMixin;

import 'package:built_collection/built_collection.dart'
    show BuiltList, BuiltSet, SetBuilder;
import 'package:collection/collection.dart' show binarySearch;
import 'package:collection/src/unmodifiable_wrappers.dart'
    show UnmodifiableSetMixin;
import 'package:meta/meta.dart';
import 'package:quiver/core.dart' show hashObjects;

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
class Superset<E> extends IterableBase<E> implements BuiltSet<E> {
  /// Used to look up objects in [_elements].
  final Comparator<E> _comparator;

  /// As `IndexedSet._filter`.
  final bool Function(E) _filter;

  /// As `IndexedSet._validElement`.
  bool _validElement(Object o) => o is E && (_filter == null || _filter(o));

  /// The elements of this set, ordered according to [_comparator].
  final List<E> _elements;

  /// [hashCode] is computed lazy, and cached here.
  int _hashCode;

  /// Creates a Superset with the elements from `iterable` and
  /// [Comparable.compare] as `comparator`.
  factory Superset([Iterable<E> iterable = const []]) =>
      (SupersetBuilder<E>()..addAll(iterable)).build();

  /// As [BuiltSet.build].
  factory Superset.build(void updates(SupersetBuilder<E> builder)) =>
      (SupersetBuilder<E>()..update(updates)).build();

  /// Assumes the `_elements` argument is ordered according to `_comparator` and
  /// only contains elements allowed by `_isValidElement`.
  Superset._withOrderedElements(
      this._comparator, this._filter, Iterable<E> elements)
      : _elements = List<E>.unmodifiable(elements);

  /*
   * From IndexedSet
   */

  /// As [IndexedSet.containsKey].
  bool containsKey(int index) => 0 <= index && index < _elements.length;

  /// Returns the index of `element`, if `element` is in this set.
  ///
  /// Otherwise, returns `-1`.
  int index(E element) => _validElement(element)
      ? binarySearch(_elements, element, compare: _comparator)
      : -1;

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

  @override
  E elementAt(int index) => _elements[index];

  /*
   * From BuiltSet
   */

  /// As [BuiltSet.asSet].
  @override
  IndexedSet<int, E> asSet() => _UnmodifiableSupersetView(this);

  /// As [BuiltSet.contains].
  @override
  bool contains(Object element) => element is E && index(element) != -1;

  /// As [BuiltSet.containsAll].
  @override
  bool containsAll(Iterable<Object> elements) => elements.every(contains);

  /// As [BuiltSet.difference]. Uses `comparator` and `isValidElement` of this.
  @override
  Superset<E> difference(BuiltSet<Object> other) =>
      Superset<E>._withOrderedElements(
          _comparator, _filter, _elements.where((el) => !other.contains(el)));

  /// As [BuiltSet.intersection]. Uses `comparator` and `isValidElement` of
  /// this.
  @override
  Superset<E> intersection(BuiltSet<Object> other) =>
      Superset<E>._withOrderedElements(
          _comparator, _filter, _elements.where((el) => other.contains(el)));

  /// As [BuiltSet.lookup].
  @override
  E lookup(Object object) {
    if (object is! E) return null;
    final i = index(object);
    return i != -1 ? _elements[i] : null;
  }

  /// As [BuiltSet.toBuiltList].
  @override
  BuiltList<E> toBuiltList() => BuiltList<E>(this);

  /// As [BuiltSet.toBuiltSet].
  @override
  BuiltSet<E> toBuiltSet() => this;

  /// Returns a [SplayTreeSet] with the same elements, comparator and filter as
  /// this set.
  @override
  SplayTreeSet<E> toSet() =>
      SplayTreeSet<E>(_comparator, _filter)..addAll(_elements);

  /// As [BuiltSet.union]. Uses `comparator` and `isValidElement` of this.
  ///
  /// Throws an [ArgumentError] if `other` contains an element that gets
  /// rejected by `isValidElement` of this set.
  @override
  Superset<E> union(BuiltSet<E> other) => (toBuilder()..addAll(other)).build();

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
      SupersetBuilder<E>(_comparator, _filter)..replace(this);

  /*
   * Equality and hashCode
   */

  /// As [BuiltSet.hashCode].
  @override
  int get hashCode => _hashCode ??= hashObjects(
      _elements.map((e) => e.hashCode).toList(growable: false)..sort());

  /// As [BuiltSet.operator==].
  @override
  bool operator ==(dynamic other) {
    if (identical(other, this)) return true;
    if (other is! BuiltSet) return false;
    if (other.length != length) return false;
    if (other.hashCode != hashCode) return false;
    return containsAll(other);
  }

  @override
  String toString() => IterableBase.iterableToShortString(this, '{', '}');
}

/// [Builder class]((https://pub.dartlang.org/packages/built_collection)) for
/// [Superset].
class SupersetBuilder<E> implements SetBuilder<E> {
  /// Used to sort [_elements].
  Comparator<E> _comparator;

  /// As `IndexedSet._filter`.
  bool Function(E) _filter;

  /// The current elements of this builder, ordered according to [_comparator].
  SplayTreeSet<E> _elements;

  /// If [E] is not [Comparable] and [withComparator] was never called on this
  /// builder, it is not initialized; all methods except [withComparator] will
  /// throw a [StateError] (through [_assertInitialized]).
  bool get _initialized => _comparator != null;

  /// If [build] is called several times without changes to the builder, the
  /// same superset can be reused; it is cached here.
  Superset<E> _lastBuilt;

  /// The elements of this builder (and its built supersets) are ordered
  /// according to [comparator].
  ///
  /// If [comparator] is not provided and [E] is [Comparable], then
  /// [Comparable.compare] will be used. Otherwise, it has to be set via
  /// [withComparator], and all other methods will throw a [StateError] until
  /// a comparator is provided.
  ///
  /// Only objects for which [isValidElement] returns `true` will be passed to
  /// [comparator]. This can be used if [comparator] does not work on all
  /// objects.
  factory SupersetBuilder(
      [Comparator<E> comparator, bool isValidElement(E element)]) {
    final result = SupersetBuilder<E>._uninitialized();
    if (comparator != null) {
      result.withComparator(comparator, isValidElement);
    } else if (Comparable.compare is Comparator<E>) {
      result.withComparator(Comparable.compare as Comparator<E>);
    }
    return result;
  }

  SupersetBuilder._uninitialized() {
    if (E == dynamic)
      throw UnsupportedError('explicit element type required, '
          'for example "new SupersetBuilder<String>"');
  }

  /*
   * From Builder
   */

  @override
  bool get isEmpty => _elements.isEmpty;
  @override
  bool get isNotEmpty => _elements.isNotEmpty;
  @override
  int get length => _elements.length;

  @override
  Superset<E> build() {
    _assertInitialized();
    return _lastBuilt ??=
        Superset<E>._withOrderedElements(_comparator, _filter, _elements);
  }

  /// As [SetBuilder.replace].
  @override
  void replace(Iterable<Object> iterable) {
    _assertInitialized();

    if (iterable is Superset<E> &&
        _comparator == iterable._comparator &&
        _filter == iterable._filter) {
      _elements
        ..clear()
        ..addAll(iterable);
      _lastBuilt = iterable;
      return;
    }

    final elements = SplayTreeSet<E>(_comparator);
    var count = 0;
    for (final el in iterable) {
      if (!_validElement(el))
        throw ArgumentError.value(iterable, 'iterable',
            'element $count rejected by `isValidElement`');
      count++;
      elements.add(el);
    }
    _elements = elements;
    _markAsModified();
  }

  @override
  void update(void updates(SupersetBuilder<E> b)) => updates(this);

  /// Throws [UnsupportedError].
  ///
  /// The superset class stores elements in an ordered list. Use
  /// `withComparator` to customize element order.
  @override
  @alwaysThrows
  void withBase(Set<E> base()) => throw new UnsupportedError(
      'The superset class stores elements in an ordered list. '
      'Use `withComparator` to customize element order.');

  /// Throws [UnsupportedError].
  ///
  /// The superset class stores elements in an ordered list. Use
  /// `withComparator` to customize element order.
  @override
  @alwaysThrows
  void withDefaultBase() => throw UnsupportedError(
      'The superset class stores elements in an ordered list. '
      'Use `withComparator` to customize element order.');

  /// Uses `comparator` as the comparator for all sets created by this builder.
  /// If `isValidElement` is provided, removes all elements from this builder
  /// that don't satisfy the filter criterion.
  void withComparator(Comparator<E> comparator,
      [bool isValidElement(E element)]) {
    if (comparator == null) throw ArgumentError.notNull('comparator');

    final elements = SplayTreeSet<E>(comparator);
    if (_initialized) {
      elements
        ..addAll(isValidElement == null
            ? _elements
            : _elements.where(isValidElement));
    }

    _comparator = comparator;
    _filter = isValidElement;
    _elements = elements;
    _markAsModified();
  }

  /*
   * From SetBuilder
   */

  /// As [SetBuilder.add].
  @override
  void add(E element) {
    _assertInitialized();
    if (!_validElement(element))
      throw ArgumentError.value(element, 'rejected by `isValidElement`');
    _elements.add(element);
    _markAsModified();
  }

  /// As [SetBuilder.addAll]. Iterates over `elements` twice.
  @override
  void addAll(Iterable<E> elements) {
    _assertInitialized();
    var count = 0;
    for (final el in elements) {
      if (!_validElement(el))
        throw ArgumentError.value(elements, 'iterable',
            'element $count rejected by `isValidElement`');
      count++;
    }
    _elements.addAll(elements);
    _markAsModified();
  }

  /// As [SetBuilder.clear].
  @override
  void clear() {
    _assertInitialized();
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
  bool remove(Object object) {
    _assertInitialized();
    if (!_validElement(object) || !_elements.remove(object)) {
      return false;
    }
    _markAsModified();
    return true;
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
    _assertInitialized();
    final lengthBefore = _elements.length;
    _elements.retainAll(elements);
    if (_elements.length != lengthBefore) _markAsModified();
  }

  /// As [SetBuilder.retainWhere]. Alias of [SupersetBuilder.where].
  @override
  void retainWhere(bool Function(E) f) {
    _assertInitialized();
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

  /// As `IndexedSet._validElement`.
  bool _validElement(Object o) => o is E && (_filter == null || _filter(o));

  /// Must be called whenever [_elements] is modified. Invalidates [_lastBuilt].
  void _markAsModified() => _lastBuilt = null;

  /// Throws a [StateError] if this builder has not been  initialized by
  /// [withComparator].
  void _assertInitialized() =>
      _initialized ||
      (throw StateError('This builder has no `comparator`. '
          'Use `withComparator` to provide one.'));
}

/// An unmodifiable view of a [Superset] for [Superset.asSet].
class _UnmodifiableSupersetView<E> extends SetMixin<E>
    with UnmodifiableSetMixin<E>
    implements IndexedSet<int, E> {
  /// All method calls are delegated to this object.
  final Superset<E> _superset;

  @override
  Iterator<E> get iterator => _superset.iterator;

  @override
  int get length => _superset.length;

  _UnmodifiableSupersetView(this._superset);

  @override
  bool containsKey(int i) => _superset.containsKey(i);

  @override
  bool contains(Object object) => _superset.contains(object);

  @override
  int index(E element) => _superset.index(element);

  @override
  E lookup(Object object) => _superset.lookup(object);

  @override
  IndexedSet<int, E> toSet() => this;

  @override
  E operator [](int i) => _superset[i];
}
