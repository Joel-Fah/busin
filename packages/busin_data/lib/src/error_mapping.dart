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
  if (error is StorageException) return _fromStorage(error);
  if (error is FunctionException) return _fromFunction(error);
  // A session that could not be refreshed because there is no connection is not a refusal.
  if (error is AuthRetryableFetchException) return const Offline('The backend could not be reached.');
  if (error is AuthException) return NotAllowed('auth: ${error.statusCode ?? error.message}');
  if (error is SocketException || error is TimeoutException || error is HttpException) {
    return const Offline('The backend could not be reached.');
  }
  if (error is FormatException) return Unexpected('unexpected reply: ${error.message}');
  return Unexpected(error.runtimeType.toString());
}

RepositoryException _fromStorage(StorageException error) {
  final message = 'storage ${error.statusCode ?? 'error'}';
  return switch (error.statusCode) {
    '401' || '403' => NotAllowed(message),
    '404' => NotFound(message),
    '409' => Conflict(message),
    '400' || '413' || '415' => Invalid(message),
    _ => Unexpected(message),
  };
}

RepositoryException _fromFunction(FunctionException error) {
  final message = 'function ${error.status}';
  return switch (error.status) {
    401 || 403 || 429 => NotAllowed(message),
    404 => NotFound(message),
    400 || 422 => Invalid(message),
    _ => Unexpected(message),
  };
}

/// The short code a database function put in its error message (`bus_busy`), or null for any other text. Only a single
/// lowercase word with underscores qualifies, so a message with row contents or a sentence is never passed on.
String? _reasonOf(String? message) {
  final text = message?.trim() ?? '';
  return RegExp(r'^[a-z][a-z_]{2,39}$').hasMatch(text) ? text : null;
}

RepositoryException _fromCode(PostgrestException error) {
  final code = error.code ?? '';
  final message = 'database $code';
  final reason = _reasonOf(error.message);
  switch (code) {
    // Row Level Security, wrong role, or a function refusing the caller.
    case '42501':
    case '401':
    case '403':
    // Too many requests (a function's quota, raised as PT429 so PostgREST answers 429).
    case 'PT429':
      return NotAllowed(message, reason: reason);
    // No row (a single-row read found none), or an id the function does not know.
    case 'PGRST116':
    case 'P0002':
      return NotFound(message, reason: reason);
    // Unique violation, or a state that does not allow the change (for example already reviewed).
    case '23505':
    case '55000':
      return Conflict(message, reason: reason);
    // Bad value, constraint or reference.
    // A reference to a row that is gone (a semester or a stop removed meanwhile): said so, so a screen does not blame
    // something else.
    case '23503':
      return Invalid(message, reason: reason ?? 'missing_reference');
    case '22023':
    case '22P02':
    case '22007':
    case '22008':
    case '23502':
    case '23514':
      return Invalid(message, reason: reason);
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
