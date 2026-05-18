import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'log_export_scope.dart';
import 'log_file_manager.dart';

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
  static int? _maxMessageLength;
  static const int _chunkSize = 1000;
  // --- file logging fields ---
  static bool _storeWarnings = false;
  static bool _storeErrors = false;
  static bool _storeInfo = false;
  static bool _storeDebug = false;
  static int _logRetentionDays = 7;
  static bool _autoCleanOldLogs = true;
  static bool _isWritingToFile = false;
  static void Function(File logFile, LogLevel level)? _onLogFileUpdated;

  // Lazily populated on first write per level within a session
  static File? _warningFile;
  static File? _errorFile;
  static File? _infoFile;
  static File? _debugFile;

  // Captured once at configure() time, shared across all level filenames
  static String? _sessionTimestamp;

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
  /// [maxMessageLength] optional maximum character length for printed messages.
  /// If set, messages exceeding this length are truncated and marked with
  /// "... [truncated]". Does not apply to stack traces. Defaults to null
  /// (full message is always printed).
  /// [storeWarnings] whether to write warning logs to a local file (default: false).
  /// [storeErrors] whether to write error logs to a local file (default: false).
  /// [storeInfo] whether to write info logs to a local file (default: false).
  /// [storeDebug] whether to write debug logs to a local file (default: false).
  /// [logRetentionDays] number of days before old log files are deleted (default: 7).
  /// [autoCleanOldLogs] whether to automatically clean old logs on startup (default: true).
  /// [onLogFileUpdated] optional callback invoked each time a log line is written
  /// to a file, receiving the updated [File] and its [LogLevel].
  /// File logging is not supported on Flutter Web.
  static Future<void> configure({
    bool isDebugMode = kDebugMode,
    LoggerType loggerType = LoggerType.print,
    CrashReporter? crashReporter,
    bool withColors = true,
    bool enableCrashReporting = false,
    int? maxMessageLength,
    bool storeWarnings = false,
    bool storeErrors = false,
    bool storeInfo = false,
    bool storeDebug = false,
    int logRetentionDays = 7,
    bool autoCleanOldLogs = true,
    void Function(File logFile, LogLevel level)? onLogFileUpdated,
  }) async {
    _isDebugMode = isDebugMode;
    _loggerType = loggerType;
    _reportToCrashlytics = enableCrashReporting;
    _withColors = withColors;
    _maxMessageLength = maxMessageLength;
    _storeWarnings = storeWarnings;
    _storeErrors = storeErrors;
    _storeInfo = storeInfo;
    _storeDebug = storeDebug;
    _logRetentionDays = logRetentionDays;
    _autoCleanOldLogs = autoCleanOldLogs;
    _onLogFileUpdated = onLogFileUpdated;

    // Reset session file references for this new session
    _warningFile = null;
    _errorFile = null;
    _infoFile = null;
    _debugFile = null;
    _isWritingToFile = false;

    // Capture session timestamp once — used for all log filenames this session
    _sessionTimestamp = LogFileManager.formatSessionTimestamp(DateTime.now());

    if (crashReporter != null) {
      _crashReporter = crashReporter;
      await _crashReporter.setCollectionEnabled(enableCrashReporting);
    }

    // Auto-cleanup runs at startup if enabled and any file logging is active
    final anyFileLoggingEnabled =
        storeWarnings || storeErrors || storeInfo || storeDebug;
    if (autoCleanOldLogs && anyFileLoggingEnabled) {
      await cleanOldLogs();
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

    // File output — NOT gated by debug mode, works in release builds
    await _writeToFile(message: message.toString(), level: level, tag: tag);

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

  /// Returns all log files written in the current session, or null if no
  /// file logging is active or no logs have been written yet.
  ///
  /// Also triggers [onLogFileUpdated] for each file if configured, allowing
  /// the developer to handle export (upload, share, display) in one call.
  ///
  /// Returns null when no files are available — handle this with null safety.
  static Future<List<File>?> exportLogs({
    LogExportScope scope = LogExportScope.currentSession,
  }) async {
    if (kIsWeb) {
      debugPrint('GhostLogger: file logging is not supported on Flutter Web.');
      return null;
    }

    List<File> files;

    if (scope == LogExportScope.currentSession) {
      // Only files created/opened this session
      files = [
        _debugFile,
        _infoFile,
        _warningFile,
        _errorFile,
      ].whereType<File>().toList();
    } else {
      // Scan disk for ALL ghost_logger_*.log files
      files = await LogFileManager.listAllLogFiles();
    }

    if (files.isEmpty) return null;

    if (_onLogFileUpdated != null) {
      final levelMap = {
        _debugFile: LogLevel.debug,
        _infoFile: LogLevel.info,
        _warningFile: LogLevel.warning,
        _errorFile: LogLevel.error,
      };
      for (final file in files) {
        // For allSessions, level is inferred from filename; current session uses map
        final level = levelMap[file] ?? _inferLevelFromFilename(file);
        if (level != null) _onLogFileUpdated!(file, level);
      }
    }

    return files;
  }

  /// Deletes GhostLogger log files from the application support directory.
  ///
  /// By default, only files older than [logRetentionDays] are removed.
  /// Set [includeRecents] to true to delete all log files regardless of age,
  /// including files within the retention window.
  ///
  /// Called automatically on startup when [autoCleanOldLogs] is true,
  /// which always uses the default behavior (retention-based cleanup only).
  /// Can also be called manually — for example after the user taps a
  /// "Clear Logs" action in your app.
  static Future<void> cleanOldLogs({bool includeRecents = false}) async {
    if (kIsWeb) return;
    await LogFileManager.deleteOldFiles(
      _logRetentionDays,
      includeRecents: includeRecents,
    );
  }

  /// Formats the log message with emoji, level, and optional tag.
  static String _formatMessage(dynamic message, LogLevel level, String? tag) {
    final tagPrefix = tag != null ? '[$tag] ' : '';
    final levelName = level.name.toUpperCase();
    return '${level.emoji} $levelName: $tagPrefix$message';
  }

  /// Writes log to console based on configured logger type.
  ///
  /// If [maxMessageLength] is configured, the message is truncated to that
  /// length before being passed to the active logger. Stack traces are
  /// always passed in full regardless of this setting.
  static void _writeToConsole(
    String message,
    LogLevel level,
    StackTrace? stackTrace,
  ) {
    // Apply maxMessageLength — affects both print and console logger types
    final String effectiveMessage;
    if (_maxMessageLength != null && message.length > _maxMessageLength!) {
      effectiveMessage =
          '${message.substring(0, _maxMessageLength!)}... [truncated]';
    } else {
      effectiveMessage = message;
    }

    switch (_loggerType) {
      case LoggerType.print:
        _writeToPrint(effectiveMessage, level, stackTrace);
        break;

      case LoggerType.console:
        _writeToDeveloperLog(effectiveMessage, level, stackTrace);
        break;
    }
  }

  /// Writes to print() with optional color support.
  ///
  /// Long messages are split into [_chunkSize]-character chunks to prevent
  /// output clipping. If [GhostLogger] was configured with a [maxMessageLength],
  /// messages are truncated to that length before chunking and marked with
  /// "... [truncated]". Stack traces are always printed in full.
  static void _writeToPrint(
    String message,
    LogLevel level,
    StackTrace? stackTrace,
  ) {
    final messageChunks = _splitIntoChunks(message);

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

      // Single reset before the entire message
      // ignore: avoid_print
      print(AnsiColors.reset);

      // First chunk carries the [GhostLogger] prefix
      // ignore: avoid_print
      print('$color[GhostLogger] ${messageChunks.first}');

      // Remaining chunks are raw — color re-applied each time for terminal safety
      for (var i = 1; i < messageChunks.length; i++) {
        // ignore: avoid_print
        print('$color${messageChunks[i]}');
      }

      // Single reset after the entire message
      // ignore: avoid_print
      print(AnsiColors.reset);

      // Stack trace — always full, same reset-once + chunk pattern
      if (stackTrace != null) {
        final stackChunks = _splitIntoChunks(stackTrace.toString());
        // ignore: avoid_print
        print(AnsiColors.reset);
        // ignore: avoid_print
        print('$color${stackChunks.first}');
        for (var i = 1; i < stackChunks.length; i++) {
          // ignore: avoid_print
          print('$color${stackChunks[i]}');
        }
        // ignore: avoid_print
        print(AnsiColors.reset);
      }
    } else {
      // No-color path — same chunking logic, no ANSI codes

      // First chunk carries the [GhostLogger] prefix
      // ignore: avoid_print
      print('[GhostLogger] ${messageChunks.first}');

      // Remaining chunks are raw
      for (var i = 1; i < messageChunks.length; i++) {
        // ignore: avoid_print
        print(messageChunks[i]);
      }

      // Stack trace — always full
      if (stackTrace != null) {
        final stackChunks = _splitIntoChunks(stackTrace.toString());
        for (final chunk in stackChunks) {
          // ignore: avoid_print
          print(chunk);
        }
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

  /// Splits [text] into chunks of at most [_chunkSize] characters.
  ///
  /// Used internally to work around print() output clipping on long strings.
  static List<String> _splitIntoChunks(String text) {
    final chunks = <String>[];
    var start = 0;
    while (start < text.length) {
      final end = (start + _chunkSize).clamp(0, text.length);
      chunks.add(text.substring(start, end));
      start = end;
    }
    return chunks;
  }

  /// Writes a log entry to the level's local file if file logging is enabled
  /// for that level.
  ///
  /// Does nothing on Flutter Web — a debug warning is emitted instead.
  /// File writing is not gated by [_isDebugMode] and runs in release builds.
  static Future<void> _writeToFile({
    required String message,
    required LogLevel level,
    required String? tag,
  }) async {
    if (kIsWeb) {
      // ignore: avoid_print
      debugPrint('GhostLogger: file logging is not supported on Flutter Web.');
      return;
    }
    // Guard against re-entrant calls — prevents infinite loops when the
    // onLogFileUpdated callback itself calls GhostLogger.log*()
    if (_isWritingToFile) return;

    final shouldStore = switch (level) {
      LogLevel.debug => _storeDebug,
      LogLevel.info => _storeInfo,
      LogLevel.warning => _storeWarnings,
      LogLevel.error => _storeErrors,
    };

    if (!shouldStore || _sessionTimestamp == null) return;

    _isWritingToFile = true;
    // Resolve the file lazily — created on first write for this level/session
    try {
      final file = await _resolveFileForLevel(level);

      final line = LogFileManager.formatLine(
        level: level.name,
        tag: tag,
        message: message,
      );

      await LogFileManager.writeLine(file, line);

      _onLogFileUpdated?.call(file, level);
    } finally {
      _isWritingToFile = false;
    }
  }

  /// Returns the cached file for [level], creating it if this is the first
  /// write for this level in the current session.
  static Future<File> _resolveFileForLevel(LogLevel level) async {
    switch (level) {
      case LogLevel.debug:
        _debugFile ??= await LogFileManager.resolveFile(
          level: level.name,
          sessionTimestamp: _sessionTimestamp!,
        );
        return _debugFile!;
      case LogLevel.info:
        _infoFile ??= await LogFileManager.resolveFile(
          level: level.name,
          sessionTimestamp: _sessionTimestamp!,
        );
        return _infoFile!;
      case LogLevel.warning:
        _warningFile ??= await LogFileManager.resolveFile(
          level: level.name,
          sessionTimestamp: _sessionTimestamp!,
        );
        return _warningFile!;
      case LogLevel.error:
        _errorFile ??= await LogFileManager.resolveFile(
          level: level.name,
          sessionTimestamp: _sessionTimestamp!,
        );
        return _errorFile!;
    }
  }

  static LogLevel? _inferLevelFromFilename(File file) {
    final name = file.uri.pathSegments.last;
    if (name.contains('_debug_')) return LogLevel.debug;
    if (name.contains('_info_')) return LogLevel.info;
    if (name.contains('_warning_')) return LogLevel.warning;
    if (name.contains('_error_')) return LogLevel.error;
    return null;
  }
}
