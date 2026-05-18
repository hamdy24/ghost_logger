import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Manages log file creation, writing, and cleanup for GhostLogger.
///
/// Handles per-session, per-level log files stored in the application
/// support directory. Not supported on Flutter Web.
class LogFileManager {
  LogFileManager._();

  static const String _filePrefix = 'ghost_logger';
  static const String _fileExtension = '.log';
  static const String _noTag = 'NO-TAG';

  /// Formats a log line with timestamp, level, tag, and message.
  ///
  /// Format: `2026-05-18T07:30:00.000 | WARNING | [Tag] | message`
  /// If no tag is provided, `NO-TAG` is used as placeholder.
  static String formatLine({
    required String level,
    required String? tag,
    required String message,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final tagLabel = tag ?? _noTag;
    return '$timestamp | ${level.toUpperCase().padRight(7)} | $tagLabel | $message\n';
  }

  /// Returns the log file for a given level and session timestamp,
  /// creating it if it does not yet exist.
  static Future<File> resolveFile({
    required String level,
    required String sessionTimestamp,
  }) async {
    final dir = await getApplicationSupportDirectory();
    final filename = '${_filePrefix}_${level}_$sessionTimestamp$_fileExtension';
    final file = File('${dir.path}/$filename');
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    return file;
  }

  /// Appends a formatted log line to the given file.
  static Future<void> writeLine(File file, String line) async {
    await file.writeAsString(line, mode: FileMode.append);
  }

  /// Deletes ghost_logger_*.log files from the application support directory.
  ///
  /// If [includeRecents] is true, all matching files are deleted regardless of age.
  /// Otherwise, only files older than [retentionDays] days are deleted.
  static Future<void> deleteOldFiles(
    int retentionDays, {
    bool includeRecents = false,
  }) async {
    final dir = await getApplicationSupportDirectory();
    final directory = Directory(dir.path);
    if (!await directory.exists()) return;

    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));

    await for (final entity in directory.list()) {
      if (entity is File) {
        final name = entity.uri.pathSegments.last;
        if (name.startsWith(_filePrefix) && name.endsWith(_fileExtension)) {
          if (includeRecents) {
            await entity.delete();
          } else {
            final modified = await entity.lastModified();
            if (modified.isBefore(cutoff)) {
              await entity.delete();
            }
          }
        }
      }
    }
  }

  /// Formats a DateTime into a filename-safe session timestamp string.
  ///
  /// Example output: `2026-05-18_07-30-00`
  static String formatSessionTimestamp(DateTime dt) {
    final date = '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)}';
    final time = '${_pad(dt.hour)}-${_pad(dt.minute)}-${_pad(dt.second)}';
    return '${date}_$time';
  }

  /// Returns all ghost_logger_*.log files currently on disk in the
  /// application support directory, sorted by last modified date descending
  /// (newest first).
  static Future<List<File>> listAllLogFiles() async {
    final dir = await getApplicationSupportDirectory();
    final directory = Directory(dir.path);
    if (!await directory.exists()) return [];

    final files = <File>[];
    await for (final entity in directory.list()) {
      if (entity is File) {
        final name = entity.uri.pathSegments.last;
        if (name.startsWith(_filePrefix) && name.endsWith(_fileExtension)) {
          files.add(entity);
        }
      }
    }

    // Sort newest first so the developer's iteration is chronologically useful
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    return files;
  }

  static String _pad(int value) => value.toString().padLeft(2, '0');
}
