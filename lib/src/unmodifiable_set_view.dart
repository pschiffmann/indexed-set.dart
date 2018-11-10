import 'package:collection/collection.dart';
import 'package:collection/src/empty_unmodifiable_set.dart';

import 'indexed_set.dart';

/// An unmodifiable set.
///
/// An UnmodifiableIndexedSetView contains an [IndexedSet] object and ensures
/// that it does not change. Methods that would change the set, such as [add]
/// and [remove], throw an [UnsupportedError]. Permitted operations defer to the
/// wrapped set.
class UnmodifiableIndexedSetView<I, E> extends UnmodifiableSetView<E>
    implements IndexedSet<I, E> {
  final IndexedSet<I, E> _base;

  @override
  I index(E element) => _base.index(element);

  UnmodifiableIndexedSetView(IndexedSet<I, E> setBase)
      : _base = setBase,
        super(setBase);

  const factory UnmodifiableIndexedSetView.empty(I Function(E) index) =
      EmptyIndexedSet<I, E>;

  @override
  E operator [](I index) => _base[index];

  @override
  bool containsKey(I index) => _base.containsKey(index);

  /// Returns `this`.
  @override
  IndexedSet<I, E> toSet() => this;
}

class EmptyIndexedSet<I, E> extends EmptyUnmodifiableSet<E>
    implements UnmodifiableIndexedSetView<I, E> {
  @override
  IndexedSet<I, E> get _base =>
      throw UnsupportedError('Unnecessary for a set that is always empty');

  final I Function(E) _index;

  const EmptyIndexedSet(this._index);

  @override
  E operator [](I index) => null;
  @override
  I index(E element) => _index(element);
  @override
  bool containsKey(I index) => false;
  @override
  IndexedSet<I, E> toSet() => this;
}
