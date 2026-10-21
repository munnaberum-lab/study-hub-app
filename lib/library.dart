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
    return SafeArea(
      child: DefaultTabController(
        length: 2,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
            child: Row(children: [
              Expanded(
                child: Text('Library • ${Api.aid ?? ''}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Api.logout();
                  if (mounted) setState(() {});
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ]),
          ),
          const TabBar(tabs: [Tab(text: 'Liked'), Tab(text: 'Playlists')]),
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
          child: ListView(children: [
            for (final p in l)
              ListTile(
                leading: const Icon(Icons.playlist_play),
                title: Text('${p['name']}'),
                subtitle: Text('${p['count']} videos'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: Text('${p['name']}')),
                      body: VideoListView(
                        loader: (page) async {
                          final items = await Api.playlistVideos('${p['id']}');
                          return PageDataSingle.of(items);
                        },
                        emptyText: 'Playlist khali hai.',
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
    } catch (e) {
      if (mounted) setState(() => _err = '$e');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      const SizedBox(height: 30),
      const Icon(Icons.account_circle, size: 72, color: Colors.deepPurpleAccent),
      const SizedBox(height: 8),
      Text('Login karo', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 4),
      const Text('Like, playlist aur premium ke liye', textAlign: TextAlign.center),
      const SizedBox(height: 24),
      TextField(
        controller: _id,
        autocorrect: false,
        decoration: const InputDecoration(labelText: 'Account ID', border: OutlineInputBorder()),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _pw,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
        onSubmitted: (_) => _submit(),
      ),
      if (_err != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_err!, style: const TextStyle(color: Colors.red))),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: _busy ? null : _submit,
        child: _busy ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Login'),
      ),
      const SizedBox(height: 16),
      if (Api.botName != null)
        TextButton(
          onPressed: () => launchUrl(Uri.parse('https://t.me/${Api.botName}'), mode: LaunchMode.externalApplication),
          child: Text('Account nahi hai? Telegram bot @${Api.botName} se banao'),
        ),
    ]);
  }
}
