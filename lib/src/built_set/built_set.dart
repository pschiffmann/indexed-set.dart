import 'dart:collection' show IterableBase;
import 'package:built_collection/built_collection.dart'
    show BuiltList, BuiltSet, SetBuilder;
import 'package:quiver/core.dart' show hashObjects;
import 'indexed_set.dart';

class BuiltIndexedSet<I, E> extends IterableBase<E> implements BuiltSet<E> {
  final IndexedSet<I, E> Function() _setFactory;
  final IndexedSet<I, E> _set;
  int _hashCode;

  /// As [new BuiltSet].
  factory BuiltIndexedSet(I Function(E) index, [Iterable iterable = const []]) {
    if (iterable is BuiltIndexedSet && iterable.hasExactElementType(E)) {
      return iterable as BuiltSet<E>;
    } else {
      return new BuiltIndexedSet<I, E>.copyAndCheck(iterable);
    }
  }

  /// As [BuiltSet.build].
  factory BuiltIndexedSet.build(
          void Function(IndexedSetBuilder<I, E>) updates) =>
      (new IndexedSetBuilder<I, E>()..update(updates)).build();

  /// As [BuiltSet.toBuilder].
  IndexedSetBuilder<I, E> toBuilder() =>
      new IndexedSetBuilder<I, E>._fromBuiltSet(this);

  /// As [BuiltSet.rebuild].
  BuiltIndexedSet<I, E> rebuild(void Function(SetBuilder<E>) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BuiltList<E> toBuiltList() => new BuiltList<E>(this);

  @override
  BuiltIndexedSet<I, E> toBuiltSet() => this;

  @override
  int get hashCode => _hashCode ??=
      hashObjects(_set.map((e) => e.hashCode).toList(growable: false)..sort());

  @override
  bool operator ==(dynamic other) {
    if (identical(other, this)) return true;
    if (other is! BuiltSet) return false;
    if (other.length != length) return false;
    if (other.hashCode != hashCode) return false;
    return containsAll(other);
  }

  @override
  String toString() => _set.toString();

  /// Returns as an immutable set.
  ///
  /// Useful when producing or using APIs that need the [Set] interface. This
  /// differs from [toSet] where mutations are explicitly disallowed.
  Set<E> asSet() => new UnmodifiableSetView<E>(_set);

  // Set.

  /// As [Set.length].
  @override
  int get length => _set.length;

  /// As [Set.containsAll].
  bool containsAll(Iterable<Object> other) => _set.containsAll(other);

  /// As [Set.difference] but takes and returns a `BuiltSet<E>`.
  BuiltSet<E> difference(BuiltSet<Object> other) =>
      new _BuiltSet<E>.withSafeSet(_setFactory, _set.difference(other._set));

  /// As [Set.intersection] but takes and returns a `BuiltSet<E>`.
  BuiltSet<E> intersection(BuiltSet<Object> other) =>
      new _BuiltSet<E>.withSafeSet(_setFactory, _set.intersection(other._set));

  /// As [Set.lookup].
  E lookup(Object object) => _set.lookup(object);

  /// As [Set.union] but takes and returns a `BuiltSet<E>`.
  BuiltSet<E> union(BuiltSet<E> other) =>
      new _BuiltSet<E>.withSafeSet(_setFactory, _set.union(other._set));

  // Iterable.

  @override
  Iterator<E> get iterator => _set.iterator;

  @override
  Iterable<T> map<T>(T f(E e)) => _set.map(f);

  @override
  Iterable<E> where(bool test(E element)) => _set.where(test);

  @override
  Iterable<T> expand<T>(Iterable<T> f(E e)) => _set.expand(f);

  @override
  bool contains(Object element) => _set.contains(element);

  @override
  void forEach(void f(E element)) => _set.forEach(f);

  @override
  E reduce(E combine(E value, E element)) => _set.reduce(combine);

  @override
  T fold<T>(T initialValue, T combine(T previousValue, E element)) =>
      _set.fold(initialValue, combine);

  @override
  bool every(bool test(E element)) => _set.every(test);

  @override
  String join([String separator = '']) => _set.join(separator);

  @override
  bool any(bool test(E element)) => _set.any(test);

  /// As [Iterable.toSet].
  ///
  /// Note that the implementation is efficient: it returns a copy-on-write
  /// wrapper around the data from this `BuiltSet`. So, if no mutations are
  /// made to the result, no copy is made.
  ///
  /// This allows efficient use of APIs that ask for a mutable collection
  /// but don't actually mutate it.
  @override
  Set<E> toSet() => new CopyOnWriteSet<E>(_set, _setFactory);

  @override
  List<E> toList({bool growable: true}) => _set.toList(growable: growable);

  @override
  bool get isEmpty => _set.isEmpty;

  @override
  bool get isNotEmpty => _set.isNotEmpty;

  @override
  Iterable<E> take(int n) => _set.take(n);

  @override
  Iterable<E> takeWhile(bool test(E value)) => _set.takeWhile(test);

  @override
  Iterable<E> skip(int n) => _set.skip(n);

  @override
  Iterable<E> skipWhile(bool test(E value)) => _set.skipWhile(test);

  @override
  E get first => _set.first;

  @override
  E get last => _set.last;

  @override
  E get single => _set.single;

  @override
  E firstWhere(bool test(E element), {E orElse()}) =>
      _set.firstWhere(test, orElse: orElse);

  @override
  E lastWhere(bool test(E element), {E orElse()}) =>
      _set.lastWhere(test, orElse: orElse);

  @override
  E singleWhere(bool test(E element)) => _set.singleWhere(test);

  @override
  E elementAt(int index) => _set.elementAt(index);

  // Internal.

  BuiltIndexedSet._(this._setFactory, this._set) {
    if (E == dynamic) {
      throw new UnsupportedError(
          'explicit element type required, for example "new BuiltSet<int>"');
    }
  }
}

class IndexedSetBuilder<I, E> implements SetBuilder<E> {}
