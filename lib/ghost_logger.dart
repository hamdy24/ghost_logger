/// Ghost Logger - Stealing errors before they steal your users' experience.
///
/// Ghost Logger provides centralized logging with multiple output mechanisms,
/// optional crash reporting integration, and clean emoji-based visual indicators.
///
/// Works invisibly in the background, logging to terminal and automatically
/// reporting to crash services without your interference.
///
/// ## Quick Start
///
/// ```
/// import 'package:ghost_logger/ghost_logger.dart';
///
/// void main() async {
///   await GhostLogger.configure(
///     isDebugMode: true,
///     loggerType: LoggerType.console,
///   );
///
///   GhostLogger.log(
///     message: 'App started',
///     level: LogLevel.info,
///     tag: 'Main',
///   );
/// }
/// ```
library;

export 'src/crash_reporter.dart';
export 'src/ghost_logger.dart';
export 'src/log_level.dart';
export 'src/logger_type.dart';
