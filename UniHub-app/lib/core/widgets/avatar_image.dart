import 'package:flutter/material.dart';

import '../utils/formatters.dart';

class AvatarImage extends StatelessWidget {
  const AvatarImage({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 22,
    this.backgroundColor,
    this.textStyle,
  });

  final String name;
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = initialsFor(name);
    final bgColor = backgroundColor ?? theme.colorScheme.primaryContainer;
    final initialsStyle = textStyle ??
        theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        );

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: imageUrl == null || imageUrl!.isEmpty
            ? Center(child: Text(initials, style: initialsStyle))
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(initials, style: initialsStyle),
                ),
              ),
      ),
    );
  }
}
