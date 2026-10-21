class Video {
  final String id, title, kind, thumb, telegram;
  final int dur, views, likes;
  final bool liked, locked, premium, playable;
  final String? quality;
  final List<String> tags;

  const Video({
    required this.id,
    required this.title,
    required this.kind,
    required this.thumb,
    required this.telegram,
    required this.dur,
    required this.views,
    required this.likes,
    required this.liked,
    required this.locked,
    required this.premium,
    required this.playable,
    required this.quality,
    required this.tags,
  });

  factory Video.fromJson(Map<String, dynamic> j) {
    final urls = (j['urls'] is Map) ? j['urls'] as Map : const {};
    return Video(
      id: '${j['id']}',
      title: '${j['title'] ?? 'Untitled'}',
      kind: '${j['kind'] ?? 'long'}',
      thumb: '${j['thumb'] ?? ''}',
      telegram: '${urls['telegram'] ?? ''}',
      dur: (j['dur'] ?? 0) is num ? (j['dur'] as num).toInt() : 0,
      views: (j['views'] ?? 0) is num ? (j['views'] as num).toInt() : 0,
      likes: (j['likes'] ?? 0) is num ? (j['likes'] as num).toInt() : 0,
      liked: j['liked'] == true,
      locked: j['locked'] == true,
      premium: j['premium'] == true,
      playable: j['playable'] != false,
      quality: j['quality'] == null ? null : '${j['quality']}',
      tags: ((j['tags'] ?? []) as List).map((e) => '$e').toList(),
    );
  }

  Video withLike(bool liked, int likes) => Video(
        id: id, title: title, kind: kind, thumb: thumb, telegram: telegram,
        dur: dur, views: views, likes: likes, liked: liked, locked: locked,
        premium: premium, playable: playable, quality: quality, tags: tags,
      );
}

class PageData {
  final List<Video> items;
  final bool hasMore;
  const PageData(this.items, this.hasMore);
}

class ShortsData {
  final List<Video> items;
  final String? next;
  const ShortsData(this.items, this.next);
}

String fmtDur(int s) {
  if (s <= 0) return '';
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(sec)}' : '$m:${two(sec)}';
}

String fmtCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

class PageDataSingle {
  static PageData of(List<Video> items) => PageData(items, false);
}
