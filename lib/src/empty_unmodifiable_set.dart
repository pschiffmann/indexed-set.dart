import 'package:collection/src/empty_unmodifiable_set.dart';
import 'unmodifiable_set_view.dart';

class EmptyIndexedSet<I, E> extends EmptyUnmodifiableSet<E>
    implements UnmodifiableIndexedSetView<I, E> {
  final I Function(E) _index;

  const EmptyIndexedSet(this._index);

  @override
  E operator [](I index) => null;
  @override
  I index(E element) => _index(element);
  @override
  bool containsKey(I index) => false;
}
