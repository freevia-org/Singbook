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
    this.hideHandle = false,
    this.sideHeader,
    this.sideWidth,
    this.collapsedAction,
    required this.lyrics,
    required this.controls,
  });

  final bool expanded;
  final bool hideHandle;
  final ValueChanged<bool> onChanged;
  final String expandLabel;
  final String collapseLabel;
  final bool side;
  final Widget? sideHeader;
  final double? sideWidth;
  final Widget? collapsedAction;
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
    final dragSign =
        widget.side && Directionality.of(context) == TextDirection.rtl
        ? 1.0
        : -1.0;
    void startDrag() {
      _reveal.stop();
      _dragging = true;
      _dragCanceled = false;
      _distance = 0;
    }

    void updateDrag(double delta) {
      _distance += delta;
      final box = _controlsKey.currentContext?.findRenderObject();
      final extent = box is RenderBox && box.hasSize
          ? (widget.side ? box.size.width : box.size.height)
          : 180.0;
      _reveal.value =
          (_reveal.value +
                  (widget.side ? delta * dragSign : -delta) /
                      extent.clamp(80, 400))
              .clamp(0.0, 1.0);
    }

    void endDrag(double velocity) {
      _dragging = false;
      if (_dragCanceled) return;
      final signedVelocity = widget.side ? velocity * dragSign : -velocity;
      final signedDistance = widget.side ? _distance * dragSign : -_distance;
      final expanded = signedVelocity.abs() > 300
          ? signedVelocity > 0
          : _distance.abs() >= 12
          ? signedDistance > 0
          : _reveal.value >= .5;
      _choose(expanded);
    }

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
            onVerticalDragStart: widget.side ? null : (_) => startDrag(),
            onVerticalDragUpdate: widget.side
                ? null
                : (details) => updateDrag(details.delta.dy),
            onVerticalDragCancel: widget.side
                ? null
                : () {
                    _dragging = false;
                    _settle(widget.expanded);
                  },
            onVerticalDragEnd: widget.side
                ? null
                : (details) => endDrag(details.primaryVelocity ?? 0),
            onHorizontalDragStart: widget.side ? (_) => startDrag() : null,
            onHorizontalDragUpdate: widget.side
                ? (details) => updateDrag(details.delta.dx)
                : null,
            onHorizontalDragCancel: widget.side
                ? () {
                    _dragging = false;
                    _settle(widget.expanded);
                  }
                : null,
            onHorizontalDragEnd: widget.side
                ? (details) => endDrag(details.primaryVelocity ?? 0)
                : null,
            child: InkWell(
              onTap: () => _choose(!widget.expanded),
              child: widget.side
                  ? SizedBox(
                      width: 48,
                      height: 96,
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Container(
                          key: const ValueKey('player-controls-grip'),
                          width: 12,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerLow,
                            borderRadius:
                                const BorderRadiusDirectional.horizontal(
                                  end: Radius.circular(8),
                                ),
                          ),
                          child: Container(
                            width: 3,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.outline,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    )
                  : SizedBox(
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
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerLow,
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
      child: widget.side
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: widget.lyrics),
                      if (!widget.hideHandle)
                        PositionedDirectional(
                          top: 0,
                          bottom: 0,
                          end: 0,
                          child: Center(child: handle),
                        ),
                      if (!widget.expanded && widget.collapsedAction != null)
                        PositionedDirectional(
                          top: 8,
                          end: 8,
                          child: Material(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerLow,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: widget.collapsedAction!,
                          ),
                        ),
                    ],
                  ),
                ),
                _animatedControls(),
              ],
            )
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: widget.lyrics),
                      if (!widget.expanded && widget.collapsedAction != null)
                        PositionedDirectional(
                          top: 8,
                          end: 8,
                          child: Material(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerLow,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: widget.collapsedAction!,
                          ),
                        ),
                      if (!widget.hideHandle)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Center(child: handle),
                        ),
                    ],
                  ),
                ),
                _animatedControls(),
              ],
            ),
    );
  }

  Widget _animatedControls() => AnimatedBuilder(
    animation: _reveal,
    builder: (context, child) => SizeTransition(
      sizeFactor: _reveal,
      axis: widget.side ? Axis.horizontal : Axis.vertical,
      alignment: widget.side
          ? Directionality.of(context) == TextDirection.rtl
                ? Alignment.centerRight
                : Alignment.centerLeft
          : Alignment.topCenter,
      child: ExcludeFocus(
        excluding: _reveal.value == 0,
        child: Offstage(offstage: _reveal.value == 0, child: child),
      ),
    ),
    child: KeyedSubtree(
      key: _controlsKey,
      child: widget.side && widget.sideHeader != null
          ? SizedBox(
              width: widget.sideWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  widget.sideHeader!,
                  Expanded(child: widget.controls),
                ],
              ),
            )
          : widget.controls,
    ),
  );
}
