import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../widgets/floating_nav.dart';
import '../app_title_bar.dart';

class NewsDetailPage extends StatefulWidget {
  final String url;
  final String title;

  /// Optional: if you want tab switching from this screen, pass a callback
  /// that sets the main tab index. Otherwise we just `pop()` on nav taps.
  final ValueChanged<int>? onNavTap;

  const NewsDetailPage({
    super.key,
    required this.url,
    required this.title,
    this.onNavTap,
  });

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    // Recommended perf toggle for Android hardware-accelerated webview
    if (Platform.isAndroid) WebView.platform = AndroidWebView();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),
          onPageStarted: (_) => setState(() {
            _hasError = false;
            _progress = 0;
          }),
          onPageFinished: (_) => setState(() => _progress = 100),
          onWebResourceError: (e) => setState(() => _hasError = true),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _handleNavTap(int i) {
    // Keep the floating bar visible; delegate to host if provided,
    // otherwise just go back to the previous screen.
    if (widget.onNavTap != null) {
      widget.onNavTap!(i);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const AppTitleBar(logoSize: 24),
        actions: [
          if (_progress > 0 && _progress < 100)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  height: 16, width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.primary,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _controller.reload(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _hasError
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, size: 40),
                    const SizedBox(height: 12),
                    const Text('Failed to load article.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => _controller.loadRequest(Uri.parse(widget.url)),
                      child: const Text('Try again'),
                    )
                  ],
                ),
              ),
            )
          : WebViewWidget(controller: _controller),

      // Show the same floating bar here
      bottomNavigationBar: FloatingNavBar(
        currentIndex: 0,            // Home tab highlighted
        onTap: _handleNavTap,
      ),
    );
  }
}
