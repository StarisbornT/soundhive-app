import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:soundhive2/model/investment_model.dart';

import '../provider.dart';

final getInvestmentProvider = StateNotifierProvider<GetInvestmentNotifier, AsyncValue<InvestmentResponse>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return GetInvestmentNotifier(dio, storage);
});

class GetInvestmentNotifier extends StateNotifier<AsyncValue<InvestmentResponse>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  int _currentPage = 1;
  bool _hasMore = true;
  String _searchQuery = '';

  GetInvestmentNotifier(this._dio, this._storage) : super(const AsyncValue.loading()) {
    getInvestments();
  }

  Future<void> getInvestments({bool reset = false, String? searchQuery}) async {
    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    if (searchQuery != null) {
      _searchQuery = searchQuery;
      _currentPage = 1;
      _hasMore = true;
    }

    if (!_hasMore && !reset) return;

    try {
      final response = await _dio.get(
          '/soundhive-vests',
          queryParameters: {
            'page': _currentPage,
            if (_searchQuery.isNotEmpty) 'search': _searchQuery,
          },
          options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
              }
          )
      );

      final serviceResponse = InvestmentResponse.fromMap(response.data);

      if (reset) {
        state = AsyncValue.data(serviceResponse);
      } else {
        final currentData = state.value;
        if (currentData != null) {
          final mergedData = PaginatedData(
            currentPage: serviceResponse.data.currentPage,
            data: [...currentData.data.data, ...serviceResponse.data.data],
            firstPageUrl: serviceResponse.data.firstPageUrl,
            from: serviceResponse.data.from,
            lastPage: serviceResponse.data.lastPage,
            lastPageUrl: serviceResponse.data.lastPageUrl,
            links: serviceResponse.data.links,
            nextPageUrl: serviceResponse.data.nextPageUrl,
            path: serviceResponse.data.path,
            perPage: serviceResponse.data.perPage,
            prevPageUrl: serviceResponse.data.prevPageUrl,
            to: serviceResponse.data.to,
            total: serviceResponse.data.total,
          );
          state = AsyncValue.data(InvestmentResponse(
            status: serviceResponse.status,
            data: mergedData,
          ));
        } else {
          state = AsyncValue.data(serviceResponse);
        }
      }

      _hasMore = serviceResponse.data.nextPageUrl != null;
      if (_hasMore) {
        _currentPage++;
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> searchInvestments(String query) async {
    await getInvestments(reset: true, searchQuery: query);
  }

  Future<void> loadMore() async {
    if (_hasMore && !state.isLoading) {
      await getInvestments();
    }
  }

  Future<void> getActiveInvestments() async {
    _currentPage = 1;
    _hasMore = true;
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
          '/member/investment/member-list',
          options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
              }
          )
      );
      final serviceResponse = InvestmentResponse.fromMap(response.data);
      state = AsyncValue.data(serviceResponse);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}