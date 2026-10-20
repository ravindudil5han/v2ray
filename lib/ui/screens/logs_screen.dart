import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/log_service.dart';
import '../theme/app_theme.dart';

/// Live Log Terminal Screen.
class LogsScreen extends StatefulWidget {
  final LogService logService;

  const LogsScreen({super.key, required this.logService});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _filterController = TextEditingController();
  bool _autoScroll = true;

  @override
  void dispose() {
    _scrollController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  void _copyLogs() {
    final text = widget.logService.getAllLogsAsText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copied to clipboard')),
    );
  }

  void _scrollToBottom() {
    if (_autoScroll && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Color _getLogColor(String level) {
    switch (level) {
      case 'ERROR':
        return AppTheme.errorRed;
      case 'WARN':
        return AppTheme.warningAmber;
      case 'CORE':
        return AppTheme.primaryCyan;
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.logService,
      builder: (context, _) {
        final logs = widget.logService.logs;
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return Scaffold(
          appBar: AppBar(
            title: const Text('Live Core Logs'),
            actions: [
              IconButton(
                tooltip: _autoScroll ? 'Disable Auto-Scroll' : 'Enable Auto-Scroll',
                icon: Icon(
                  Icons.vertical_align_bottom_rounded,
                  color: _autoScroll ? AppTheme.primaryCyan : AppTheme.disconnectedGrey,
                ),
                onPressed: () => setState(() => _autoScroll = !_autoScroll),
              ),
              IconButton(
                tooltip: 'Copy All Logs',
                icon: const Icon(Icons.copy_rounded, color: Colors.white),
                onPressed: _copyLogs,
              ),
              IconButton(
                tooltip: 'Clear Logs',
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorRed),
                onPressed: () => widget.logService.clear(),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _filterController,
                  onChanged: (val) => widget.logService.setFilter(val),
                  decoration: InputDecoration(
                    hintText: 'Filter logs (e.g. error, routing, core)...',
                    prefixIcon: const Icon(Icons.filter_list_rounded,
                        color: AppTheme.disconnectedGrey),
                    suffixIcon: _filterController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _filterController.clear();
                              widget.logService.setFilter('');
                            },
                          )
                        : null,
                  ),
                ),
              ),

              // Terminal View
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF080C12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: logs.isEmpty
                      ? const Center(
                          child: Text(
                            'No logs yet. Start the connection to view core output.',
                            style: TextStyle(
                              color: AppTheme.disconnectedGrey,
                              fontFamily: 'monospace',
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: logs.length,
                          itemBuilder: (ctx, index) {
                            final log = logs[index];
                            final color = _getLogColor(log.level);

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '[${log.formattedTime}] ',
                                      style: const TextStyle(
                                        color: AppTheme.disconnectedGrey,
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '${log.message}\n',
                                      style: TextStyle(
                                        color: color,
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
