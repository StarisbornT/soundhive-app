import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_resume_provider.dart';
import 'dashboard_provider/user_provider.dart';

class AppLifecycleManager extends ConsumerStatefulWidget {
  final Widget child;

  const AppLifecycleManager({super.key, required this.child});

  @override
  ConsumerState<AppLifecycleManager> createState() =>
      _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends ConsumerState<AppLifecycleManager>
    with WidgetsBindingObserver {
  DateTime? _pausedAt;

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
    FocusManager.instance.primaryFocus?.unfocus();
    _pausedAt = DateTime.now();
  }

  void _onAppResumed() {
    FocusManager.instance.primaryFocus?.unfocus();

    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (pausedAt == null) return;

    final awayFor = DateTime.now().difference(pausedAt);
    if (awayFor < staleAfterBackground) return;

    // Refresh core, app-wide data that most screens depend on.
    ref.read(userProvider.notifier).loadUserProfile();

    // Broadcast to any screen that wants to refresh its own data —
    // see appResumeSignalProvider for how to listen to this.
    ref.read(appResumeSignalProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}