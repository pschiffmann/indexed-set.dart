import 'dart:collection' show SetMixin;
import 'dart:typed_data' show Uint8List;
import 'indexed_set.dart';
import 'superset.dart';

/// Returns the number of `1` bits in `byte`, which must not be negative.
int _countBits(int byte) {
  var count = 0;
  while (byte > 0) {
    count += byte & 1;
    byte >>= 1;
  }
  return count;
}

/// A subset only contains elements from its [superset].
///
/// Because the superset is immutable and assigns an index to each of its
/// elements, this class is very space-efficient, using only 1 bit per element
/// in the superset. Set operations ([difference], [intersection], [union],
/// [addAll], [removeAll], [retainAll]) on subsets of the same superset benefit
/// from this as well.
class Subset<E> extends SetMixin<E> implements IndexedSet<int, E> {
  /// This object dictates which elements this set can store, and provides its
  /// [index] and `isValidElement` functions.
  final Superset<E> superset;

  /// Each bit in this list indicates the presence (`1`) or absense (`0`) of the
  /// element with the corresponding index in [superset].
  Uint8List _elements;

  /// Cached [length]. Kept in sync with [_elements] by all mutating methods,
  /// and by [_updateLength].
  int _length;

  /// Is incremented every time this set is changed (by [add] and [remove]).
  /// Read by [_SubsetIterator] to detect concurrent modifications.
  int _modificationCount = 0;

  @override
  Iterator<E> get iterator => new _SubsetIterator(this);

  @override
  int get length => _length;

  /// Creates a subset of `superset`.
  ///
  /// If `filled` is `true`, the set initially contains all elements from
  /// `superset`. Else, it is initialized empty.
  Subset(this.superset, {bool filled: false})
      : _elements = new Uint8List(
            superset.length ~/ 8 + (superset.length % 8 > 0 ? 1 : 0)),
        _length = 0 {
    if (filled) {
      for (var i = 0; i < _elements.length - 1; i++) {
        _elements[i] = 255;
      }
      if (_elements.isNotEmpty) {
        // In the last byte, set only the bits to `1` that are actually used
        // so the unused bits won't be counted by [_updateLength].
        _elements[_elements.length - 1] = 255 >> (8 - superset.length % 8);
      }
      _length = superset.length;
    }
  }

  Subset._copy(Subset<E> other)
      : superset = other.superset,
        _elements = new Uint8List.fromList(other._elements),
        _length = other._length;

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
    _length++;
    _modificationCount++;
    return true;
  }

  @override
  void addAll(Iterable<E> elements) {
    if (elements is Subset<E> && superset == elements.superset) {
      for (var i = 0; i < _elements.length; i++) {
        _elements[i] |= elements._elements[i];
      }
      _updateLength();
      _modificationCount++;
    } else {
      super.addAll(elements);
    }
  }

  @override
  void clear() {
    _elements = new Uint8List(_elements.length);
    _length = 0;
    _modificationCount++;
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
  Subset<E> difference(Set<Object> other) => toSet()..removeAll(other);

  @override
  Subset<E> intersection(Set<Object> other) {
    if (other is Subset<E> && superset == other.superset) {
      return toSet()..retainAll(other);
    } else {
      return super.intersection(other);
    }
  }

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
    _length--;
    _modificationCount++;
    return true;
  }

  @override
  void removeAll(Iterable<Object> elements) {
    if (elements is Subset<E> && superset == elements.superset) {
      for (var i = 0; i < _elements.length; i++) {
        _elements[i] &= ~elements._elements[i];
      }
      _updateLength();
      _modificationCount++;
    } else {
      super.removeAll(elements);
    }
  }

  @override
  void retainAll(Iterable<Object> elements) {
    if (elements is Subset<E> && superset == elements.superset) {
      for (var i = 0; i < _elements.length; i++) {
        _elements[i] &= elements._elements[i];
      }
      _updateLength();
      _modificationCount++;
    } else {
      super.retainAll(elements);
    }
  }

  @override
  Subset<E> toSet() => new Subset<E>._copy(this);

  @override
  E operator [](int i) => containsKey(i) ? superset[i] : null;

  /// Returns [true] if the ith bit in [_elements] is set.
  bool _checkElement(int i) => _elements[i ~/ 8] & 1 << i % 8 > 0;

  /// Sets the ith bit in [_elements] to `1`.
  void _setElement(int i) => _elements[i ~/ 8] |= 1 << i % 8;

  /// Sets the ith bit in [_elements] to `0`.
  void _unsetElement(int i) => _elements[i ~/ 8] &= ~(1 << i % 8);

  /// Counts the number of set bits in [_elements] and updates [_length].
  void _updateLength() =>
      _length = _elements.fold(0, (count, byte) => count + _countBits(byte));
}

class _SubsetIterator<E> implements Iterator<E> {
  final Subset<E> _subset;

  /// The index of [current] in `_subset.superset`. `-1` indicates that the
  /// iterator is uninitialized ([moveNext] was never called).
  int _position = -1;

  /// The value of `_subset._modificationCount` at the time when this iterator
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
    while (_position + 1 < _subset.superset.length) {
      _position++;
      if (_subset._checkElement(_position)) {
        _current = _subset[_position];
        return true;
      }
    }
    return false;
  }
}
