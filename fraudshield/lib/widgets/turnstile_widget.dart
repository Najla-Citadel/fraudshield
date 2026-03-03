import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TurnstileWidget extends StatefulWidget {
  final Function(String token) onTokenReceived;

  const TurnstileWidget({super.key, required this.onTokenReceived});

  @override
  State<TurnstileWidget> createState() => _TurnstileWidgetState();
}

class _TurnstileWidgetState extends State<TurnstileWidget> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final siteKey =
        dotenv.env['TURNSTILE_SITE_KEY'] ?? '0x4AAAAAAAx7Y8n7Y8n7Y8n7';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'CaptchaChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message.startsWith('ERROR_')) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Security Check Failed';
            });
          } else {
            widget.onTokenReceived(message.message);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Turnstile WebView Error: ${error.description}');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Connection Error';
              });
            }
          },
        ),
      )
      ..loadHtmlString('''
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>
    <style>
        body { 
          margin: 0; 
          padding: 0; 
          background-color: transparent; 
          display: flex; 
          justify-content: center; 
          align-items: center; 
          height: 100vh;
          overflow: hidden;
        }
        .cf-turnstile {
          transform: scale(0.85); /* Slightly smaller for mobile */
        }
    </style>
</head>
<body>
    <div class="cf-turnstile" 
         data-sitekey="$siteKey" 
         data-callback="javascriptCallback"
         data-error-callback="errorCallback"
         data-theme="dark"></div>
    <script>
        function javascriptCallback(token) {
            CaptchaChannel.postMessage(token);
        }
        function errorCallback(code) {
            CaptchaChannel.postMessage('ERROR_' + code);
        }
    </script>
</body>
</html>
''', baseUrl: 'https://api.fraudshieldprotect.com');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Stack(
        children: [
          if (_errorMessage != null)
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _controller.reload();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(
                  '$_errorMessage. Tap to retry',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            )
          else ...[
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
