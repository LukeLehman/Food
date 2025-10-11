// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import '../services/news_api.dart';
import '../config/api.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<NewsItem>? _news;
  String? _newsError;
  bool _loading = false;

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  Future<void> _loadNews() async {
    setState(() {
      _loading = true;
      _newsError = null;
    });
    try {
      final url = ApiConfig.newsUrl();
      debugPrint('NEWS URL => $url');
      final items = await NewsApi.fetch(); // uses ApiConfig.newsUrl()
      setState(() => _news = items);
    } catch (e) {
      debugPrint('NEWS ERROR => $e');
      setState(() => _newsError = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  @override
  Widget build(BuildContext context) {
    final links = [
      ('About ISHI', 'https://ironstronginitiative.com'),
      ('Privacy Policy', 'https://ironstronginitiative.com/privacy'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ISHI'),
        actions: [
          IconButton(
            tooltip: 'Refresh news',
            onPressed: _loading ? null : _loadNews,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNews,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Links section
            const Text(
              'Links',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...links.map((entry) {
              final (label, url) = entry;
              return Column(
                children: [
                  ListTile(
                    title: Text(label),
                    subtitle: Text(url, style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _openExternal(url),
                  ),
                  const Divider(height: 1),
                ],
              );
            }),

            const SizedBox(height: 16),

            // News section header
            Row(
              children: [
                const Text(
                  'Health News',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (_loading) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    height: 16,
                    width: 16,
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
                    onTap: () => _openExternal(n.url),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
