import 'package:flutter/material.dart';

class NetworkImageFallback extends StatelessWidget {
  const NetworkImageFallback({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.backgroundColor,
    this.fallbackIcon = Icons.image_not_supported_outlined,
    this.iconSize = 40,
  });

  final String url;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final IconData fallbackIcon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fallbackColor = backgroundColor ?? theme.colorScheme.surfaceVariant;
    final image = Image.network(
      url,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        color: fallbackColor,
        child: Center(
          child: Icon(
            fallbackIcon,
            size: iconSize,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );

    if (borderRadius == null) return image;

    return ClipRRect(
      borderRadius: borderRadius!,
      child: image,
    );
  }
}
