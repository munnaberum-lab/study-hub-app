import 'package:flutter/material.dart';

import 'api.dart';
import 'models.dart';
import 'shorts.dart';
import 'videos.dart';
import 'widgets.dart';

class _HomeData {
  final ShortsData shorts;
  final PageData latest, popular;
  final List<String> tags;
  _HomeData(this.shorts, this.latest, this.popular, this.tags);
}

class HomeScreen extends StatefulWidget {
  final VoidCallback onSeeShorts, onSeeVideos;
  const HomeScreen({super.key, required this.onSeeShorts, required this.onSeeVideos});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeData> _f = _load();

  Future<_HomeData> _load() async {
    final r = await Future.wait<Object>([
      Api.shorts(limit: 10),
      Api.videos(kind: 'long', limit: 10),
      Api.videos(kind: 'long', sort: 'views', limit: 8),
      Api.tags(),
    ]);
    return _HomeData(r[0] as ShortsData, r[1] as PageData, r[2] as PageData, r[3] as List<String>);
  }

  void _reload() => setState(() => _f = _load());

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(gradient: kGradient, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 10),
        ShaderMask(
          shaderCallback: (r) => kGradient.createShader(r),
          child: const Text(kAppName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.search_rounded, size: 28),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
        ),
      ]),
    );
  }

  Widget _hero(BuildContext context, Video v) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: GestureDetector(
        onTap: () => openVideo(context, v),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(fit: StackFit.expand, children: [
              PosterImage(v.thumb),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xEE000000)],
                    stops: [0.3, 1],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(gradient: kGradient, borderRadius: BorderRadius.circular(8)),
                    child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 8),
                  Text(v.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2)),
                  const SizedBox(height: 10),
                  Row(children: [
                    FilledButton.icon(
                      onPressed: () => openVideo(context, v),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Play'),
                    ),
                    const SizedBox(width: 12),
                    Text(metaOf(v), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _shortCard(BuildContext context, List<Video> all, int i) {
    final v = all[i];
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShortsScreen(initial: all.sublist(i)))),
      child: Container(
        width: 128,
        margin: const EdgeInsets.only(right: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(fit: StackFit.expand, children: [
            PosterImage(v.thumb),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                  stops: [0.5, 1],
                ),
              ),
            ),
            const Positioned(top: 8, right: 8, child: Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 22)),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(v.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${fmtCount(v.views)} views', style: const TextStyle(color: Colors.white60, fontSize: 10)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<_HomeData>(
        future: _f,
        builder: (c, s) {
          if (s.connectionState != ConnectionState.done) {
            return Column(children: [
              _header(context),
              const Expanded(
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 14),
                    Text('Load ho raha hai...', style: TextStyle(color: Colors.white60)),
                    SizedBox(height: 4),
                    Text('(pehli baar 30-40 second lag sakte hain)', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ]),
                ),
              ),
            ]);
          }
          if (s.hasError) return Column(children: [_header(context), Expanded(child: ErrorBox(s.error!, _reload))]);
          final d = s.data!;
          if (d.shorts.items.isEmpty && d.latest.items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(children: [
                _header(context),
                const SizedBox(height: 100),
                const EmptyBox('Abhi koi video nahi hai.\nApne Telegram channel mein files daalo, wo yahan aa jayengi.'),
              ]),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(children: [
              _header(context),
              if (d.latest.items.isNotEmpty) _hero(context, d.latest.items.first),
              if (d.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        for (final tg in d.tags)
                          TagChip(tg, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TagScreen(tag: tg)))),
                      ],
                    ),
                  ),
                ),
              if (d.shorts.items.isNotEmpty) ...[
                SectionTitle('Shorts', onMore: widget.onSeeShorts),
                SizedBox(
                  height: 214,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: d.shorts.items.length,
                    itemBuilder: (c, i) => _shortCard(context, d.shorts.items, i),
                  ),
                ),
              ],
              if (d.latest.items.length > 1) ...[
                SectionTitle('Latest videos', onMore: widget.onSeeVideos),
                for (final v in d.latest.items.skip(1)) VideoCard(v),
              ],
              if (d.popular.items.isNotEmpty) ...[
                const SectionTitle('Popular'),
                SizedBox(
                  height: 170,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: d.popular.items.length,
                    itemBuilder: (c, i) => MiniCard(d.popular.items[i]),
                  ),
                ),
              ],
              const SizedBox(height: 28),
            ]),
          );
        },
      ),
    );
  }
}
