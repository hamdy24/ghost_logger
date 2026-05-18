/// Controls which log files are returned by [GhostLogger.exportLogs].
enum LogExportScope {
  /// Returns only the files written in the current app session.
  currentSession,

  /// Returns all log files found on disk, across all sessions,
  /// within the configured [logRetentionDays] window.
  allSessions,
}
