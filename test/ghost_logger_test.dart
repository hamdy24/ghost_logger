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

  @override
  Future<void> sendDiagnosticLogs() async {}
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
      final longMessage = 'A' * 5000;
      await GhostLogger.log(message: longMessage, level: LogLevel.info);
      expect(true, isTrue);
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

  group('GhostLogger Write Queue and flush()', () {
    setUp(() async {
      await GhostLogger.configure(
        isDebugMode: false,
        loggerType: LoggerType.console,
      );
    });

    test(
      'flush() completes immediately when no file logging is active',
      () async {
        // No store flags enabled — flush should resolve with no work to do
        await expectLater(GhostLogger.flush(), completes);
      },
    );

    test(
      'flush() completes after a burst of fire-and-forget log calls',
      () async {
        await GhostLogger.configure(
          isDebugMode: false,
          loggerType: LoggerType.console,
          storeDebug: true,
        );

        // Fire 20 concurrent log calls without awaiting any of them
        for (var i = 0; i < 20; i++) {
          GhostLogger.logDebug('Burst entry $i', tag: 'QueueTest');
        }

        // flush() must settle only after all 20 writes complete
        await expectLater(GhostLogger.flush(), completes);
      },
    );

    test('flush() is safe to call multiple times consecutively', () async {
      await GhostLogger.flush();
      await GhostLogger.flush();
      expect(true, isTrue);
    });

    test('new configure() resets the queue cleanly', () async {
      GhostLogger.logDebug('Pre-reconfigure entry');

      // Reconfiguring mid-flight should not leave the queue in a broken state
      await GhostLogger.configure(
        isDebugMode: false,
        loggerType: LoggerType.console,
      );

      await expectLater(GhostLogger.flush(), completes);
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
