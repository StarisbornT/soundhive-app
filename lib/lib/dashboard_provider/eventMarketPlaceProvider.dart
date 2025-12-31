import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/model/event_model.dart';
import '../../model/event_marketplace_model.dart';
import '../provider.dart';
final eventMarketPlaceProvider = StateNotifierProvider<EventMarketplaceNotifier, AsyncValue<EventMarketplaceModel>>((ref) {
  final dio = ref.watch(dioProvider);
  return EventMarketplaceNotifier(dio);
});

class EventMarketplaceNotifier extends StateNotifier<AsyncValue<EventMarketplaceModel>> {
  final Dio _dio;

  List<EventItem> _allServices = [];
  int _currentPage = 1;
  bool _isLastPage = false;
  bool _isLoadingMore = false;

  bool get isLastPage => _isLastPage;
  bool get isLoadingMore => _isLoadingMore;
  List<EventItem> get allServices => _allServices;

  EventMarketplaceNotifier(this._dio)
      : super(const AsyncValue.loading());

  Future<void> getEventMarketplace({
    bool loadMore = false,
    int? pageSize,
  }) async {
    if (_isLastPage && loadMore) return;

    if (loadMore) {
      _isLoadingMore = true;
      state = state; // keep old data
    } else {
      state = const AsyncValue.loading();
      _currentPage = 1;
      _allServices = [];
      _isLastPage = false;
    }

    try {
      final response = await _dio.get(
        '/events/marketplace',
        queryParameters: {
          'page': _currentPage,
          'per_page': pageSize,
        },
        options: Options(headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
      );

      final result = EventMarketplaceModel.fromMap(response.data);
      final newServices = result.data.data;

      if (loadMore) {
        _allServices.addAll(newServices);
      } else {
        _allServices = newServices;
      }

      state = AsyncValue.data(result);

      if (newServices.isEmpty) {
        _isLastPage = true;
      } else {
        _currentPage += 1;
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    } finally {
      _isLoadingMore = false;
    }
  }
}
