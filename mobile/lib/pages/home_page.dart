// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/news_api.dart';
import '../config/api.dart';
import 'news_detail_page.dart';
import 'app_title_bar.dart';


appBar: AppBar(
  title: const AppTitleBar(logoSize: 44), // bigger logo on Home
  actions: [
    IconButton(
      tooltip: 'Refresh news',
      onPressed: _loadingNews ? null : _loadNews,
      icon: const Icon(Icons.refresh),
    ),
  ],
),

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<NewsItem>? _news;
  String? _newsError;
  bool _loadingNews = false;
  bool _checkedVersion = false;

  @override
  void initState() {
    super.initState();
    _checkVersion();
    _loadNews();
  }

  // Compare semantic versions: -1 if a<b, 0 if equal, 1 if a>b
  int _cmpVersion(String a, String b) {
    List<int> p(String v) => v
        .split('.')
        .map((e) => int.tryParse(e.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
    final pa = p(a), pb = p(b);
    final len = (pa.length > pb.length) ? pa.length : pb.length;
    for (var i = 0; i < len; i++) {
      final ai = i < pa.length ? pa[i] : 0;
      final bi = i < pb.length ? pb[i] : 0;
      if (ai != bi) return ai.compareTo(bi);
    }
    return 0;
  }

  Future<void> _checkVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = info.version;
      final required = ApiConfig.minAppVersion;
      if (_cmpVersion(current, required) < 0 && mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Update required'),
            content: Text(
              'A newer version of ISHI is available.\n\n'
              'Installed: $current\n'
              'Required:  $required\n\n'
              'Please update to continue.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(); // leave upgrade path to store links in About/Profile
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (_) {
      // Don’t block if PackageInfo fails.
    } finally {
      if (mounted) setState(() => _checkedVersion = true);
    }
  }

  Future<void> _loadNews() async {
    setState(() {
      _loadingNews = true;
      _newsError = null;
    });
    try {
      final url = ApiConfig.newsUrl();
      debugPrint('NEWS URL => $url');
      final items = await NewsApi.fetch();
      if (!mounted) return;
      setState(() => _news = items);
    } catch (e) {
      debugPrint('NEWS ERROR => $e');
      if (!mounted) return;
      setState(() => _newsError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingNews = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ensure this exists and is listed in pubspec.yaml
        Image.asset('assets/logo.png', height: 32),
        const SizedBox(width: 8),
        const Flexible(
          child: Text(
            'Iron Strong Health Initiative',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: titleRow,
        actions: [
          IconButton(
            tooltip: 'Refresh news',
            onPressed: _loadingNews ? null : _loadNews,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNews,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Text(
                  'Health News',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (_loadingNews) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            if (_newsError != null)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Failed to load news.\n$_newsError',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              )
            else if (_news == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_news!.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No news right now.')),
              )
            else
              ..._news!.map((n) {
                return Card(
                  elevation: 0,
                  child: ListTile(
                    title: Text(n.title),
                    subtitle: Text(n.source),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NewsDetailPage(
                            title: n.title,
                            url: n.url,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),

            const SizedBox(height: 24),
            if (!_checkedVersion && kDebugMode)
              const Center(
                child: Text(
                  'Checking app version…',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
