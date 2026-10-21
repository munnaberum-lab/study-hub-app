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
      Api.videos(kind: 'long', sort: 'views', limit: 6),
      Api.tags(),
    ]);
    return _HomeData(r[0] as ShortsData, r[1] as PageData, r[2] as PageData, r[3] as List<String>);
  }

  void _reload() => setState(() => _f = _load());

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: FutureBuilder<_HomeData>(
        future: _f,
        builder: (c, s) {
          if (s.connectionState != ConnectionState.done) {
            return const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Load ho raha hai...'),
              ]),
            );
          }
          if (s.hasError) return ErrorBox(s.error!, _reload);
          final d = s.data!;
          if (d.shorts.items.isEmpty && d.latest.items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(children: const [
                SizedBox(height: 120),
                EmptyBox('Abhi koi video nahi hai.\nApne Telegram channel mein files daalo, wo yahan aa jayengi.'),
              ]),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(children: [
                  Text(kAppName, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                  ),
                ]),
              ),
              if (d.tags.isNotEmpty)
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      for (final tg in d.tags)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text('#$tg'),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TagScreen(tag: tg)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              if (d.shorts.items.isNotEmpty) ...[
                _sectionTitle(context, 'Shorts', widget.onSeeShorts),
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: d.shorts.items.length,
                    itemBuilder: (c, i) {
                      final v = d.shorts.items[i];
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ShortsScreen(initial: d.shorts.items.sublist(i)),
                          ),
                        ),
                        child: Container(
                          width: 124,
                          margin: const EdgeInsets.only(right: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(fit: StackFit.expand, children: [
                              PosterImage(v.thumb),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  color: Colors.black54,
                                  child: Text(v.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontSize: 11)),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (d.latest.items.isNotEmpty) ...[
                _sectionTitle(context, 'Latest videos', widget.onSeeVideos),
                for (final v in d.latest.items) VideoTile(v),
              ],
              if (d.popular.items.isNotEmpty) ...[
                _sectionTitle(context, 'Popular', null),
                for (final v in d.popular.items) VideoTile(v),
              ],
              const SizedBox(height: 24),
            ]),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text, VoidCallback? onMore) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 4, 6),
        child: Row(children: [
          Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          if (onMore != null) TextButton(onPressed: onMore, child: const Text('Sab dekho')),
        ]),
      );
}
