import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

import 'ansi_colors.dart';
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
/// ## Basic Usage
///
/// ```
/// await GhostLogger.configure(
///   loggerType: LoggerType.print,
/// );
///
/// GhostLogger.logInfo('User logged in', tag: 'Auth');
/// GhostLogger.logError('Network failed', stackTrace: StackTrace.current);
/// ```
class GhostLogger {
  GhostLogger._();

  static bool _isDebugMode = kDebugMode;
  static LoggerType _loggerType = LoggerType.print;
  static CrashReporter _crashReporter = const NullCrashReporter();
  static bool _withColors = true;
  static bool _reportToCrashlytics = false;

  /// Configures the logger with specified settings.
  ///
  /// This should be called once at application startup.
  ///
  /// [isDebugMode] controls whether logs are visible in console output.
  /// Defaults to Flutter's [kDebugMode].
  /// [loggerType] determines the output mechanism (default: print).
  /// [crashReporter] optional crash reporting service integration.
  /// [withColors] whether to colorize log output (default: true).
  /// [enableCrashReporting] whether to report logs to crash service (default: false).
  static Future<void> configure({
    bool isDebugMode = kDebugMode,
    LoggerType loggerType = LoggerType.print,
    CrashReporter? crashReporter,
    bool withColors = true,
    bool enableCrashReporting = false,
  }) async {
    _isDebugMode = isDebugMode;
    _loggerType = loggerType;
    _reportToCrashlytics = enableCrashReporting;
    _withColors = withColors;

    if (crashReporter != null) {
      _crashReporter = crashReporter;
      await _crashReporter.setCollectionEnabled(enableCrashReporting);
    }
  }

  /// Logs a message with specified level and optional metadata.
  ///
  /// [message] the content to log (required).
  /// [level] severity of the log message (default: debug).
  /// [tag] optional identifier for the log source.
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

  /// Logs a debug message.
  ///
  /// Convenience method for debug-level logging.
  ///
  /// Example:
  /// ```
  /// GhostLogger.logDebug('Variable value: $value', tag: 'DataService');
  /// ```
  static Future<void> logDebug(
    dynamic message, {
    String? tag,
    StackTrace? stackTrace,
    bool? reportToCrashService,
  }) async {
    await log(
      message: message,
      level: LogLevel.debug,
      tag: tag,
      stackTrace: stackTrace,
      reportToCrashService: reportToCrashService,
    );
  }

  /// Logs an informational message.
  ///
  /// Convenience method for info-level logging.
  ///
  /// Example:
  /// ```
  /// GhostLogger.logInfo('User logged in successfully', tag: 'Auth');
  /// ```
  static Future<void> logInfo(
    dynamic message, {
    String? tag,
    StackTrace? stackTrace,
    bool? reportToCrashService,
  }) async {
    await log(
      message: message,
      level: LogLevel.info,
      tag: tag,
      stackTrace: stackTrace,
      reportToCrashService: reportToCrashService,
    );
  }

  /// Logs a warning message.
  ///
  /// Convenience method for warning-level logging.
  ///
  /// Example:
  /// ```
  /// GhostLogger.logWarning('API endpoint deprecated', tag: 'Network');
  /// ```
  static Future<void> logWarning(
    dynamic message, {
    String? tag,
    StackTrace? stackTrace,
    bool? reportToCrashService,
  }) async {
    await log(
      message: message,
      level: LogLevel.warning,
      tag: tag,
      stackTrace: stackTrace,
      reportToCrashService: reportToCrashService,
    );
  }

  /// Logs an error message.
  ///
  /// Convenience method for error-level logging.
  ///
  /// Example:
  /// ```
  /// GhostLogger.logError(
  ///   'Network request failed',
  ///   tag: 'API',
  ///   stackTrace: StackTrace.current,
  /// );
  /// ```
  static Future<void> logError(
    dynamic message, {
    String? tag,
    StackTrace? stackTrace,
    bool? reportToCrashService,
  }) async {
    await log(
      message: message,
      level: LogLevel.error,
      tag: tag,
      stackTrace: stackTrace,
      reportToCrashService: reportToCrashService,
    );
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
        _writeToPrint(message, level, stackTrace);
        break;

      case LoggerType.console:
        _writeToDeveloperLog(message, level, stackTrace);
        break;
    }
  }

  /// Writes to print() with optional color support.
  static void _writeToPrint(
    String message,
    LogLevel level,
    StackTrace? stackTrace,
  ) {
    if (_withColors) {
      String color;
      switch (level) {
        case LogLevel.debug:
          color = AnsiColors.gray;
          break;
        case LogLevel.info:
          color = AnsiColors.cyan;
          break;
        case LogLevel.warning:
          color = AnsiColors.yellow;
          break;
        case LogLevel.error:
          color = AnsiColors.red;
          break;
      }

      // Emit reset before to ensure clean state
      // ignore: avoid_print
      print(AnsiColors.reset);

      // Print colored message
      // ignore: avoid_print
      print('$color[GhostLogger] $message');

      // Emit reset after in separate call
      // ignore: avoid_print
      print(AnsiColors.reset);

      if (stackTrace != null) {
        // ignore: avoid_print
        print(AnsiColors.reset);
        // ignore: avoid_print
        print('$color$stackTrace');
        // ignore: avoid_print
        print(AnsiColors.reset);
      }
    } else {
      // ignore: avoid_print
      print('[GhostLogger] $message');
      if (stackTrace != null) {
        // ignore: avoid_print
        print(stackTrace);
      }
    }
  }

  /// Writes to developer.log() without colors for IDE compatibility.
  static void _writeToDeveloperLog(
    String message,
    LogLevel level,
    StackTrace? stackTrace,
  ) {
    developer.log(
      message,
      level: level.numericLevel,
      name: 'GhostLogger',
      time: DateTime.now(),
      stackTrace: stackTrace,
    );
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
