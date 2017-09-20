import 'package:collection/src/empty_unmodifiable_set.dart';
import 'unmodifiable_set_view.dart';

class EmptyIndexedSet<I, E> extends EmptyUnmodifiableSet<E>
    implements UnmodifiableIndexedSetView<I, E> {
  @override
  final I Function(E) index;

  const EmptyIndexedSet(this.index);

  @override
  E operator [](I index) => null;
  @override
  bool containsKey(I index) => false;
}
