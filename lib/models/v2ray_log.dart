import 'package:intl/intl.dart';

/// Single log entry for the live terminal display.
class V2RayLog {
  final DateTime timestamp;
  final String level;
  final String message;

  V2RayLog({
    DateTime? timestamp,
    required this.level,
    required this.message,
  }) : timestamp = timestamp ?? DateTime.now();

  String get formattedTime => DateFormat('HH:mm:ss.SSS').format(timestamp);

  factory V2RayLog.fromString(String raw) {
    String level = 'INFO';
    if (raw.contains('ERROR') || raw.contains('Err') || raw.contains('failed')) {
      level = 'ERROR';
    } else if (raw.contains('WARN') || raw.contains('warning')) {
      level = 'WARN';
    } else if (raw.startsWith('[Core]')) {
      level = 'CORE';
    }

    return V2RayLog(
      level: level,
      message: raw,
    );
  }
}
