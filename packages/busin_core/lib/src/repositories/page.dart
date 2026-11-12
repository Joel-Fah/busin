/// Which slice of a list to load. Lists are always paginated, so an app loads
/// only what it shows.
class PageRequest {
  const PageRequest({this.limit = defaultLimit, this.offset = 0})
      : assert(limit > 0 && limit <= maxLimit),
        assert(offset >= 0);

  static const int defaultLimit = 20;
  static const int maxLimit = 100;

  final int limit;
  final int offset;

  /// The request for the slice after this one.
  PageRequest get next => PageRequest(limit: limit, offset: offset + limit);

  /// The last row of the slice, for range-based queries (inclusive).
  int get lastIndex => offset + limit - 1;
}
