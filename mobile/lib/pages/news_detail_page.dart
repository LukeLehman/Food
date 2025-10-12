import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../ui/app_title_bar.dart';
import '../widgets/floating_nav.dart'; // your existing FloatingNavBar

class NewsDetailPage extends StatefulWidget {
  final String title;
  final String url;
  const NewsDetailPage({super.key, required this.title, required this.url});

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  late final WebViewController _controller;
  bool _canGoBack = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = AndroidWebView();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) async {
            final can = await _controller.canGoBack();
            setState(() {
              _canGoBack = can;
              _loading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _back() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      setState(() {});
    } else {
      if (mounted) Navigator.of(context).maybePop();
    }
  }

  void _onBottomTap(int index) {
    switch (index) {
      case 0: // Home
        Navigator.of(context).popUntil((r) => r.isFirst);
        break;
      case 1: // ISHI-AI Check
        Navigator.of(context).popUntil((r) => r.isFirst);
        // push your AI page route here if needed
        break;
      case 2: // Events
      case 3: // Profile
      case 4: // About
        Navigator.of(context).popUntil((r) => r.isFirst);
        // then push the corresponding tab/page if you have routes
        break;
      case 5: // Donate
        // If you have a donate route or external link, open it:
        // launchUrl(Uri.parse('https://...'));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: _canGoBack ? 'Back in page' : 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
        title: const AppTitleBar(logoSize: 28),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
        ],
      ),
      // Show your existing floating nav on the article screen too:
      bottomNavigationBar: FloatingNavBar(
        currentIndex: 0,      // highlight whatever makes sense here
        onTap: _onBottomTap,  // same handler as Home
      ),
    );
  }
}
