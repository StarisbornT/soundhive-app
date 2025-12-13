import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VerificationWebView extends ConsumerStatefulWidget {
  final String url;
  final String? title;

  const VerificationWebView({super.key, required this.url, this.title});

  @override
  ConsumerState<VerificationWebView> createState() => _VerificationWebViewState();
}

class _VerificationWebViewState extends ConsumerState<VerificationWebView> {
  late final WebViewController _controller;
  bool _successDetected = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            try {
              final result = await _controller.runJavaScriptReturningResult('''
                (function() {
                try {
                  const content = document.body.innerText;
                  if (content.includes('"success":true') || 
                      content.includes('"close_window":true')) {
                    return true;
                  }
                  return false;
                } catch(e) {
                  return false;
                }
              })()
              ''');

              if (result == true) {
                if (!_successDetected) {
                  _successDetected = true;
                  Navigator.pop(context, 'success');
                }
              }
            } catch (e) {
              print('Error checking payment status: $e');
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: const Color(0xFF0C051F),
        title:  Text(
          widget.title ?? 'BVN Verification',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _controller.reload();
              print("🔄 WebView reloaded");
            },
          ),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
