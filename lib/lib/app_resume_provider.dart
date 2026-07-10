import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How long the app can sit backgrounded before we treat returning to it
/// as "stale" and worth refreshing data for.
const Duration staleAfterBackground = Duration(minutes: 2);

/// Increments every time the app resumes after being backgrounded longer
/// than [staleAfterBackground]. Screens that want to auto-refresh their
/// data on a stale resume should `ref.listen` to this and re-fetch.
final appResumeSignalProvider = StateProvider<int>((ref) => 0);