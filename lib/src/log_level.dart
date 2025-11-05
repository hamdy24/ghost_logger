/// Represents the severity level of a log message.
///
/// Used to categorize and filter log output based on importance.
enum LogLevel {
  /// Development and troubleshooting information.
  debug,

  /// General informational messages about app operation.
  info,

  /// Warnings about potential issues that don't prevent execution.
  warning,

  /// Error conditions that require attention.
  error,
}

/// Extension providing utilities for [LogLevel] enumeration.
///
/// Adds emoji representation and numeric level conversion methods
/// to log levels for enhanced logging capabilities.
extension LogLevelExtension on LogLevel {
  /// Returns the emoji representation for this log level.
  String get emoji {
    switch (this) {
      case LogLevel.debug:
        return '⚒️';
      case LogLevel.info:
        return '👉';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }

  /// Returns the numeric level compatible with dart:developer log.
  ///
  /// Values correspond to Dart's logging levels.
  int get numericLevel {
    switch (this) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 1000;
      case LogLevel.error:
        return 2000;
    }
  }
}
