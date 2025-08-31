import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../model/get_active_vest_model.dart';
import '../provider.dart';

final getActiveVestProvider = StateNotifierProvider<GetActiveVestNotifier, AsyncValue<ActiveVestResponse>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return GetActiveVestNotifier(dio, storage);
});

class GetActiveVestNotifier extends StateNotifier<AsyncValue<ActiveVestResponse>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  List<ActiveVest> _allInvestments = [];
  int _currentPage = 1;
  bool _isLastPage = false;
  String? _currentStatus;
  String? _currentSearchQuery;

  GetActiveVestNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  List<ActiveVest> get allInvestments => _allInvestments;
  bool get isLastPage => _isLastPage;

  Future<void> getActiveVest({
    bool loadMore = false,
    String? status,
    String? searchQuery,
    int pageSize = 10,
  }) async {
    if (_isLastPage && loadMore) return;

    // Reset pagination if parameters changed
    if (!loadMore || status != _currentStatus || searchQuery != _currentSearchQuery) {
      _currentPage = 1;
      _allInvestments = [];
      _isLastPage = false;
      _currentStatus = status;
      _currentSearchQuery = searchQuery;
    }

    if (!loadMore) {
      state = const AsyncValue.loading();
    }

    try {
      final Map<String, dynamic> queryParams = {
        'page': _currentPage,
        'per_page': pageSize,
        if (status != null && status.isNotEmpty) 'status': status,
        if (searchQuery != null && searchQuery.isNotEmpty) 'search': searchQuery,
      };

      final response = await _dio.get(
          '/soundhive-vests/active',
          queryParameters: queryParams,
          options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
              }
          )
      );

      final result = ActiveVestResponse.fromMap(response.data);
      final newInvestments = result.data.data;

      if (loadMore) {
        _allInvestments.addAll(newInvestments);
      } else {
        _allInvestments = newInvestments;
      }

      // Update state with the complete list
      state = AsyncValue.data(ActiveVestResponse(
        status: result.status,
        data: PaginatedActiveInvestmentData(
          currentPage: result.data.currentPage,
          data: _allInvestments,
          firstPageUrl: result.data.firstPageUrl,
          from: result.data.from,
          lastPage: result.data.lastPage,
          lastPageUrl: result.data.lastPageUrl,
          links: result.data.links,
          nextPageUrl: result.data.nextPageUrl,
          path: result.data.path,
          perPage: result.data.perPage,
          prevPageUrl: result.data.prevPageUrl,
          to: result.data.to,
          total: result.data.total,
        ),
      ));

      // Check if we've reached the last page
      _isLastPage = result.data.nextPageUrl == null || newInvestments.isEmpty;

      if (!_isLastPage) {
        _currentPage++;
      }

    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadMore() async {
    if (!_isLastPage && !state.isLoading) {
      await getActiveVest(loadMore: true);
    }
  }

  Future<void> refresh() async {
    await getActiveVest(loadMore: false);
  }

  Future<void> filterByStatus(String status) async {
    await getActiveVest(status: status);
  }

  Future<void> searchInvestments(String query) async {
    await getActiveVest(searchQuery: query);
  }
}