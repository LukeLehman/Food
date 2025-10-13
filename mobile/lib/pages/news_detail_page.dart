// lib/pages/news_detail_page.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_title_bar.dart';

class NewsDetailPage extends StatefulWidget {
  final String title;
  final String url;
  const NewsDetailPage({super.key, required this.title, required this.url});

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  late final WebViewController _controller;
  double _progress = 0;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _progress = 0),
          onProgress: (p) => setState(() => _progress = p / 100.0),
          onPageFinished: (_) => setState(() => _progress = 1),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _openExternally() async {
    final uri = Uri.parse(widget.url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // smaller than Home, still bigger than default
        title: const AppTitleBar(logoSize: 36),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: (_progress > 0 && _progress < 1) ? 2 : 0,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: _progress.clamp(0, 1),
              child: Container(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
      ),
      body: SafeArea(child: WebViewWidget(controller: _controller)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _ChromeBar(
            onBack: () async {
              if (await _controller.canGoBack()) {
                _controller.goBack();
              } else if (mounted) {
                Navigator.pop(context);
              }
            },
            onForward: () async {
              if (await _controller.canGoForward()) {
                _controller.goForward();
              }
            },
            onReload: () => _controller.reload(),
            openInBrowser: _openExternally,
          ),
        ),
      ),
    );
  }
}

/// Small chrome bar for back/forward/reload/open
class _ChromeBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onReload;
  final VoidCallback openInBrowser;

  const _ChromeBar({
    required this.onBack,
    required this.onForward,
    required this.onReload,
    required this.openInBrowser,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PhysicalModel(
      color: cs.surface,
      elevation: 10,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 56,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(tooltip: 'Back', onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded)),
            IconButton(tooltip: 'Forward', onPressed: onForward, icon: const Icon(Icons.arrow_forward_rounded)),
            IconButton(tooltip: 'Reload', onPressed: onReload, icon: const Icon(Icons.refresh_rounded)),
            IconButton(tooltip: 'Open', onPressed: openInBrowser, icon: const Icon(Icons.open_in_new_rounded)),
          ],
        ),
      ),
    );
  }
}
