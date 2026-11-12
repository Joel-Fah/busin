/// A problem a repository reports, in terms the app can act on. The data layer maps
/// backend errors onto these, so no app depends on a backend SDK's error types.
sealed class RepositoryException implements Exception {
  const RepositoryException(this.message, {this.reason});

  /// A short description for logs. It never holds personal data, and it is not
  /// shown to people: screens choose their own localized text from the type.
  final String message;

  /// Why, when the backend gave a short code for it (for example `bus_busy` or `use_scheduled_trip`). It is one of the
  /// snake_case words our own functions raise, never row contents. Null when there is none.
  final String? reason;

  @override
  String toString() => '$runtimeType: $message';
}

/// The caller may not do this (wrong role, suspended account, another school).
class NotAllowed extends RepositoryException {
  const NotAllowed(super.message, {super.reason});
}

/// What was asked for does not exist, or is not visible to the caller.
class NotFound extends RepositoryException {
  const NotFound(super.message, {super.reason});
}

/// The request clashes with what is stored, for example a second live
/// subscription in the same semester.
class Conflict extends RepositoryException {
  const Conflict(super.message, {super.reason});
}

/// The request was refused as malformed, or refused by a rule of the database.
class Invalid extends RepositoryException {
  const Invalid(super.message, {super.reason});
}

/// The backend could not be reached. Trying again later may work.
class Offline extends RepositoryException {
  const Offline(super.message, {super.reason});
}

/// Anything else. The message may help a developer; the screen shows a generic error.
class Unexpected extends RepositoryException {
  const Unexpected(super.message, {super.reason});
}
