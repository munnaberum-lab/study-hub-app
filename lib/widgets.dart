import 'package:flutter/material.dart';

import 'models.dart';
import 'watch.dart';

class Thumb extends StatelessWidget {
  final String url;
  final BoxFit fit;
  const Thumb(this.url, {super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (c, child, p) => p == null ? child : Container(color: Colors.black12),
      errorBuilder: (c, e, s) => Container(
        color: Colors.black12,
        child: const Center(child: Icon(Icons.play_circle_outline, size: 36, color: Colors.black38)),
      ),
    );
  }
}

/// Lambi video ki row (thumbnail left, text right).
class VideoTile extends StatelessWidget {
  final Video v;
  const VideoTile(this.v, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WatchScreen(video: v))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 150,
            height: 88,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(fit: StackFit.expand, children: [
                Thumb(v.thumb),
                if (v.dur > 0)
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: _badge(fmtDur(v.dur)),
                  ),
                if (v.locked || v.premium)
                  const Positioned(left: 4, top: 4, child: Icon(Icons.lock, size: 18, color: Colors.amber)),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.titleSmall),
              const SizedBox(height: 4),
              Text('${fmtCount(v.views)} views${v.quality != null ? ' • ${v.quality}' : ''}',
                  style: t.bodySmall),
            ]),
          ),
        ]),
      ),
    );
  }
}

Widget _badge(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
    );

class ErrorBox extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const ErrorBox(this.error, this.onRetry, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text('$error', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      ),
    );
  }
}

class EmptyBox extends StatelessWidget {
  final String text;
  const EmptyBox(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.video_library_outlined, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
          ]),
        ),
      );
}

/// Infinite-scroll list of videos. [loader] page number leta hai (1 se).
class VideoListView extends StatefulWidget {
  final Future<PageData> Function(int page) loader;
  final Widget? header;
  final String emptyText;
  const VideoListView({super.key, required this.loader, this.header, this.emptyText = 'Abhi koi video nahi hai.'});

  @override
  State<VideoListView> createState() => _VideoListViewState();
}

class _VideoListViewState extends State<VideoListView> {
  final _sc = ScrollController();
  final List<Video> _items = [];
  int _page = 0;
  bool _more = true, _loading = false;
  Object? _err;

  @override
  void initState() {
    super.initState();
    _sc.addListener(() {
      if (_sc.position.pixels > _sc.position.maxScrollExtent - 400) _next();
    });
    _next();
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    _items.clear();
    _page = 0;
    _more = true;
    _err = null;
    await _next();
  }

  Future<void> _next() async {
    if (_loading || !_more) return;
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final d = await widget.loader(_page + 1);
      if (!mounted) return;
      setState(() {
        _page++;
        _items.addAll(d.items);
        _more = d.hasMore;
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
    if (_items.isEmpty && _err != null) return ErrorBox(_err!, _reset);
    if (_items.isEmpty && !_loading) {
      return ListView(children: [if (widget.header != null) widget.header!, EmptyBox(widget.emptyText)]);
    }
    return RefreshIndicator(
      onRefresh: _reset,
      child: ListView.builder(
        controller: _sc,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length + 2,
        itemBuilder: (c, i) {
          if (i == 0) return widget.header ?? const SizedBox(height: 6);
          if (i == _items.length + 1) {
            if (_loading) {
              return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
            }
            if (_err != null) return ErrorBox(_err!, _next);
            return const SizedBox(height: 24);
          }
          return VideoTile(_items[i - 1]);
        },
      ),
    );
  }
}

