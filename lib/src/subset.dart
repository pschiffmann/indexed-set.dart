import 'indexed_set.dart';
import 'superset.dart';

class Subset<E> extends IndexedSet<int, E> {
  Subset(Superset<E> superset) : super(null);
}
