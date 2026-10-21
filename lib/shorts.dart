import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'api.dart';
import 'models.dart';
import 'widgets.dart';

bool _shortsMuted = false; // mute ka setting saari shorts pe lagta hai

/// Reels jaisa vertical feed. [initial] diya ho to wahin se shuru hota hai.
class ShortsScreen extends StatefulWidget {
  final bool active;
  final List<Video>? initial;
  const ShortsScreen({super.key, this.active = true, this.initial});
  @override
  State<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends State<ShortsScreen> {
  final PageController _pc = PageController();
  final List<Video> _items = [];
  String? _next;
  bool _more = true, _loading = false;
  int _page = 0;
  Object? _err;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null && widget.initial!.isNotEmpty) {
      _items.addAll(widget.initial!);
      _next = _items.last.id;
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading || !_more) return;
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final d = await Api.shorts(after: _next);
      if (!mounted) return;
      setState(() {
        _items.addAll(d.items);
        _next = d.next;
        _more = d.next != null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final standalone = widget.initial != null;
    Widget body;
    if (_items.isEmpty && _loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_items.isEmpty) {
      body = _err != null ? ErrorBox(_err!, _load) : const EmptyBox('Abhi koi short nahi hai.');
    } else {
      body = PageView.builder(
        controller: _pc,
        scrollDirection: Axis.vertical,
        itemCount: _items.length,
        onPageChanged: (i) {
          setState(() => _page = i);
          if (i >= _items.length - 3) _load();
        },
        itemBuilder: (c, i) => ShortPage(
          key: ValueKey(_items[i].id),
          video: _items[i],
          current: widget.active && i == _page,
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Positioned.fill(child: body),
        if (!standalone)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: const Text('Shorts',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, shadows: [Shadow(blurRadius: 8)])),
          ),
        if (standalone)
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            left: 4,
            child: IconButton(
              color: Colors.white,
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
      ]),
    );
  }
}

class ShortPage extends StatefulWidget {
  final Video video;
  final bool current;
  const ShortPage({super.key, required this.video, required this.current});
  @override
  State<ShortPage> createState() => _ShortPageState();
}

class _ShortPageState extends State<ShortPage> {
  VideoPlayerController? _c;
  String? _error;
  late Video v = widget.video;
  bool _counted = false;
  bool _heart = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final url = await Api.playUrl(v.id);
      final c = VideoPlayerController.networkUrl(Uri.parse(url));
      await c.initialize();
      c.setLooping(true);
      c.setVolume(_shortsMuted ? 0 : 1);
      if (!mounted) {
        c.dispose();
        return;
      }
      c.addListener(() {
        if (mounted) setState(() {});
      });
      setState(() => _c = c);
      _sync();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Video load nahi hui.');
    }
  }

  void _sync() {
    final c = _c;
    if (c == null) return;
    if (widget.current) {
      c.play();
      if (!_counted) {
        _counted = true;
        Api.addView(v.id);
      }
    } else {
      c.pause();
    }
  }

  @override
  void didUpdateWidget(ShortPage old) {
    super.didUpdateWidget(old);
    if (old.current != widget.current) _sync();
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _like({bool onlyAdd = false}) async {
    if (!Api.loggedIn) return _snack('Like ke liye Library tab mein login karo.');
    if (onlyAdd && v.liked) return;
    try {
      final want = !v.liked;
      final n = await Api.like(v.id, want);
      if (mounted) setState(() => v = v.withLike(want, n));
    } catch (e) {
      _snack('$e');
    }
  }

  void _doubleTapLike() {
    setState(() => _heart = true);
    _like(onlyAdd: true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _heart = false);
    });
  }

  Widget _rail(IconData icon, String label, VoidCallback onTap, {Color color = Colors.white}) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
        child: IconButton(onPressed: onTap, iconSize: 28, icon: Icon(icon, color: color)),
      ),
      if (label.isNotEmpty) Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    Widget video;
    if (c != null) {
      final size = c.value.size;
      final portrait = size.width > 0 && size.height > size.width;
      video = portrait
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(width: size.width, height: size.height, child: VideoPlayer(c)),
              ),
            )
          : Center(child: AspectRatio(aspectRatio: c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio, child: VideoPlayer(c)));
    } else if (_error != null) {
      video = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
        ),
      );
    } else {
      video = Stack(fit: StackFit.expand, children: [
        PosterImage(v.thumb),
        const Center(child: CircularProgressIndicator(color: Colors.white)),
      ]);
    }

    return GestureDetector(
      onTap: () {
        if (c == null) return;
        c.value.isPlaying ? c.pause() : c.play();
      },
      onDoubleTap: _doubleTapLike,
      child: Stack(fit: StackFit.expand, children: [
        Container(color: Colors.black),
        video,
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x99000000), Colors.transparent, Colors.transparent, Color(0xCC000000)],
                stops: [0, 0.18, 0.6, 1],
              ),
            ),
          ),
        ),
        if (c != null && !c.value.isPlaying && !c.value.isBuffering)
          const IgnorePointer(child: Center(child: Icon(Icons.play_arrow_rounded, size: 90, color: Colors.white60))),
        if (c != null && c.value.isBuffering && c.value.isPlaying)
          const IgnorePointer(child: Center(child: CircularProgressIndicator(color: Colors.white))),
        IgnorePointer(
          child: Center(
            child: AnimatedScale(
              scale: _heart ? 1.0 : 0.3,
              duration: const Duration(milliseconds: 250),
              child: AnimatedOpacity(
                opacity: _heart ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.favorite, size: 110, color: Colors.redAccent),
              ),
            ),
          ),
        ),
        Positioned(
          right: 10,
          bottom: 70,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _rail(v.liked ? Icons.favorite : Icons.favorite_border, fmtCount(v.likes), _like,
                color: v.liked ? Colors.redAccent : Colors.white),
            const SizedBox(height: 14),
            _rail(_shortsMuted ? Icons.volume_off : Icons.volume_up, '', () {
              _shortsMuted = !_shortsMuted;
              c?.setVolume(_shortsMuted ? 0 : 1);
              setState(() {});
            }),
          ]),
        ),
        Positioned(
          left: 16,
          right: 84,
          bottom: 26,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(v.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, shadows: [Shadow(blurRadius: 6)])),
            const SizedBox(height: 4),
            Text(
              [
                '${fmtCount(v.views)} views',
                if (v.tags.isNotEmpty) v.tags.take(3).map((e) => '#$e').join(' '),
              ].join('  •  '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ]),
        ),
        if (c != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VideoProgressIndicator(
              c,
              allowScrubbing: true,
              padding: EdgeInsets.zero,
              colors: const VideoProgressColors(
                playedColor: Color(0xFF9C6BFF),
                bufferedColor: Colors.white30,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
      ]),
    );
  }
}
