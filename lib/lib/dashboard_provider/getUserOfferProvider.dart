import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/offerFromUserModel.dart';
import '../provider.dart';
final getUserOfferProvider = StateNotifierProvider<GetUserOfferNotifier, AsyncValue<OfferFromUserModel>>((ref) {
  final dio = ref.watch(dioProvider);
  return GetUserOfferNotifier(dio);
});

class GetUserOfferNotifier extends StateNotifier<AsyncValue<OfferFromUserModel>> {
  final Dio _dio;

  List<OfferFromUser> _allServices = [];
  int _currentPage = 1;
  bool _isLastPage = false;
  bool _isLoadingMore = false;

  bool get isLastPage => _isLastPage;
  bool get isLoadingMore => _isLoadingMore;
  List<OfferFromUser> get allServices => _allServices;

  GetUserOfferNotifier(this._dio)
      : super(const AsyncValue.loading());

  Future<void> getMyOffers({
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
        '/offers/my-offers',
        queryParameters: {
          'page': _currentPage,
          'per_page': pageSize,
        },
        options: Options(headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
      );

      final result = OfferFromUserModel.fromMap(response.data);
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