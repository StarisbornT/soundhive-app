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

  // Filtering tracking fields
  String? _selectedType;
  int? _selectedCategoryId;
  String? _selectedStage;

  GetInvestmentNotifier(this._dio, this._storage) : super(const AsyncValue.loading()) {
    getInvestments();
  }

  Future<void> getInvestments({
    bool reset = false,
    String? searchQuery,
    String? type,
    int? categoryId,
    String? projectStage,
  }) async {
    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    if (searchQuery != null) _searchQuery = searchQuery;
    if (type != null) _selectedType = type == 'ALL' ? null : type;
    if (categoryId != null) _selectedCategoryId = categoryId == -1 ? null : categoryId;
    if (projectStage != null) _selectedStage = projectStage == 'ALL' ? null : projectStage;

    if (!_hasMore && !reset) return;

    try {
      final queryParams = {
        'page': _currentPage,
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        if (_selectedType != null) 'type': _selectedType,
        if (_selectedCategoryId != null) 'category_id': _selectedCategoryId,
        if (_selectedStage != null) 'project_stage': _selectedStage,
      };

      final response = await _dio.get(
          '/soundhive-vests',
          queryParameters: queryParams,
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

  Future<void> filterVests({String? type, int? categoryId, String? stage}) async {
    await getInvestments(reset: true, type: type, categoryId: categoryId, projectStage: stage);
  }

  Future<void> loadMore() async {
    if (_hasMore && !state.isLoading) {
      await getInvestments();
    }
  }
}