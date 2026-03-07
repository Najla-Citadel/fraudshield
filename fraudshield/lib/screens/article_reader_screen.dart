import 'package:flutter/material.dart';
import '../design_system/components/app_loading_indicator.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/layouts/screen_scaffold.dart';

class ArticleReaderScreen extends StatefulWidget {
  final String title;
  final String url;

  const ArticleReaderScreen({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<ArticleReaderScreen> createState() => _ArticleReaderScreenState();
}

class _ArticleReaderScreenState extends State<ArticleReaderScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: widget.title,
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Center(
              child: AppLoadingIndicator(color: DesignTokens.colors.primaryBlue),
            ),
        ],
      ),
    );
  }
}
