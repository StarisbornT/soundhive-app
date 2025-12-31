import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/model/event_model.dart';
import '../../model/ticket_model.dart';
import '../provider.dart';
final getMyTicketProvider = StateNotifierProvider<GetMyTicketNotifier, AsyncValue<TicketModel>>((ref) {
  final dio = ref.watch(dioProvider);
  return GetMyTicketNotifier(dio);
});

class GetMyTicketNotifier extends StateNotifier<AsyncValue<TicketModel>> {
  final Dio _dio;

  List<TicketItem> _allServices = [];
  int _currentPage = 1;
  bool _isLastPage = false;
  bool _isLoadingMore = false;

  bool get isLastPage => _isLastPage;
  bool get isLoadingMore => _isLoadingMore;
  List<TicketItem> get allServices => _allServices;

  GetMyTicketNotifier(this._dio)
      : super(const AsyncValue.loading());

  Future<void> getMyTicket({
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
        '/events/ticket/user',
        queryParameters: {
          'page': _currentPage,
          'per_page': pageSize,
        },
        options: Options(headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
      );

      final result = TicketModel.fromMap(response.data);
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
  Future<void> getRegistration({
    bool loadMore = false,
    int? pageSize,
    required eventId
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
        '/events/ticket/reg/$eventId',
        queryParameters: {
          'page': _currentPage,
          'per_page': pageSize,
        },
        options: Options(headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
      );

      final result = TicketModel.fromMap(response.data);
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
