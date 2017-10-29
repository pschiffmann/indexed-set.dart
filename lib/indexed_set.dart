export 'src/indexed_set.dart';
export 'src/unmodifiable_set_view.dart';

/// Thrown by [IndexedSet.add] when an element is added to the set that has the
/// same index as a preexisting element, but is not equal to it.
class DuplicateIndexException<I, E> implements Exception {
  /// The index of [collidingElement]. (which is equal to the index of
  /// [preexistingElement] according to the `areIndexesEqual` of the set)
  final I index;

  /// The element that was present in the set when [IndexedSet.add] was called.
  final E preexistingElement;

  /// The argument to [IndexedSet.add].
  final E collidingElement;

  DuplicateIndexException(
      this.index, this.preexistingElement, this.collidingElement);

  @override
  String toString() => 'duplicate index ($index): '
      'Could not add $collidingElement to a set that contains '
      '$preexistingElement because they have the same index';
}
