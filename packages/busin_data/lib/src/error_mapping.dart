import 'dart:async';
import 'dart:io';

import 'package:busin_core/busin_core.dart';
import 'package:supabase/supabase.dart';

/// Turns what the backend SDK throws into the repository exceptions apps handle.
/// Anything already mapped passes through unchanged. The messages carry codes,
/// never row contents, so they are safe to log.
RepositoryException mapError(Object error) {
  if (error is RepositoryException) return error;
  if (error is PostgrestException) return _fromCode(error);
  if (error is AuthException) return NotAllowed('auth: ${error.statusCode ?? error.message}');
  if (error is SocketException || error is TimeoutException || error is HttpException) {
    return const Offline('The backend could not be reached.');
  }
  if (error is FormatException) return Unexpected('unexpected reply: ${error.message}');
  return Unexpected(error.runtimeType.toString());
}

RepositoryException _fromCode(PostgrestException error) {
  final code = error.code ?? '';
  final message = 'database $code';
  switch (code) {
    // Row Level Security, wrong role, or a function refusing the caller.
    case '42501':
    case '401':
    case '403':
      return NotAllowed(message);
    // No row (a single-row read found none), or an id the function does not know.
    case 'PGRST116':
    case 'P0002':
      return NotFound(message);
    // Unique violation, or a state that does not allow the change (for example already reviewed).
    case '23505':
    case '55000':
      return Conflict(message);
    // Bad value, constraint or reference.
    case '22023':
    case '22P02':
    case '22007':
    case '22008':
    case '23502':
    case '23503':
    case '23514':
      return Invalid(message);
    default:
      return Unexpected(message);
  }
}

/// Runs [body] and reports any failure as a repository exception.
Future<T> guarded<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on Object catch (error) {
    throw mapError(error);
  }
}
