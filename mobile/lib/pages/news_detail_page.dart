// lib/pages/news_detail_page.dart
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

    // If you have any http (non-https) links and need cleartext on Android,
    // remember to set android:usesCleartextTraffic="true" in AndroidManifest.
  }

  @override
  Widget build(BuildContext context) {
    // final titleBar = AppTitleBar(logoSize: 28, title: widget.title);
    final titleBar = const AppTitleBar(logoSize: 28);

    return Scaffold(
      appBar: AppBar(
        title: titleBar,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: _progress < 1 && _progress > 0 ? 2 : 0,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: _progress.clamp(0, 1),
              child: Container(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
      // Your floating bar (keep it consistent with Home)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _ChromeBar(
            onBack: () async {
              if (await _controller.canGoBack()) {
                _controller.goBack();
              } else {
                if (context.mounted) Navigator.pop(context);
              }
            },
            onForward: () async {
              if (await _controller.canGoForward()) {
                _controller.goForward();
              }
            },
            onReload: () => _controller.reload(),
            openInBrowser: () {
              // you can wire url_launcher here if you want an external open
              _controller.loadRequest(Uri.parse(widget.url));
            },
          ),
        ),
      ),
    );
  }
}

/// A small in-page “floating” chrome bar for back/forward/reload.
/// If you already have a global FloatingNavBar, you can remove this and
/// reuse that widget here instead.
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
