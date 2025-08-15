// Add these imports at the top of your file
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../components/success.dart';
import '../../lib/dashboard_provider/user_provider.dart';
import 'dashboard.dart';

// Modified VerificationWebView class
class VerificationWebView extends ConsumerStatefulWidget  {
  final String url;

  const VerificationWebView({super.key, required this.url});

  @override
  ConsumerState<VerificationWebView> createState() => _VerificationWebViewState();
}

class _VerificationWebViewState extends ConsumerState<VerificationWebView>{
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebViewController();
  }

  Future<void> _initializeWebViewController() async {
    _controller = WebViewController();

    // Platform-specific configuration
    if (_controller.platform is AndroidWebViewController) {
      final androidController = _controller.platform as AndroidWebViewController;
      await androidController.setMediaPlaybackRequiresUserGesture(false);
      await androidController.setOnPlatformPermissionRequest((request) {
        request.grant();
      });
    }

    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _controller.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (request) {
          final uri = Uri.parse(request.url);
          if (uri.host.contains('google.com')) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              // Load user profile
              final userNotifier = ref.read(userProvider.notifier);
              await userNotifier.loadUserProfile();
              // Replace current route with Success page
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const Success(
                    title: 'Verified Successfully',
                    subtitle: 'Your Identity Verified successfully!',
                    navigation: DashboardScreen.id,
                  ),
                ),
              );
            });
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );
    await _controller.loadRequest(Uri.parse(widget.url));

    setState(() => _isLoading = false);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white), // iOS-style back icon
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Color(0xFF0C051F),
        title: const Text('Identity Verification', style: TextStyle(color: Colors.white),),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}