import 'package:flutter/material.dart';

/// The connected Google identity, with a neutral placeholder when no photo is
/// available or the image cannot be loaded.
class AccountAvatar extends StatelessWidget {
  const AccountAvatar({super.key, this.photoUrl, this.size = 36});

  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = photoUrl;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: ClipOval(
          child: url == null || url.isEmpty
              ? _placeholder(scheme)
              : Image.network(
                  url,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  frameBuilder: (context, child, frame, synchronousCall) =>
                      frame == null ? _placeholder(scheme) : child,
                  loadingBuilder: (context, child, progress) =>
                      progress == null ? child : _placeholder(scheme),
                  errorBuilder: (context, error, stackTrace) =>
                      _placeholder(scheme),
                ),
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme scheme) => ColoredBox(
    color: scheme.surfaceContainerHighest,
    child: Icon(
      Icons.account_circle_outlined,
      size: size,
      color: scheme.onSurfaceVariant,
    ),
  );
}
