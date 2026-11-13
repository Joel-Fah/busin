import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A provider's answer as a guarded screen should read it. While a value is in hand, reloading it (or a reload that
/// fails) keeps that value: a background refresh must never send the person back to the loading screen and rebuild the
/// app under their hands. [belongs] says whether the value in hand is still the right one (for example the profile of
/// the person signed in now); when it is not, the reload counts as loading, as the first read does.
({bool loading, Object? error, T? value}) held<T>(AsyncValue<T> async, {bool Function(T value)? belongs}) {
  if (async.hasValue) {
    final value = async.requireValue;
    if (belongs == null || belongs(value)) return (loading: false, error: null, value: value);
  }
  if (async.hasError && !async.isLoading) return (loading: false, error: async.error, value: null);
  return (loading: true, error: null, value: null);
}
