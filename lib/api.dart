import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'models.dart';

/// Apni Render site ka link yahan hai (end mein / nahi lagana).
const String kBaseUrl = 'https://snh4kt.onrender.com';
const String kAppName = 'Study Hub';

class ApiException implements Exception {
  final String code, message;
  ApiException(this.code, this.message);
  @override
  String toString() => message;
}

class Api {
  static String? token;
  static String? aid;
  static String? botName;

  static bool get loggedIn => token != null;

  static Future<File> _authFile() async {
    final d = await getApplicationSupportDirectory();
    return File('${d.path}/auth.json');
  }

  static Future<void> init() async {
    try {
      final f = await _authFile();
      if (await f.exists()) {
        final m = jsonDecode(await f.readAsString());
        token = m['token'] as String?;
        aid = m['aid'] as String?;
      }
    } catch (_) {}
  }

  static Future<void> _saveAuth(String? t, String? a) async {
    token = t;
    aid = a;
    try {
      final f = await _authFile();
      if (t == null) {
        if (await f.exists()) await f.delete();
      } else {
        await f.writeAsString(jsonEncode({'token': t, 'aid': a ?? ''}));
      }
    } catch (_) {
      // save na ho paye to bhi is session mein login chalta rahega
    }
  }

  static Map<String, String> _headers() => {
        'X-Requested-With': 'fetch',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Future<dynamic> _req(String method, String path,
      {Map<String, String>? query, Object? body}) async {
    final uri = Uri.parse('$kBaseUrl$path').replace(queryParameters: query);
    http.Response r;
    try {
      if (method == 'GET') {
        r = await http.get(uri, headers: _headers()).timeout(const Duration(seconds: 45));
      } else {
        r = await http
            .post(uri, headers: _headers(), body: jsonEncode(body ?? {}))
            .timeout(const Duration(seconds: 45));
      }
    } catch (_) {
      throw ApiException('network', 'Internet ya server ki dikkat. Dobara try karo.');
    }
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(r.bodyBytes));
    } catch (_) {
      data = null;
    }
    if (r.statusCode >= 400) {
      final e = data is Map ? data['error'] : null;
      if (r.statusCode == 401 && token != null && path != '/api/v1/auth/login') {
        await _saveAuth(null, null); // session expire ho gaya
      }
      throw ApiException(e is Map ? '${e['code']}' : 'error',
          e is Map ? '${e['message']}' : 'Error ${r.statusCode}');
    }
    return data;
  }

  static List<Video> _list(dynamic l) =>
      ((l ?? []) as List).map((e) => Video.fromJson(Map<String, dynamic>.from(e as Map))).toList();

  // ---- videos ----
  static Future<PageData> videos({
    String kind = 'all',
    String sort = 'new',
    String? q,
    String? tag,
    int page = 1,
    int limit = 12,
  }) async {
    final d = await _req('GET', '/api/v1/videos', query: {
      'kind': kind,
      'sort': sort,
      'page': '$page',
      'limit': '$limit',
      if (q != null && q.isNotEmpty) 'q': q,
      if (tag != null) 'tag': tag,
    });
    return PageData(_list(d['items']), d['has_more'] == true);
  }

  static Future<ShortsData> shorts({String? after, int limit = 10}) async {
    final d = await _req('GET', '/api/v1/shorts', query: {
      'limit': '$limit',
      if (after != null) 'after': after,
    });
    return ShortsData(_list(d['items']), d['next'] as String?);
  }

  static Future<List<Video>> suggest(String id) async {
    final d = await _req('GET', '/api/v1/videos/$id/suggest', query: {'limit': '8'});
    return _list(d['items']);
  }

  static Future<List<String>> tags() async {
    final d = await _req('GET', '/api/v1/tags');
    return ((d['tags'] ?? []) as List).map((e) => '$e').toList();
  }

  static Future<String> playUrl(String id) async {
    final d = await _req('GET', '/api/v1/videos/$id/play');
    return '${d['url']}';
  }

  static Future<void> addView(String id) async {
    try {
      await _req('POST', '/api/v1/videos/$id/view');
    } catch (_) {}
  }

  static Future<int> like(String id, bool like) async {
    final d = await _req('POST', '/api/v1/videos/$id/like', body: {'like': like});
    return (d['likes'] ?? 0) as int;
  }

  // ---- account ----
  static Future<void> loadMe() async {
    try {
      final d = await _req('GET', '/api/v1/me');
      botName = d['bot'] as String?;
      if (d['logged_in'] != true && token != null) await _saveAuth(null, null);
    } catch (_) {}
  }

  static Future<void> login(String id, String password) async {
    final d = await _req('POST', '/api/v1/auth/login', body: {'id': id, 'password': password});
    final t = d['token'] as String?;
    if (t == null) {
      throw ApiException('server', 'Server abhi token login support nahi karta. Backend update karo.');
    }
    await _saveAuth(t, '${d['aid']}');
  }

  static Future<void> logout() async {
    try {
      await _req('POST', '/api/v1/auth/logout');
    } catch (_) {}
    await _saveAuth(null, null);
  }

  static Future<PageData> myLikes({int page = 1}) async {
    final d = await _req('GET', '/api/v1/me/likes', query: {'page': '$page'});
    return PageData(_list(d['items']), d['has_more'] == true);
  }

  static Future<List<Map<String, dynamic>>> playlists({String video = ''}) async {
    final d = await _req('GET', '/api/v1/me/playlists', query: {if (video.isNotEmpty) 'video': video});
    return ((d['items'] ?? []) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<List<Video>> playlistVideos(String pid) async {
    final d = await _req('GET', '/api/v1/me/playlists/$pid');
    return _list(d['items']);
  }

  static Future<void> createPlaylist(String name, {String? video}) async {
    await _req('POST', '/api/v1/me/playlists', body: {'name': name, if (video != null) 'video': video});
  }

  static Future<void> addToPlaylist(String pid, String video) async {
    await _req('POST', '/api/v1/me/playlists/$pid/items', body: {'video': video});
  }
}
