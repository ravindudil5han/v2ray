import 'package:flutter/foundation.dart';
import '../models/v2ray_log.dart';

/// Service for accumulating and filtering live engine logs.
class LogService extends ChangeNotifier {
  static const int maxLogs = 1000;
  final List<V2RayLog> _logs = [];
  String _filter = '';

  List<V2RayLog> get logs {
    if (_filter.isEmpty) return List.unmodifiable(_logs);
    final query = _filter.toLowerCase();
    return _logs
        .where((l) =>
            l.message.toLowerCase().contains(query) ||
            l.level.toLowerCase().contains(query))
        .toList();
  }

  void addLog(String message) {
    final entry = V2RayLog.fromString(message);
    _logs.add(entry);
    if (_logs.length > maxLogs) {
      _logs.removeRange(0, _logs.length - maxLogs);
    }
    notifyListeners();
  }

  void setFilter(String query) {
    _filter = query;
    notifyListeners();
  }

  void clear() {
    _logs.clear();
    notifyListeners();
  }

  String getAllLogsAsText() {
    return _logs.map((l) => '[${l.formattedTime}] [${l.level}] ${l.message}').join('\n');
  }
}
