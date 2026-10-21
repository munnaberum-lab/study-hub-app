import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'api.dart';
import 'models.dart';
import 'player.dart';
import 'videos.dart';
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
      await vc.play();
      setState(() {});
      Api.addView(v.id);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _needLogin = e.code == 'login';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Video load nahi ho payi. Dobara try karo.');
    }
  }

  @override
  void dispose() {
    _vc?.dispose();
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _toggleLike() async {
    if (!Api.loggedIn) return _snack('Like karne ke liye Library tab mein login karo.');
    try {
      final want = !v.liked;
      final n = await Api.like(v.id, want);
      if (mounted) setState(() => v = v.withLike(want, n));
    } catch (e) {
      _snack('$e');
    }
  }

  Future<void> _playlistSheet() async {
    if (!Api.loggedIn) return _snack('Playlist ke liye Library tab mein login karo.');
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16151D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      isScrollControlled: true,
      builder: (_) => _PlaylistSheet(videoId: v.id),
    );
  }

  Widget _backButton() => Positioned(
        top: 6,
        left: 6,
        child: Container(
          decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
          child: IconButton(
            color: Colors.white,
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );

  Widget _playerArea() {
    final vc = _vc;
    if (vc != null) {
      return PlayerView(controller: vc, title: v.title, onBack: () => Navigator.pop(context));
    }
    return Stack(fit: StackFit.expand, children: [
      PosterImage(v.thumb),
      Container(color: Colors.black54),
      if (_error == null)
        const Center(child: CircularProgressIndicator(color: Colors.white))
      else
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 10),
              if (_needLogin)
                const Text('Library tab mein login karo.', style: TextStyle(color: Colors.white70))
              else if (!v.playable && v.telegram.isNotEmpty)
                FilledButton(
                  onPressed: () => launchUrl(Uri.parse(v.telegram), mode: LaunchMode.externalApplication),
                  child: const Text('Telegram mein kholo'),
                )
              else
                FilledButton(onPressed: _start, child: const Text('Retry')),
            ]),
          ),
        ),
      _backButton(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          AspectRatio(aspectRatio: 16 / 9, child: _playerArea()),
          Expanded(
            child: ListView(padding: EdgeInsets.zero, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(v.title, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, height: 1.25)),
                  const SizedBox(height: 6),
                  Text(
                    [
                      '${fmtCount(v.views)} views',
                      if (v.quality != null && v.quality!.isNotEmpty) v.quality!,
                      if (v.dur > 0) fmtDur(v.dur),
                    ].join(' • '),
                    style: t.bodySmall?.copyWith(color: Colors.white60),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  ActionPill(
                    icon: v.liked ? Icons.favorite : Icons.favorite_border,
                    label: fmtCount(v.likes),
                    active: v.liked,
                    onTap: _toggleLike,
                  ),
                  ActionPill(icon: Icons.playlist_add, label: 'Playlist', onTap: _playlistSheet),
                  if (v.telegram.isNotEmpty)
                    ActionPill(
                      icon: Icons.send_outlined,
                      label: 'Telegram',
                      onTap: () => launchUrl(Uri.parse(v.telegram), mode: LaunchMode.externalApplication),
                    ),
                ]),
              ),
              if (v.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Wrap(runSpacing: 8, children: [
                    for (final tg in v.tags.take(8))
                      TagChip(tg, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TagScreen(tag: tg)))),
                  ]),
                ),
              if (_more.isNotEmpty) ...[
                const SectionTitle('Aur videos'),
                for (final m in _more) VideoCard(m),
              ],
              const SizedBox(height: 24),
            ]),
          ),
        ]),
      ),
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
      padding: EdgeInsets.fromLTRB(16, 18, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Playlist mein daalo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 8),
        if (_lists == null)
          const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
        else
          for (final p in _lists!)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(p['has'] == true ? Icons.check_circle : Icons.circle_outlined, color: p['has'] == true ? kAccent : Colors.white54),
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
