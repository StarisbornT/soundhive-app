import 'package:flutter/material.dart';

import '../components/loader.dart';

class LoaderService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static bool _isLoaderVisible = false;

  static bool get isLoaderVisible => _isLoaderVisible;

  static void showLoader(BuildContext context) {
    if (_isLoaderVisible) return;

    _isLoaderVisible = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LogoLoader(
        logoPath: 'assets/logo.png',
      ),
    ).then((_) {
      _isLoaderVisible = false;
    });
  }

  static void hideLoader(BuildContext context) {
    if (!_isLoaderVisible) return;

    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
      _isLoaderVisible = false;
    }
  }
}
