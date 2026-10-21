import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'api.dart';
import 'models.dart';
import 'widgets.dart';

class WatchScreen extends StatefulWidget {
  final Video video;
  const WatchScreen({super.key, required this.video});
  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  late Video v = widget.video;
  VideoPlayerController? _vc;
  ChewieController? _cc;
  String? _error;
  bool _needLogin = false;
  List<Video> _more = [];

  @override
  void initState() {
    super.initState();
    _start();
    Api.suggest(v.id).then((l) {
      if (mounted) setState(() => _more = l);
    }).catchError((_) {});
  }

  Future<void> _start() async {
    setState(() {
      _error = null;
      _needLogin = false;
    });
    if (!v.playable) {
      setState(() => _error = 'Ye video app ke player mein nahi chal sakti (format support nahi).');
      return;
    }
    try {
      final url = await Api.playUrl(v.id);
      final vc = VideoPlayerController.networkUrl(Uri.parse(url));
      await vc.initialize();
      if (!mounted) {
        vc.dispose();
        return;
      }
      _vc = vc;
      _cc = ChewieController(
        videoPlayerController: vc,
        autoPlay: true,
        aspectRatio: vc.value.aspectRatio == 0 ? 16 / 9 : vc.value.aspectRatio,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: true,
      );
      setState(() {});
      Api.addView(v.id);
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _needLogin = e.code == 'login';
      });
    } catch (_) {
      setState(() => _error = 'Video load nahi ho payi. Dobara try karo.');
    }
  }

  @override
  void dispose() {
    _cc?.dispose();
    _vc?.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (!Api.loggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Like karne ke liye Library tab mein login karo.')));
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

  Future<void> _playlistSheet() async {
    if (!Api.loggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Playlist ke liye Library tab mein login karo.')));
      return;
    }
    await showModalBottomSheet(
      context: context,
      builder: (_) => _PlaylistSheet(videoId: v.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: ListView(children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.black,
            child: _cc != null
                ? Chewie(controller: _cc!)
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 10),
                            if (_needLogin)
                              const Text('Library tab mein login karo.', style: TextStyle(color: Colors.white70))
                            else if (v.telegram.isNotEmpty)
                              OutlinedButton(
                                onPressed: () => launchUrl(Uri.parse(v.telegram), mode: LaunchMode.externalApplication),
                                child: const Text('Telegram mein kholo'),
                              )
                            else
                              OutlinedButton(onPressed: _start, child: const Text('Retry')),
                          ]),
                        ),
                      )
                    : Stack(fit: StackFit.expand, children: [
                        PosterImage(v.thumb),
                        const Center(child: CircularProgressIndicator()),
                      ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(v.title, style: t.titleMedium),
            const SizedBox(height: 4),
            Text('${fmtCount(v.views)} views', style: t.bodySmall),
            const SizedBox(height: 8),
            Row(children: [
              FilledButton.tonalIcon(
                onPressed: _toggleLike,
                icon: Icon(v.liked ? Icons.favorite : Icons.favorite_border),
                label: Text(fmtCount(v.likes)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _playlistSheet,
                icon: const Icon(Icons.playlist_add),
                label: const Text('Playlist'),
              ),
            ]),
            if (v.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 6, children: [for (final tg in v.tags.take(8)) Chip(label: Text('#$tg'))]),
            ],
          ]),
        ),
        if (_more.isNotEmpty) ...[
          const Padding(padding: EdgeInsets.fromLTRB(12, 8, 12, 4), child: Text('Aur videos', style: TextStyle(fontWeight: FontWeight.bold))),
          for (final m in _more) VideoTile(m),
        ],
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _PlaylistSheet extends StatefulWidget {
  final String videoId;
  const _PlaylistSheet({required this.videoId});
  @override
  State<_PlaylistSheet> createState() => _PlaylistSheetState();
}

class _PlaylistSheetState extends State<_PlaylistSheet> {
  List<Map<String, dynamic>>? _lists;
  final _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final l = await Api.playlists(video: widget.videoId);
      if (mounted) setState(() => _lists = l);
    } catch (e) {
      if (mounted) setState(() => _lists = []);
    }
  }

  void _msg(Object e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Playlist mein daalo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        if (_lists == null)
          const Center(child: CircularProgressIndicator())
        else
          for (final p in _lists!)
            ListTile(
              dense: true,
              leading: Icon(p['has'] == true ? Icons.check_circle : Icons.circle_outlined),
              title: Text('${p['name']}'),
              subtitle: Text('${p['count']} videos'),
              onTap: p['has'] == true
                  ? null
                  : () async {
                      try {
                        await Api.addToPlaylist('${p['id']}', widget.videoId);
                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        _msg(e);
                      }
                    },
            ),
        const Divider(),
        Row(children: [
          Expanded(child: TextField(controller: _name, decoration: const InputDecoration(hintText: 'Nayi playlist ka naam'))),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () async {
              try {
                await Api.createPlaylist(_name.text.trim(), video: widget.videoId);
                if (mounted) Navigator.pop(context);
              } catch (e) {
                _msg(e);
              }
            },
            child: const Text('Banao'),
          ),
        ]),
      ]),
    );
  }
}
