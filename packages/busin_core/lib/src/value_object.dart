/// Base class for immutable models compared by value.
///
/// Subclasses list the fields that define equality in [props]. This avoids a
/// dependency on an equality package in the domain layer.
abstract class ValueObject {
  const ValueObject();

  /// The fields that make two instances equal.
  List<Object?> get props;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType || other is! ValueObject) return false;
    final a = props;
    final b = other.props;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(props);
}
