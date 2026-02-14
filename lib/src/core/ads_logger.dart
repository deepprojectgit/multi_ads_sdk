import 'package:flutter/foundation.dart';

import 'ad_type.dart';

/// Logger for ad failures and exceptions.
///
/// Use [setLogger] to provide a custom handler (e.g. send to Crashlytics).
/// By default, failures are printed in debug mode via [debugPrint].
class AdsLogger {
  AdsLogger._();

  /// Custom log handler. If set, it receives all ad failure/exception logs.
  /// Parameters: [adType], [message], [error], [stackTrace].
  static void Function(
    AdType? adType,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ])? _customLogger;

  /// Set a custom logger for ad failures and exceptions.
  ///
  /// Example (Firebase Crashlytics):
  /// ```dart
  /// AdsLogger.setLogger((adType, message, [error, stackTrace]) {
  ///   FirebaseCrashlytics.instance.log('Ad failure: $adType - $message');
  ///   if (error != null) FirebaseCrashlytics.instance.recordError(error, stackTrace);
  /// });
  /// ```
  static void setLogger(
    void Function(
      AdType? adType,
      String message, [
      Object? error,
      StackTrace? stackTrace,
    ])? logger,
  ) {
    _customLogger = logger;
  }

  /// Log an ad load failure (e.g. from platform [onAdFailedToLoad]).
  static void logAdFailedToLoad(AdType adType, String error) {
    final message = 'Ad failed to load: $adType, Error: $error';
    _log(adType, message, null, null);
  }

  /// Log when show is called but ad is not loaded (no stack trace).
  static void logAdNotLoaded(AdType adType, String detail) {
    final message = 'Ad not loaded (load first): $adType. $detail';
    _log(adType, message, null, null);
  }

  /// Log an exception during an ad operation (init, load, show, etc.).
  static void logException(
    AdType? adType,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _log(adType, message, error, stackTrace);
  }

  static void _log(
    AdType? adType,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    final prefix = adType != null ? '[$adType] ' : '';
    final fullMessage = '$prefix$message';

    if (_customLogger != null) {
      _customLogger!(adType, message, error, stackTrace);
    }

    if (kDebugMode) {
      debugPrint('[MultiAdsManager] $fullMessage');
      if (error != null) {
        debugPrint('[MultiAdsManager] Exception: $error');
        if (stackTrace != null) {
          debugPrint('[MultiAdsManager] $stackTrace');
        }
      }
    }
  }
}
