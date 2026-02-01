import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class NetworkVideoPlayer extends StatefulWidget {
  const NetworkVideoPlayer({
    super.key,
    required this.url,
    this.borderRadius,
    this.backgroundColor,
    this.fallbackIcon = Icons.videocam_off_outlined,
    this.iconSize = 40,
    this.fallbackAspectRatio = 16 / 9,
  });

  final String url;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final IconData fallbackIcon;
  final double iconSize;
  final double fallbackAspectRatio;

  @override
  State<NetworkVideoPlayer> createState() => _NetworkVideoPlayerState();
}

class _NetworkVideoPlayerState extends State<NetworkVideoPlayer> {
  late final VideoPlayerController _controller;
  final ValueNotifier<bool> _isMuted = ValueNotifier(false);
  bool _initialized = false;
  bool _hasError = false;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..setLooping(true);
    _controller.setVolume(0);
    _isMuted.value = true;
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      if (!mounted) return;
      setState(() => _initialized = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _isMuted.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    if (!_initialized) return;
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    setState(() {});
  }

  void _toggleMute() {
    final nextMuted = !_isMuted.value;
    _controller.setVolume(nextMuted ? 0 : 1);
    _isMuted.value = nextMuted;
  }

  Future<void> _openFullscreen() async {
    if (!_initialized) return;
    _isFullscreen = true;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    try {
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (context) {
            return _FullscreenVideoPlayer(
              controller: _controller,
              mutedListenable: _isMuted,
              onToggleMute: _toggleMute,
            );
          },
        ),
      );
    } finally {
      _isFullscreen = false;
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    if (mounted) {
      setState(() {});
    }
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

  Widget _buildVideo(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        final size = value.size;
        return Stack(
          children: [
            Positioned.fill(
              child: size.width == 0 || size.height == 0
                  ? _buildFallback(context)
                  : FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: size.width,
                        height: size.height,
                        child: VideoPlayer(_controller),
                      ),
                    ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _togglePlayback,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: value.isPlaying ? 0.0 : 0.9,
                      duration: const Duration(milliseconds: 180),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: _TimelineBar(controller: _controller),
            ),
            Positioned(
              right: 12,
              bottom: 44,
              child: Row(
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: _isMuted,
                    builder: (context, muted, _) {
                      return _ControlButton(
                        icon: muted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up,
                        onPressed: _toggleMute,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _ControlButton(
                    icon: Icons.fullscreen_rounded,
                    onPressed: _openFullscreen,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final aspectRatio = _initialized
        ? (_controller.value.aspectRatio == 0
              ? widget.fallbackAspectRatio
              : _controller.value.aspectRatio)
        : widget.fallbackAspectRatio;
    final child = _hasError
        ? _buildFallback(context)
        : _initialized
        ? _buildVideo(context)
        : Stack(
            children: [
              _buildFallback(context),
              const Center(child: CircularProgressIndicator()),
            ],
          );

    final clipped = widget.borderRadius == null
        ? child
        : ClipRRect(borderRadius: widget.borderRadius!, child: child);

    return VisibilityDetector(
      key: ValueKey('video-${widget.url}'),
      onVisibilityChanged: (info) {
        if (!_initialized || _hasError || _isFullscreen) return;
        final visibleFraction = info.visibleFraction;
        if (visibleFraction >= 0.6 && !_controller.value.isPlaying) {
          _controller.play();
        } else if (visibleFraction < 0.2 && _controller.value.isPlaying) {
          _controller.pause();
        }
      },
      child: AspectRatio(aspectRatio: aspectRatio, child: clipped),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.55),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _TimelineBar extends StatelessWidget {
  const _TimelineBar({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: ColoredBox(
        color: Colors.black.withOpacity(0.35),
        child: VideoProgressIndicator(
          controller,
          allowScrubbing: true,
          colors: const VideoProgressColors(
            playedColor: Colors.white,
            bufferedColor: Colors.white38,
            backgroundColor: Colors.white24,
          ),
        ),
      ),
    );
  }
}

class _FullscreenVideoPlayer extends StatelessWidget {
  const _FullscreenVideoPlayer({
    required this.controller,
    required this.mutedListenable,
    required this.onToggleMute,
  });

  final VideoPlayerController controller;
  final ValueListenable<bool> mutedListenable;
  final VoidCallback onToggleMute;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final size = value.size;
                if (size.width == 0 || size.height == 0) {
                  return const CircularProgressIndicator();
                }
                return FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: VideoPlayer(controller),
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (controller.value.isPlaying) {
                    controller.pause();
                  } else {
                    controller.play();
                  }
                },
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  left: 12,
                  child: Material(
                    color: Colors.black.withOpacity(0.55),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: _TimelineBar(controller: controller),
                ),
                Positioned(
                  right: 16,
                  bottom: 52,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: mutedListenable,
                    builder: (context, muted, _) {
                      return Row(
                        children: [
                          _ControlButton(
                            icon: muted
                                ? Icons.volume_off_rounded
                                : Icons.volume_up,
                            onPressed: onToggleMute,
                          ),
                          const SizedBox(width: 8),
                          _ControlButton(
                            icon: Icons.fullscreen_exit_rounded,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
