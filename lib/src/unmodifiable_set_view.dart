import 'package:collection/collection.dart';
import 'empty_unmodifiable_set.dart';
import 'indexed_set.dart';

/// An unmodifiable set.
///
/// An UnmodifiableSetView contains a [Set] object and ensures that it does not
/// change. Methods that would change the set, such as [add] and [remove], throw
/// an [UnsupportedError]. Permitted operations defer to the wrapped set.
class UnmodifiableIndexedSetView<I, E> extends UnmodifiableSetView<E>
    implements IndexedSet<I, E> {
  final IndexedSet<I, E> _base;

  @override
  I Function(E) get index => _base.index;

  UnmodifiableIndexedSetView(IndexedSet<I, E> setBase)
      : _base = setBase,
        super(setBase);

  const factory UnmodifiableIndexedSetView.empty(I Function(E) index) =
      EmptyIndexedSet;

  @override
  E operator [](I index) => _base[index];

  @override
  bool containsKey(I index) => _base.containsKey(index);
}
