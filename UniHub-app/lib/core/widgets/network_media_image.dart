import 'package:flutter/material.dart';

class NetworkMediaImage extends StatefulWidget {
  const NetworkMediaImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.backgroundColor,
    this.fallbackIcon = Icons.image_not_supported_outlined,
    this.iconSize = 40,
    this.fallbackAspectRatio = 16 / 9,
  });

  final String url;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final IconData fallbackIcon;
  final double iconSize;
  final double fallbackAspectRatio;

  @override
  State<NetworkMediaImage> createState() => _NetworkMediaImageState();
}

class _NetworkMediaImageState extends State<NetworkMediaImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  double? _aspectRatio;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant NetworkMediaImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _removeListener();
      _aspectRatio = null;
      _hasError = false;
      _resolveImage();
    }
  }

  void _resolveImage() {
    final image = NetworkImage(widget.url);
    final stream = image.resolve(ImageConfiguration.empty);
    _listener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        setState(() {
          _aspectRatio = info.image.width / info.image.height;
        });
      },
      onError: (_, __) {
        if (!mounted) return;
        setState(() => _hasError = true);
      },
    );
    stream.addListener(_listener!);
    _stream = stream;
  }

  void _removeListener() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
  }

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  Widget _buildFallback(BuildContext context) {
    final theme = Theme.of(context);
    final fallbackColor =
        widget.backgroundColor ?? theme.colorScheme.surfaceVariant;
    return Container(
      color: fallbackColor,
      alignment: Alignment.center,
      child: Icon(
        widget.fallbackIcon,
        size: widget.iconSize,
        color: theme.colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aspectRatio = _aspectRatio ?? widget.fallbackAspectRatio;
    final content = _hasError
        ? _buildFallback(context)
        : Image.network(
            widget.url,
            fit: widget.fit,
            errorBuilder: (_, __, ___) => _buildFallback(context),
          );

    final child = AspectRatio(
      aspectRatio: aspectRatio,
      child: widget.borderRadius == null
          ? content
          : ClipRRect(borderRadius: widget.borderRadius!, child: content),
    );

    return child;
  }
}
