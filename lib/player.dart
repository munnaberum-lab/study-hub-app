import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

String _fmt(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

/// Apna custom player: tap = controls, double-tap = +-10 sec, speed, buffering, fullscreen.
class PlayerView extends StatefulWidget {
  final VideoPlayerController controller;
  final String title;
  final bool fullscreen;
  final VoidCallback? onBack;
  const PlayerView({
    super.key,
    required this.controller,
    required this.title,
    this.fullscreen = false,
    this.onBack,
  });

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  bool _show = true;
  Timer? _hide, _flashTimer;
  Offset _tap = Offset.zero;
  String? _flash;
  bool _flashLeft = false;

  VideoPlayerController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.addListener(_onChange);
    _arm();
  }

  @override
  void dispose() {
    c.removeListener(_onChange);
    _hide?.cancel();
    _flashTimer?.cancel();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  void _arm() {
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 3), () {
      if (mounted && c.value.isPlaying) setState(() => _show = false);
    });
  }

  void _toggleShow() {
    setState(() => _show = !_show);
    if (_show) _arm();
  }

  void _playPause() {
    final v = c.value;
    if (v.duration > Duration.zero && v.position >= v.duration) {
      c.seekTo(Duration.zero);
      c.play();
    } else if (v.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
    _arm();
  }

  void _seekBy(int sec) {
    final v = c.value;
    var t = v.position + Duration(seconds: sec);
    if (t < Duration.zero) t = Duration.zero;
    if (t > v.duration) t = v.duration;
    c.seekTo(t);
    _arm();
  }

  void _doubleTap() {
    final w = context.size?.width ?? 0;
    final left = _tap.dx < w / 2;
    _seekBy(left ? -10 : 10);
    setState(() {
      _flash = left ? '-10 sec' : '+10 sec';
      _flashLeft = left;
    });
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _flash = null);
    });
  }

  void _fullscreen() {
    if (widget.fullscreen) {
      Navigator.pop(context);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FullscreenPlayer(controller: c, title: widget.title)),
      );
    }
  }

  Widget _roundBtn(IconData icon, double size, VoidCallback onTap) => IconButton(
        onPressed: onTap,
        iconSize: size,
        color: Colors.white,
        icon: Icon(icon),
      );

  @override
  Widget build(BuildContext context) {
    final v = c.value;
    final ar = v.aspectRatio <= 0 ? 16 / 9 : v.aspectRatio;
    final ended = v.duration > Duration.zero && v.position >= v.duration;
    final playing = v.isPlaying;

    return Container(
      color: Colors.black,
      child: Stack(fit: StackFit.expand, children: [
        Center(child: AspectRatio(aspectRatio: ar, child: VideoPlayer(c))),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _toggleShow,
            onDoubleTapDown: (d) => _tap = d.localPosition,
            onDoubleTap: _doubleTap,
          ),
        ),
        if (v.isBuffering && playing) const Center(child: CircularProgressIndicator(color: Colors.white)),
        if (_flash != null)
          Align(
            alignment: _flashLeft ? Alignment.centerLeft : Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: Text(_flash!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        IgnorePointer(
          ignoring: !_show,
          child: AnimatedOpacity(
            opacity: _show ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: Stack(fit: StackFit.expand, children: [
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xAA000000), Colors.transparent, Colors.transparent, Color(0xCC000000)],
                      stops: [0, 0.3, 0.6, 1],
                    ),
                  ),
                ),
              ),
              // upar: back, title, speed
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Row(children: [
                    if (widget.onBack != null)
                      IconButton(onPressed: widget.onBack, color: Colors.white, icon: const Icon(Icons.arrow_back))
                    else
                      const SizedBox(width: 12),
                    Expanded(
                      child: Text(widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                    PopupMenuButton<double>(
                      tooltip: 'Speed',
                      initialValue: v.playbackSpeed,
                      onSelected: (s) {
                        c.setPlaybackSpeed(s);
                        _arm();
                      },
                      itemBuilder: (_) => [
                        for (final s in const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
                          PopupMenuItem<double>(value: s, child: Text('${s}x')),
                      ],
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(14)),
                        child: Text('${v.playbackSpeed}x',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ]),
                ),
              ),
              // beech: -10, play/pause, +10
              Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _roundBtn(Icons.replay_10, 38, () => _seekBy(-10)),
                  const SizedBox(width: 20),
                  Container(
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x66000000)),
                    child: IconButton(
                      onPressed: _playPause,
                      iconSize: 52,
                      color: Colors.white,
                      icon: Icon(ended ? Icons.replay : (playing ? Icons.pause : Icons.play_arrow)),
                    ),
                  ),
                  const SizedBox(width: 20),
                  _roundBtn(Icons.forward_10, 38, () => _seekBy(10)),
                ]),
              ),
              // neeche: time, seek bar, fullscreen
              Positioned(
                left: 8,
                right: 4,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Row(children: [
                    Text(_fmt(v.position), style: const TextStyle(color: Colors.white, fontSize: 12)),
                    Expanded(
                      child: VideoProgressIndicator(
                        c,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                        colors: const VideoProgressColors(
                          playedColor: Color(0xFF9C6BFF),
                          bufferedColor: Colors.white38,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    ),
                    Text(_fmt(v.duration), style: const TextStyle(color: Colors.white, fontSize: 12)),
                    IconButton(
                      onPressed: _fullscreen,
                      color: Colors.white,
                      icon: Icon(widget.fullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class FullscreenPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final String title;
  const FullscreenPlayer({super.key, required this.controller, required this.title});
  @override
  State<FullscreenPlayer> createState() => _FullscreenPlayerState();
}

class _FullscreenPlayerState extends State<FullscreenPlayer> {
  @override
  void initState() {
    super.initState();
    final portrait = widget.controller.value.aspectRatio > 0 && widget.controller.value.aspectRatio < 1;
    SystemChrome.setPreferredOrientations(
      portrait ? [DeviceOrientation.portraitUp] : [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PlayerView(
        controller: widget.controller,
        title: widget.title,
        fullscreen: true,
        onBack: () => Navigator.pop(context),
      ),
    );
  }
}
