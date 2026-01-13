import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../model/transaction_history_model.dart';
import '../provider.dart';

final getTransactionHistoryPlaceProvider = StateNotifierProvider<
    GetTransactionHistoryNotifier,
    AsyncValue<TransactionHistoryResponse>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return GetTransactionHistoryNotifier(dio, storage);
});

class GetTransactionHistoryNotifier
    extends StateNotifier<AsyncValue<TransactionHistoryResponse>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  // Track current page and total pages
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  // Store all loaded transactions
  final List<Transaction> _allTransactions = [];

  GetTransactionHistoryNotifier(this._dio, this._storage)
      : super(const AsyncValue.loading());

  // Reset to initial state
  Future<void> refresh() async {
    _currentPage = 1;
    _totalPages = 1;
    _hasMore = true;
    _allTransactions.clear();
    await getTransactionHistory();
  }

  // Load more data
  Future<void> loadMore() async {
    if (_currentPage < _totalPages && _hasMore) {
      _currentPage++;
      await getTransactionHistory(loadMore: true);
    }
  }

  // Check if there are more pages to load
  bool get hasMore => _currentPage < _totalPages && _hasMore;

  Future<void> getTransactionHistory({bool loadMore = false}) async {
    if (!loadMore) {
      state = const AsyncValue.loading();
    }

    try {
      final response = await _dio.get(
        '/transactions',
        queryParameters: {'page': _currentPage},
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      final serviceResponse = TransactionHistoryResponse.fromMap(response.data);
      final paginationData = serviceResponse.data;

      // Update total pages
      _totalPages = paginationData.lastPage;
      _hasMore = paginationData.nextPageUrl != null;

      if (loadMore) {
        // Append new data
        _allTransactions.addAll(paginationData.data);

        // Create updated response with all transactions
        final updatedResponse = TransactionHistoryResponse(
          success: serviceResponse.success,
          message: serviceResponse.message,
          data: TransactionPagination(
            currentPage: _currentPage,
            data: List.from(_allTransactions),
            firstPageUrl: paginationData.firstPageUrl,
            from: _allTransactions.isEmpty ? null : 1,
            lastPage: _totalPages,
            lastPageUrl: paginationData.lastPageUrl,
            links: paginationData.links,
            nextPageUrl: paginationData.nextPageUrl,
            path: paginationData.path,
            perPage: paginationData.perPage,
            prevPageUrl: paginationData.prevPageUrl,
            to: paginationData.to,
            total: paginationData.total,
          ),
        );

        state = AsyncValue.data(updatedResponse);
      } else {
        // First load
        _allTransactions.clear();
        _allTransactions.addAll(paginationData.data);
        state = AsyncValue.data(serviceResponse);
      }
    } catch (error, stackTrace) {
      if (loadMore) {
        // If load more fails, revert the page
        _currentPage--;
      }
      state = AsyncValue.error(error, stackTrace);
    }
  }
}