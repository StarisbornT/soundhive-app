import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../model/active_investment_model.dart';
import '../../model/creator_bookings_model.dart';
import '../provider.dart';
final getCreatorBookingProvider = StateNotifierProvider<GetCreatorBookingNotifier, AsyncValue<CreatorBookingsModel>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return GetCreatorBookingNotifier(dio, storage);
});

class GetCreatorBookingNotifier extends StateNotifier<AsyncValue<CreatorBookingsModel>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  List<Booking> _allServices = [];
  int _currentPage = 1;
  bool _isLastPage = false;
  bool _isLoadingMore = false;

  bool get isLastPage => _isLastPage;
  bool get isLoadingMore => _isLoadingMore;
  List<Booking> get allServices => _allServices;

  GetCreatorBookingNotifier(this._dio, this._storage)
      : super(const AsyncValue.loading());

  Future<void> getActiveInvestments({
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
        '/service/bookings/creator',
        queryParameters: {
          'page': _currentPage,
          'per_page': pageSize,
        },
        options: Options(headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
      );

      final result = CreatorBookingsModel.fromMap(response.data);
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
