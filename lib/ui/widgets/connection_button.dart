import 'package:flutter/material.dart';
import '../../core/engine/v2ray_engine.dart';
import '../theme/app_theme.dart';

/// Animated pulsing connection button styled after NetMod.
class ConnectionButton extends StatefulWidget {
  final EngineState state;
  final VoidCallback onTap;

  const ConnectionButton({
    super.key,
    required this.state,
    required this.onTap,
  });

  @override
  State<ConnectionButton> createState() => _ConnectionButtonState();
}

class _ConnectionButtonState extends State<ConnectionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant ConnectionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == EngineState.connecting ||
        widget.state == EngineState.connected) {
      if (!_animController.isAnimating) {
        _animController.repeat(reverse: true);
      }
    } else {
      _animController.stop();
      _animController.reset();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _getButtonColor() {
    switch (widget.state) {
      case EngineState.connected:
        return AppTheme.connectedGreen;
      case EngineState.connecting:
      case EngineState.disconnecting:
        return AppTheme.warningAmber;
      case EngineState.error:
        return AppTheme.errorRed;
      case EngineState.disconnected:
        return AppTheme.primaryCyan;
    }
  }

  IconData _getIcon() {
    switch (widget.state) {
      case EngineState.connected:
        return Icons.power_settings_new_rounded;
      case EngineState.connecting:
      case EngineState.disconnecting:
        return Icons.sync_rounded;
      case EngineState.error:
        return Icons.error_outline_rounded;
      case EngineState.disconnected:
        return Icons.power_settings_new_rounded;
    }
  }

  String _getStatusText() {
    switch (widget.state) {
      case EngineState.connected:
        return 'CONNECTED';
      case EngineState.connecting:
        return 'CONNECTING...';
      case EngineState.disconnecting:
        return 'STOPPING...';
      case EngineState.error:
        return 'CONNECTION ERROR';
      case EngineState.disconnected:
        return 'TAP TO CONNECT';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _getButtonColor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Transform.scale(
                scale: (widget.state == EngineState.connected ||
                        widget.state == EngineState.connecting)
                    ? _scaleAnimation.value
                    : 1.0,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: activeColor.withAlpha(25),
                    border: Border.all(
                      color: activeColor.withAlpha(80),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withAlpha(60),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            activeColor,
                            activeColor.withAlpha(200),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withAlpha(120),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getIcon(),
                        size: 52,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _getStatusText(),
          style: TextStyle(
            color: activeColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
