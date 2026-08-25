import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/location_service.dart';
import '../provider.dart';

final locationSyncProvider = Provider<LocationSyncService>((ref) {
  return LocationSyncService(ref.watch(dioProvider), ref.watch(storageProvider));
});

class LocationSyncService {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  static const _lastSyncKey = 'location_last_synced_at';
  static const _minInterval = Duration(hours: 6);

  LocationSyncService(this._dio, this._storage);

  /// Call this after login, and on app resume/startup.
  /// [force] bypasses the throttle — use this right after login,
  /// since that's a meaningful new session worth a fresh capture.
  Future<void> syncLocation({bool force = true}) async {
    debugPrint('🌍 syncLocation called, force=$force');
    if (!force) {
      final lastSyncStr = await _storage.read(key: _lastSyncKey);
      if (lastSyncStr != null) {
        final lastSync = DateTime.tryParse(lastSyncStr);
        if (lastSync != null && DateTime.now().difference(lastSync) < _minInterval) {
          return; // synced recently enough, skip
        }
      }
    }

    final outcome = await LocationService.getCurrentLocation();
    debugPrint('🌍 Location outcome: ${outcome.result}');

    if (outcome.result != LocationResult.success) {
      debugPrint('Location sync skipped: ${outcome.result}');
      return; // denied/disabled — don't fall back to guessing, just skip silently
    }

    try {
      await _dio.post(
        '/user/location',
        data: {
          'latitude': outcome.latitude,
          'longitude': outcome.longitude,
          'source': 'gps',
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );

      await _storage.write(key: _lastSyncKey, value: DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('🌍 Location sync failed: $e');
      if (e is DioException) {
        debugPrint('🌍 Status: ${e.response?.statusCode}, Data: ${e.response?.data}, Path: ${e.requestOptions.path}');
      }
      debugPrint('Location sync failed: $e');
      // Non-fatal — don't block the user's flow over this
    }
  }
}