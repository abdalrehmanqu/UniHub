import 'package:flutter/material.dart';

enum UniHubLogoVariant { horizontal, vertical }

class UniHubLogo extends StatelessWidget {
  const UniHubLogo({
    super.key,
    this.variant = UniHubLogoVariant.horizontal,
    this.height = 48,
    this.fit = BoxFit.contain,
    this.forceLight = false,
  });

  final UniHubLogoVariant variant;
  final double height;
  final BoxFit fit;
  final bool forceLight;

  static const _horizontalUrl =
      'https://omrwuqfyiyixnpvvrywi.supabase.co/storage/v1/object/public/branding/unihub_logo_horizontal_transparent.png';
  static const _verticalUrl =
      'https://omrwuqfyiyixnpvvrywi.supabase.co/storage/v1/object/public/branding/unihub_logo_vertical_transparent.png';
  static const _verticalLightUrl =
      'https://omrwuqfyiyixnpvvrywi.supabase.co/storage/v1/object/public/branding/unihub_logo_vertical_white_transparent.png';

  String get _url =>
      forceLight
          ? _verticalLightUrl
          : (variant == UniHubLogoVariant.horizontal ? _horizontalUrl : _verticalUrl);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'UniHub logo',
      child: Image.network(
        _url,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => Text(
          'UniHub',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
