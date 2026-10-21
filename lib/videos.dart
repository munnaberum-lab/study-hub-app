import 'package:flutter/material.dart';

import 'api.dart';
import 'widgets.dart';

/// "Videos" tab: sab lambi videos, sort ke saath.
class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});
  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  String _sort = 'new';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
          child: Row(children: [
            Text('Videos', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            ChoiceChip(label: const Text('Naye'), selected: _sort == 'new', onSelected: (_) => setState(() => _sort = 'new')),
            const SizedBox(width: 6),
            ChoiceChip(label: const Text('Popular'), selected: _sort == 'views', onSelected: (_) => setState(() => _sort = 'views')),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
            ),
          ]),
        ),
        Expanded(
          child: VideoListView(
            key: ValueKey(_sort),
            loader: (p) => Api.videos(kind: 'long', sort: _sort, page: p),
          ),
        ),
      ]),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctl = TextEditingController();
  String _q = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctl,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(hintText: 'Videos, tags search karo...', border: InputBorder.none),
          onSubmitted: (v) => setState(() => _q = v.trim()),
        ),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () => setState(() => _q = _ctl.text.trim()))],
      ),
      body: _q.isEmpty
          ? const EmptyBox('Kuch likhkar search karo.')
          : VideoListView(
              key: ValueKey(_q),
              loader: (p) => Api.videos(q: _q, page: p),
              emptyText: 'Kuch nahi mila.',
            ),
    );
  }
}

class TagScreen extends StatelessWidget {
  final String tag;
  const TagScreen({super.key, required this.tag});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('#$tag')),
      body: VideoListView(loader: (p) => Api.videos(tag: tag, page: p)),
    );
  }
}
