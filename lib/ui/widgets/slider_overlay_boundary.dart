import 'package:flutter/material.dart';

/// Keeps a slider's overlay semantics connected on Windows pushed routes.
///
/// Flutter 3.44's Slider uses an OverlayPortal that can serialize orphan nodes
/// into the Windows accessibility tree (flutter/flutter#190357). A local overlay
/// retains the Material slider's semantics, value indicator and input handling.
class SliderOverlayBoundary extends StatelessWidget {
  const SliderOverlayBoundary({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform != TargetPlatform.windows) return child;
    // Slider has no text baseline. Avoid querying the overlay's deferred
    // children for a baseline when this boundary is a ListTile subtitle.
    return IgnoreBaseline(
      child: Overlay.wrap(
        alwaysSizeToContent: true,
        clipBehavior: Clip.none,
        child: child,
      ),
    );
  }
}

/// Puts the overlay above PopupMenuItem's MergeSemantics, rather than inside it.
/// A slider portal inside that merge can otherwise still serialize orphan nodes.
class SliderPopupMenuItem<T> extends PopupMenuItem<T> {
  const SliderPopupMenuItem({
    super.key,
    super.enabled,
    super.padding,
    required super.child,
  });

  @override
  PopupMenuItemState<T, SliderPopupMenuItem<T>> createState() =>
      _SliderPopupMenuItemState<T>();
}

class _SliderPopupMenuItemState<T>
    extends PopupMenuItemState<T, SliderPopupMenuItem<T>> {
  @override
  Widget build(BuildContext context) =>
      SliderOverlayBoundary(child: super.build(context));
}
