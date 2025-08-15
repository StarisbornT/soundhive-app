import 'package:flutter/material.dart';

class AppLifecycleManager extends StatefulWidget {
  final Widget child;

  const AppLifecycleManager({super.key, required this.child});

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {
  // Track loader visibility and context
  bool _isLoaderShowing = false;
  BuildContext? _loaderContext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      default:
        break;
    }
  }

  void _onAppPaused() {
    // Standard cleanup
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _onAppResumed() {
    // No need for forceHideLoader() anymore
    // Just ensure no stuck focus states
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return _LifecycleAwareLoader(
      onLoaderShown: (ctx) => _loaderContext = ctx,
      onLoaderHidden: () => _loaderContext = null,
      child: widget.child,
    );
  }
}

/// Helper widget to track loader state
class _LifecycleAwareLoader extends StatelessWidget {
  final Function(BuildContext)? onLoaderShown;
  final VoidCallback? onLoaderHidden;
  final Widget child;

  const _LifecycleAwareLoader({
    required this.child,
    this.onLoaderShown,
    this.onLoaderHidden,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}