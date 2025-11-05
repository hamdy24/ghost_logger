/// Abstract interface for crash reporting services.
///
/// Implement this interface to integrate with your preferred crash reporting
/// service (Firebase Crashlytics, Sentry, custom solutions, etc.).
///
/// Example:
/// ```
/// class CustomCrashReporter implements CrashReporter {
///   @override
///   Future<void> log(String message) async {
///     // Send to your crash service
///   }
///
///   @override
///   Future<void> recordError(dynamic exception, StackTrace? stackTrace, {String? reason}) async {
///     // Record error in your service
///   }
///
///   @override
///   Future<void> setCollectionEnabled(bool enabled) async {
///     // Enable/disable crash collection
///   }
/// }
/// ```
abstract class CrashReporter {
  /// Creates a new [CrashReporter] instance.
  const CrashReporter();

  /// Logs a message to the crash reporting service.
  Future<void> log(String message);

  /// Records an error with optional stack trace.
  ///
  /// [exception] the error or exception to record.
  /// [stackTrace] optional stack trace for context.
  /// [reason] optional reason for the error.
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
  });

  /// Sets whether crash collection is enabled.
  ///
  /// Use this to disable collection in debug mode or based on user preferences.
  Future<void> setCollectionEnabled(bool enabled);
}

/// No-op implementation for when crash reporting is disabled.
///
/// This implementation does nothing, making it safe to use when crash
/// reporting is not configured.
class NullCrashReporter implements CrashReporter {
  /// Creates a no-op [CrashReporter] that does nothing.
  ///
  /// Useful for testing or when crash reporting is disabled.
  const NullCrashReporter();

  @override
  Future<void> log(String message) async {}

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
  }) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}
