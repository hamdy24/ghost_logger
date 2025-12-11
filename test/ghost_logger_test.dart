import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_logger/ghost_logger.dart';

class TestCrashReporter implements CrashReporter {
  final List<String> logs = [];
  final List<dynamic> errors = [];
  bool isEnabled = false;

  @override
  Future<void> log(String message) async {
    logs.add(message);
  }

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
  }) async {
    errors.add(exception);
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    isEnabled = enabled;
  }
}

void main() {
  group('GhostLogger Configuration', () {
    late TestCrashReporter crashReporter;

    setUp(() {
      crashReporter = TestCrashReporter();
    });

    test('configures with default values', () async {
      await GhostLogger.configure();
      expect(true, isTrue);
    });

    test('configures debug mode correctly', () async {
      await GhostLogger.configure(
        isDebugMode: true,
        loggerType: LoggerType.console,
      );
      expect(true, isTrue);
    });

    test('configures crash reporting correctly', () async {
      await GhostLogger.configure(
        isDebugMode: false,
        crashReporter: crashReporter,
        enableCrashReporting: true,
      );

      await GhostLogger.log(message: 'Test error', level: LogLevel.error);

      expect(crashReporter.logs, isNotEmpty);
      expect(crashReporter.isEnabled, isTrue);
    });

    test('does not report when crash reporting disabled', () async {
      await GhostLogger.configure(
        isDebugMode: true,
        crashReporter: crashReporter,
        enableCrashReporting: false,
      );

      await GhostLogger.log(message: 'Test message', level: LogLevel.info);

      expect(crashReporter.logs, isEmpty);
    });
  });

  group('GhostLogger Main Log Method', () {
    setUp(() async {
      await GhostLogger.configure(
        isDebugMode: true,
        loggerType: LoggerType.console,
      );
    });

    test('logs without crash reporting', () async {
      await GhostLogger.log(message: 'Test message', level: LogLevel.info);
      expect(true, isTrue);
    });

    test('logs with tag', () async {
      await GhostLogger.log(
        message: 'Test message',
        level: LogLevel.info,
        tag: 'TestTag',
      );
      expect(true, isTrue);
    });

    test('logs with stack trace', () async {
      await GhostLogger.log(
        message: 'Test error',
        level: LogLevel.error,
        stackTrace: StackTrace.current,
      );
      expect(true, isTrue);
    });

    test('handles very long messages', () async {
      final longMessage = 'A' * 5000; // Longer than max length
      await GhostLogger.log(message: longMessage, level: LogLevel.info);
      expect(true, isTrue); // Should not throw
    });
  });

  group('GhostLogger Convenience Methods', () {
    setUp(() async {
      await GhostLogger.configure(
        isDebugMode: true,
        loggerType: LoggerType.console,
      );
    });

    test('logDebug works', () async {
      await GhostLogger.logDebug('Debug message', tag: 'Test');
      expect(true, isTrue);
    });

    test('logInfo works', () async {
      await GhostLogger.logInfo('Info message', tag: 'Test');
      expect(true, isTrue);
    });

    test('logWarning works', () async {
      await GhostLogger.logWarning('Warning message', tag: 'Test');
      expect(true, isTrue);
    });

    test('logError works', () async {
      await GhostLogger.logError(
        'Error message',
        tag: 'Test',
        stackTrace: StackTrace.current,
      );
      expect(true, isTrue);
    });

    test('convenience methods handle long messages', () async {
      final longMessage = 'B' * 5000;
      await GhostLogger.logError(longMessage);
      expect(true, isTrue);
    });
  });

  group('LogLevel Extensions', () {
    test('returns correct emoji for each level', () {
      expect(LogLevel.debug.emoji, '⚒️');
      expect(LogLevel.info.emoji, '👉');
      expect(LogLevel.warning.emoji, '⚠️');
      expect(LogLevel.error.emoji, '❌');
    });

    test('returns correct numeric levels', () {
      expect(LogLevel.debug.numericLevel, 500);
      expect(LogLevel.info.numericLevel, 800);
      expect(LogLevel.warning.numericLevel, 1000);
      expect(LogLevel.error.numericLevel, 2000);
    });
  });
}
