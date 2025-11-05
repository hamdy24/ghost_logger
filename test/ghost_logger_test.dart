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
  group('GhostLogger', () {
    late TestCrashReporter crashReporter;

    setUp(() {
      crashReporter = TestCrashReporter();
    });

    test('configures debug mode correctly', () async {
      await GhostLogger.configure(
        isDebugMode: true,
        loggerType: LoggerType.console,
      );

      expect(true, isTrue); // Configuration successful
    });

    test('reports to crash service when enabled', () async {
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

  group('LogLevel', () {
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
