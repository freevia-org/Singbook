import 'package:flutter/foundation.dart';

/// Whether the app runs on a desktop operating system, where keyboard
/// shortcuts, hover tooltips and pointer-sized controls apply.
bool get isDesktopPlatform => switch (defaultTargetPlatform) {
  TargetPlatform.windows || TargetPlatform.macOS || TargetPlatform.linux => true,
  _ => false,
};
