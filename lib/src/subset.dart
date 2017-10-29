import 'dart:typed_data' show Uint8List;
import 'dart:collection' show SetMixin;
import 'indexed_set.dart';
import 'superset.dart';

/// A subset only contains elements from its [superset].
///
/// Because the superset is immutable and assigns an index to each of its
/// elements, this class can be implemented very space-efficient, using only 1
/// bit per element in the superset. Set operations ([difference],
/// [intersection], [union]) on subsets of the same superset benefit from this
/// as well.
class Subset<E> extends SetMixin<E> implements IndexedSet<int, E> {
  /// This object dictates which elements this set can store, and provides its
  /// [index] and `isValidElement` functions.
  final Superset<E> superset;

  /// Each bit in this list indicates the presence (`1`) or absense (`0`) of the
  /// element with the corresponding index in [superset].
  final Uint8List _elements;

  /// Is incremented every time this set is changed (by [add] and [remove]).
  /// Read by [_SubsetIterator] to detect and throw on concurrent modifications.
  int _modificationCount = 0;

  @override
  Iterator<E> get iterator => new _SubsetIterator(this);

  @override
  int get length => superset.length;

  Subset(this.superset)
      : _elements = new Uint8List(
            superset.length ~/ 8 + (superset.length % 8 > 0 ? 1 : 0));

  @override
  bool add(E element) {
    final i = index(element);
    if (i == -1) {
      throw new ArgumentError.value(
          element,
          'element',
          "The element can't be added to this subset "
          "because it isn't present in the superset");
    }
    if (_checkElement(i)) return false;
    _setElement(i);
    _modificationCount++;
    return true;
  }

  @override
  bool contains(Object object) {
    if (object is! E) return false;
    final i = index(object);
    if (i == -1) return false;
    return _checkElement(i);
  }

  @override
  bool containsKey(int i) => superset.containsKey(i) && _checkElement(i);

  @override
  int index(E element) => superset.index(element);

  @override
  E lookup(Object object) {
    if (object is! E) return null;
    final i = index(object);
    if (i == -1) return null;
    return this[i];
  }

  @override
  bool remove(Object object) {
    if (object is! E) return false;
    final i = index(object);
    if (i == -1 || !_checkElement(i)) return false;
    _unsetElement(i);
    _modificationCount++;
    return true;
  }

  @override
  Subset<E> toSet() => new Subset<E>(superset);

  @override
  E operator [](int i) => containsKey(i) ? superset[i] : null;

  /// Returns [true] if the ith bit in [_elements] is set.
  bool _checkElement(int i) => _elements[i ~/ 8] & 1 << i % 8 > 0;

  /// Sets the ith bit in [_elements] to `1`.
  void _setElement(int i) => _elements[i ~/ 8] |= 1 << i % 8;

  /// Sets the ith bit in [_elements] to `0`.
  void _unsetElement(int i) => _elements[i ~/ 8] &= ~(1 << i % 8);
}

class _SubsetIterator<E> implements Iterator<E> {
  final Subset<E> _subset;

  /// The index of [current] in [_subset]. `-1` indicates that the iterator is
  /// uninitialized ([moveNext] was never called).
  int _position = -1;

  /// The value of [_subset._modificationCount] at the time when this iterator
  /// was created. Used to detect and throw on concurrent modifications.
  final int _modificationCount;

  /// Cached [current] object.
  E _current;

  @override
  E get current => _current;

  _SubsetIterator(this._subset)
      : _modificationCount = _subset._modificationCount;

  @override
  bool moveNext() {
    if (_modificationCount != _subset._modificationCount) {
      throw new ConcurrentModificationError(_subset);
    }
    while (_position + 1 < _subset.length) {
      _position++;
      if (_subset._checkElement(_position)) {
        _current = _subset[_position];
        return true;
      }
    }
    return false;
  }
}
