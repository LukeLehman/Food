// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Fallback: try in-app webview
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    final links = [
      ('About ISHI', 'https://ironstronginitiative.com'),
      ('Privacy Policy', 'https://ironstronginitiative.com/privacy'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('ISHI')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: links.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, i) {
          final (label, url) = links[i];
          return ListTile(
            title: Text(label),
            subtitle: Text(url, style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _openExternal(url),
          );
        },
      ),
    );
  }
}
