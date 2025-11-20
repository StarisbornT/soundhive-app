extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test, {required Null Function() orElse}) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}