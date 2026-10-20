import 'package:flutter/material.dart';

/// Reveals the transport without replacing or remounting the lyrics viewport.
class PlayerControlsPanel extends StatefulWidget {
  const PlayerControlsPanel({
    super.key,
    required this.expanded,
    required this.onChanged,
    required this.expandLabel,
    required this.collapseLabel,
    required this.side,
    required this.lyrics,
    required this.controls,
  });

  final bool expanded;
  final ValueChanged<bool> onChanged;
  final String expandLabel;
  final String collapseLabel;
  final bool side;
  final Widget lyrics;
  final Widget controls;

  @override
  State<PlayerControlsPanel> createState() => _PlayerControlsPanelState();
}

class _PlayerControlsPanelState extends State<PlayerControlsPanel>
    with SingleTickerProviderStateMixin {
  late final _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: widget.expanded ? 1 : 0,
  );
  final _controlsKey = GlobalKey();
  bool _dragging = false;
  bool _dragCanceled = false;
  double _distance = 0;

  @override
  void didUpdateWidget(covariant PlayerControlsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded != widget.expanded && !_dragging) {
      _settle(widget.expanded);
    }
  }

  void _settle(bool expanded) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _reveal.value = expanded ? 1 : 0;
    } else {
      _reveal.animateTo(expanded ? 1 : 0, curve: Curves.easeOutCubic);
    }
  }

  void _choose(bool expanded) {
    _settle(expanded);
    if (expanded != widget.expanded) widget.onChanged(expanded);
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.expanded ? widget.collapseLabel : widget.expandLabel;
    final handle = Semantics(
      button: true,
      expanded: widget.expanded,
      label: label,
      child: Tooltip(
        message: label,
        child: Listener(
          onPointerCancel: (_) {
            _dragCanceled = true;
            _dragging = false;
            _settle(widget.expanded);
          },
          child: GestureDetector(
            key: const ValueKey('player-controls-handle'),
            behavior: HitTestBehavior.opaque,
            onVerticalDragStart: (_) {
              _reveal.stop();
              _dragging = true;
              _dragCanceled = false;
              _distance = 0;
            },
            onVerticalDragUpdate: (details) {
              _distance += details.delta.dy;
              final box = _controlsKey.currentContext?.findRenderObject();
              final extent = box is RenderBox && box.hasSize
                  ? (widget.side ? box.size.width : box.size.height)
                  : 180.0;
              _reveal.value =
                  (_reveal.value - details.delta.dy / extent.clamp(80, 400))
                      .clamp(0.0, 1.0);
            },
            onVerticalDragCancel: () {
              _dragging = false;
              _settle(widget.expanded);
            },
            onVerticalDragEnd: (details) {
              _dragging = false;
              if (_dragCanceled) return;
              final velocity = details.primaryVelocity ?? 0;
              final expanded = velocity.abs() > 300
                  ? velocity < 0
                  : _distance.abs() >= 12
                  ? _distance < 0
                  : _reveal.value >= .5;
              _choose(expanded);
            },
            child: InkWell(
              onTap: () => _choose(!widget.expanded),
              child: SizedBox(
                width: 96,
                height: 48,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    key: const ValueKey('player-controls-grip'),
                    width: 64,
                    height: 12,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                    child: Container(
                      width: 32,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return SafeArea(
      top: false,
      child: Flex(
        direction: widget.side ? Axis.horizontal : Axis.vertical,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: widget.lyrics),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(child: handle),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _reveal,
            builder: (context, child) => SizeTransition(
              sizeFactor: _reveal,
              axis: widget.side ? Axis.horizontal : Axis.vertical,
              alignment: widget.side
                  ? Alignment.centerLeft
                  : Alignment.topCenter,
              child: Offstage(offstage: _reveal.value == 0, child: child),
            ),
            child: KeyedSubtree(key: _controlsKey, child: widget.controls),
          ),
        ],
      ),
    );
  }
}
