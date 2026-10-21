import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';
import 'models.dart';
import 'widgets.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  Widget build(BuildContext context) {
    if (!Api.loggedIn) {
      return SafeArea(child: LoginView(onDone: () => setState(() {})));
    }
    final name = Api.aid ?? '';
    return SafeArea(
      child: DefaultTabController(
        length: 2,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: const BoxDecoration(gradient: kGradient, shape: BoxShape.circle),
                child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const Text('Meri Library', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ]),
              ),
              IconButton(
                tooltip: 'Logout',
                onPressed: () async {
                  await Api.logout();
                  if (mounted) setState(() {});
                },
                icon: const Icon(Icons.logout),
              ),
            ]),
          ),
          const TabBar(
            indicatorColor: kAccent,
            labelColor: kAccent,
            unselectedLabelColor: Colors.white60,
            tabs: [Tab(text: 'Liked'), Tab(text: 'Playlists')],
          ),
          Expanded(
            child: TabBarView(children: [
              VideoListView(loader: (p) => Api.myLikes(page: p), emptyText: 'Abhi koi liked video nahi hai.'),
              const _PlaylistsTab(),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _PlaylistsTab extends StatefulWidget {
  const _PlaylistsTab();
  @override
  State<_PlaylistsTab> createState() => _PlaylistsTabState();
}

class _PlaylistsTabState extends State<_PlaylistsTab> {
  late Future<List<Map<String, dynamic>>> _f = Api.playlists();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _f,
      builder: (c, s) {
        if (s.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (s.hasError) return ErrorBox(s.error!, () => setState(() => _f = Api.playlists()));
        final l = s.data!;
        if (l.isEmpty) return const EmptyBox('Koi playlist nahi hai.\nVideo kholkar "Playlist" button se banao.');
        return RefreshIndicator(
          onRefresh: () async => setState(() => _f = Api.playlists()),
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
            for (final p in l)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1B26),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(gradient: kGradient, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.playlist_play, color: Colors.white),
                  ),
                  title: Text('${p['name']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${p['count']} videos'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: Text('${p['name']}')),
                        body: VideoListView(
                          loader: (page) async => PageDataSingle.of(await Api.playlistVideos('${p['id']}')),
                          emptyText: 'Playlist khali hai.',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        );
      },
    );
  }
}

class LoginView extends StatefulWidget {
  final VoidCallback onDone;
  const LoginView({super.key, required this.onDone});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _id = TextEditingController();
  final _pw = TextEditingController();
  bool _busy = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    Api.loadMe().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      await Api.login(_id.text.trim(), _pw.text);
      widget.onDone();
      return;
    } catch (e) {
      final m = '$e';
      if (mounted) setState(() => _err = m.length > 160 ? '${m.substring(0, 160)}...' : m);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(24, 36, 24, 24), children: [
      Center(
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(gradient: kGradient, borderRadius: BorderRadius.circular(26)),
          child: const Icon(Icons.person_rounded, color: Colors.white, size: 46),
        ),
      ),
      const SizedBox(height: 18),
      Text('Welcome back', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      const Text('Like, playlist aur premium ke liye login karo', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
      const SizedBox(height: 28),
      TextField(
        controller: _id,
        autocorrect: false,
        decoration: InputDecoration(
          labelText: 'Account ID',
          prefixIcon: const Icon(Icons.alternate_email),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _pw,
        obscureText: true,
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon: const Icon(Icons.lock_outline),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onSubmitted: (_) => _submit(),
      ),
      if (_err != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(_err!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
        ),
      const SizedBox(height: 20),
      SizedBox(
        height: 52,
        child: FilledButton(
          style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
      const SizedBox(height: 16),
      if (Api.botName != null)
        TextButton(
          onPressed: () => launchUrl(Uri.parse('https://t.me/${Api.botName}'), mode: LaunchMode.externalApplication),
          child: Text('Account nahi hai? Telegram bot @${Api.botName} se banao', textAlign: TextAlign.center),
        ),
    ]);
  }
}
