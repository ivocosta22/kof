import 'package:flutter/material.dart';
import 'app_drawer.dart';

/// Wraps a screen with a "reveal" style drawer: the content slides
/// to the right and scales down, revealing the drawer behind it.
///
/// Access from anywhere inside the tree with [AppShell.of(context)].
class AppShell extends StatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static AppShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<AppShellState>();

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  bool get _isOpen => _ctrl.value > 0.5;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void open() => _ctrl.animateTo(1.0, curve: Curves.easeOutCubic);
  void close() => _ctrl.animateTo(0.0, curve: Curves.easeOutCubic);
  void toggle() => _isOpen ? close() : open();

  void _snap(DragEndDetails d) {
    if (_ctrl.value > 0.5 || d.velocity.pixelsPerSecond.dx > 200) {
      open();
    } else {
      close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth * 0.78;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Stack(
        children: [
          // ── Drawer sits permanently behind the content ───────────
          SizedBox(
            width: drawerWidth,
            child: AppDrawer(onClose: close),
          ),

          // ── Content with slide + scale + corner-radius animation ─
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              final t = _ctrl.value;
              return Transform.translate(
                offset: Offset(drawerWidth * t, 0),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.0 * t),
                    child: Stack(
                      children: [
                        child!,
                        // Scrim overlay — captures taps + swipes when open
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: t < 0.05,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: close,
                              onHorizontalDragUpdate: (d) {
                                _ctrl.value =
                                    (_ctrl.value + d.delta.dx / drawerWidth)
                                        .clamp(0.0, 1.0);
                              },
                              onHorizontalDragEnd: _snap,
                              child: ColoredBox(
                                color:
                                    Colors.black.withValues(alpha: 0.35 * t),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              );
            },
            // GestureDetector is the static child — not rebuilt each frame
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (d) {
                _ctrl.value =
                    (_ctrl.value + d.delta.dx / drawerWidth).clamp(0.0, 1.0);
              },
              onHorizontalDragEnd: _snap,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
