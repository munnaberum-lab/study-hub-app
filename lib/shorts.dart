import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'api.dart';
import 'models.dart';

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
    Widget body;
    if (_items.isEmpty && _loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_items.isEmpty) {
      body = Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_err != null ? '$_err' : 'Abhi koi short nahi hai.', style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 12),
          FilledButton(onPressed: _load, child: const Text('Retry')),
        ]),
      );
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
    final standalone = widget.initial != null;
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: standalone
          ? AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white, elevation: 0)
          : null,
      body: body,
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
      if (!mounted) {
        c.dispose();
        return;
      }
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

  Future<void> _like() async {
    if (!Api.loggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Like ke liye Library tab mein login karo.')));
      return;
    }
    try {
      final want = !v.liked;
      final n = await Api.like(v.id, want);
      setState(() => v = v.withLike(want, n));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    return GestureDetector(
      onTap: () {
        if (c == null) return;
        setState(() => c.value.isPlaying ? c.pause() : c.play());
      },
      child: Stack(fit: StackFit.expand, children: [
        Container(color: Colors.black),
        if (c != null)
          Center(
            child: AspectRatio(
              aspectRatio: c.value.aspectRatio == 0 ? 9 / 16 : c.value.aspectRatio,
              child: VideoPlayer(c),
            ),
          )
        else if (_error != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
            ),
          )
        else
          const Center(child: CircularProgressIndicator()),
        if (c != null && !c.value.isPlaying)
          const Center(child: Icon(Icons.play_arrow, size: 80, color: Colors.white54)),
        Positioned(
          right: 12,
          bottom: 90,
          child: Column(children: [
            IconButton(
              onPressed: _like,
              iconSize: 34,
              icon: Icon(v.liked ? Icons.favorite : Icons.favorite_border, color: v.liked ? Colors.redAccent : Colors.white),
            ),
            Text(fmtCount(v.likes), style: const TextStyle(color: Colors.white)),
          ]),
        ),
        Positioned(
          left: 14,
          right: 80,
          bottom: 24,
          child: Text(
            v.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, shadows: [Shadow(blurRadius: 6)]),
          ),
        ),
        if (c != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VideoProgressIndicator(c, allowScrubbing: true, padding: EdgeInsets.zero),
          ),
      ]),
    );
  }
}
