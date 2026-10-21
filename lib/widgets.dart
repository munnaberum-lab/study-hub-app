import 'package:flutter/material.dart';

import 'models.dart';
import 'watch.dart';

const Color kAccent = Color(0xFF9C6BFF);
const LinearGradient kGradient = LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFFE040A0)]);

void openVideo(BuildContext context, Video v) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => WatchScreen(video: v)));
}

String metaOf(Video v) {
  final p = <String>['${fmtCount(v.views)} views'];
  if (v.quality != null && v.quality!.isNotEmpty) p.add(v.quality!);
  return p.join(' • ');
}

/// Thumbnail: pehle gradient placeholder, phir image fade-in hoti hai.
class PosterImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  const PosterImage(this.url, {super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1B2E), Color(0xFF2A1F3D)],
          ),
        ),
        child: const Center(child: Icon(Icons.play_circle_outline, size: 34, color: Colors.white24)),
      ),
      if (url.isNotEmpty)
        Image.network(
          url,
          fit: fit,
          frameBuilder: (c, child, frame, sync) => sync
              ? child
              : AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 350),
                  child: child,
                ),
          errorBuilder: (c, e, s) => const SizedBox.shrink(),
        ),
    ]);
  }
}

Widget _durBadge(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
    );

Widget _qualityBadge(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(gradient: kGradient, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
    );

const BoxDecoration _bottomFade = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0x99000000)],
    stops: [0.55, 1],
  ),
);

/// Badi card (16:9 thumbnail upar, title neeche).
class VideoCard extends StatelessWidget {
  final Video v;
  const VideoCard(this.v, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: GestureDetector(
        onTap: () => openVideo(context, v),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(fit: StackFit.expand, children: [
                PosterImage(v.thumb),
                const DecoratedBox(decoration: _bottomFade),
                if (v.dur > 0) Positioned(right: 10, bottom: 10, child: _durBadge(fmtDur(v.dur))),
                if (v.quality != null && v.quality!.isNotEmpty)
                  Positioned(left: 10, top: 10, child: _qualityBadge(v.quality!)),
                if (v.locked || v.premium)
                  const Positioned(right: 10, top: 10, child: Icon(Icons.lock, size: 20, color: Colors.amber)),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(metaOf(v), style: t.bodySmall?.copyWith(color: Colors.white60)),
        ]),
      ),
    );
  }
}

/// Chhota carousel card.
class MiniCard extends StatelessWidget {
  final Video v;
  final double width;
  const MiniCard(this.v, {super.key, this.width = 230});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () => openVideo(context, v),
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(fit: StackFit.expand, children: [
                PosterImage(v.thumb),
                const DecoratedBox(decoration: _bottomFade),
                if (v.dur > 0) Positioned(right: 6, bottom: 6, child: _durBadge(fmtDur(v.dur))),
              ]),
            ),
          ),
          const SizedBox(height: 6),
          Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          Text(metaOf(v), style: t.bodySmall?.copyWith(color: Colors.white60)),
        ]),
      ),
    );
  }
}

/// Compact row (search, liked, suggestions ke liye).
class VideoTile extends StatelessWidget {
  final Video v;
  const VideoTile(this.v, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => openVideo(context, v),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 150,
            height: 86,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(fit: StackFit.expand, children: [
                PosterImage(v.thumb),
                if (v.dur > 0) Positioned(right: 5, bottom: 5, child: _durBadge(fmtDur(v.dur))),
                if (v.locked || v.premium)
                  const Positioned(left: 5, top: 5, child: Icon(Icons.lock, size: 16, color: Colors.amber)),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(v.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(metaOf(v), style: t.bodySmall?.copyWith(color: Colors.white60)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final VoidCallback? onMore;
  const SectionTitle(this.text, {super.key, this.onMore});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 8, 6),
      child: Row(children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(gradient: kGradient, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const Spacer(),
        if (onMore != null) TextButton(onPressed: onMore, child: const Text('Sab dekho')),
      ]),
    );
  }
}

class TagChip extends StatelessWidget {
  final String tag;
  final VoidCallback onTap;
  const TagChip(this.tag, {super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1B26),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Text('#$tag', style: const TextStyle(fontSize: 13, color: Colors.white70)),
      ),
    );
  }
}

class ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const ActionPill({super.key, required this.icon, required this.label, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color(0x339C6BFF) : const Color(0xFF1C1B26),
      shape: StadiumBorder(side: BorderSide(color: active ? kAccent : Colors.white12)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 20, color: active ? kAccent : Colors.white70),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? kAccent : Colors.white70)),
            ],
          ]),
        ),
      ),
    );
  }
}

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
          const Icon(Icons.cloud_off, size: 52, color: Colors.white38),
          const SizedBox(height: 14),
          Text('$error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
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
            const Icon(Icons.video_library_outlined, size: 60, color: Colors.white24),
            const SizedBox(height: 14),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60)),
          ]),
        ),
      );
}

/// Infinite-scroll list of videos. [loader] page number leta hai (1 se).
class VideoListView extends StatefulWidget {
  final Future<PageData> Function(int page) loader;
  final Widget? header;
  final String emptyText;
  final bool cards;
  const VideoListView({
    super.key,
    required this.loader,
    this.header,
    this.emptyText = 'Abhi koi video nahi hai.',
    this.cards = false,
  });

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
      if (_sc.position.pixels > _sc.position.maxScrollExtent - 500) _next();
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
    if (_items.isEmpty && _loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) {
      return ListView(children: [if (widget.header != null) widget.header!, const SizedBox(height: 60), EmptyBox(widget.emptyText)]);
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
          final v = _items[i - 1];
          return widget.cards ? VideoCard(v) : VideoTile(v);
        },
      ),
    );
  }
}
