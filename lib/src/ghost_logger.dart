import 'dart:developer' as developer;

import 'crash_reporter.dart';
import 'log_level.dart';
import 'logger_type.dart';

/// A lightweight, flexible logging utility with optional crash reporting.
///
/// GhostLogger provides a clean API for logging messages with different severity
/// levels and output mechanisms. It works silently in the background, logging
/// to your terminal while automatically reporting errors to crash services.
///
/// **Tagline:** Stealing errors before they steal your users' experience.
///
/// ## Configuration
///
/// Configure the logger once at app startup:
///
/// ```
/// await GhostLogger.configure(
///   isDebugMode: true,
///   loggerType: LoggerType.console,
/// );
/// ```
///
/// ## Logging
///
/// Log messages with different severity levels:
///
/// ```
/// GhostLogger.log(
///   message: 'User logged in',
///   level: LogLevel.info,
///   tag: 'Auth',
/// );
/// ```
///
/// ## Crash Reporting
///
/// Integrate with Firebase Crashlytics or other services:
///
/// ```
/// await GhostLogger.configure(
///   isDebugMode: false,
///   crashReporter: GhostFirebase(),
///   enableCrashReporting: true,
/// );
/// ```
class GhostLogger {
  GhostLogger._();

  static bool _isDebugMode = true;
  static LoggerType _loggerType = LoggerType.print;
  static CrashReporter _crashReporter = const NullCrashReporter();
  static bool _reportToCrashlytics = false;

  /// Configures the logger with specified settings.
  ///
  /// This should be called once at application startup.
  ///
  /// [isDebugMode] controls whether logs are visible in console output.
  /// [loggerType] determines the output mechanism (default: print).
  /// [crashReporter] optional crash reporting service integration.
  /// [enableCrashReporting] whether to report logs to crash service (default: false).
  static Future<void> configure({
    required bool isDebugMode,
    LoggerType loggerType = LoggerType.print,
    CrashReporter? crashReporter,
    bool enableCrashReporting = false,
  }) async {
    _isDebugMode = isDebugMode;
    _loggerType = loggerType;
    _reportToCrashlytics = enableCrashReporting;

    if (crashReporter != null) {
      _crashReporter = crashReporter;
      await _crashReporter.setCollectionEnabled(enableCrashReporting);
    }
  }

  /// Logs a message with specified level and optional metadata.
  ///
  /// [message] the content to log (required).
  /// [level] severity of the log message (default: debug).
  /// [tag] optional identifier for the log source (e.g., 'Auth', 'API').
  /// [stackTrace] optional stack trace for error contexts.
  /// [reportToCrashService] override crash reporting for this specific log.
  static Future<void> log({
    required dynamic message,
    LogLevel level = LogLevel.debug,
    String? tag,
    StackTrace? stackTrace,
    bool? reportToCrashService,
  }) async {
    final shouldReportToCrash = reportToCrashService ?? _reportToCrashlytics;

    if (_isDebugMode) {
      final formattedMessage = _formatMessage(message, level, tag);
      _writeToConsole(formattedMessage, level, stackTrace);
    }

    if (shouldReportToCrash) {
      await _reportToCrashReporter(message, level, stackTrace);
    }
  }

  /// Formats the log message with emoji, level, and optional tag.
  static String _formatMessage(dynamic message, LogLevel level, String? tag) {
    final tagPrefix = tag != null ? '[$tag] ' : '';
    final levelName = level.name.toUpperCase();
    return '${level.emoji} $levelName: $tagPrefix$message';
  }

  /// Writes log to console based on configured logger type.
  static void _writeToConsole(
    String message,
    LogLevel level,
    StackTrace? stackTrace,
  ) {
    switch (_loggerType) {
      case LoggerType.print:
        // ignore: avoid_print
        print(message);
        if (stackTrace != null) {
          // ignore: avoid_print
          print(stackTrace);
        }
        break;

      case LoggerType.console:
        developer.log(
          message,
          level: level.numericLevel,
          name: 'GhostLogger',
          stackTrace: stackTrace,
        );
        break;

      case LoggerType.logger:
        // Reserved for future custom logger implementation
        developer.log(
          message,
          level: level.numericLevel,
          name: 'GhostLogger',
          stackTrace: stackTrace,
        );
        break;
    }
  }

  /// Reports message to configured crash reporting service.
  static Future<void> _reportToCrashReporter(
    dynamic message,
    LogLevel level,
    StackTrace? stackTrace,
  ) async {
    await _crashReporter.log('${level.emoji}: $message');

    if (stackTrace != null || level == LogLevel.error) {
      await _crashReporter.recordError(
        Exception(message),
        stackTrace,
        reason: level.name,
      );
    }
  }
}
