import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../model/category_model.dart';
import '../../model/creator_model.dart';
import '../provider.dart';
final creatorProvider = StateNotifierProvider<CreatorNotifier, AsyncValue<CreatorListResponse>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return CreatorNotifier(dio, storage);
});

class CreatorNotifier extends StateNotifier<AsyncValue<CreatorListResponse>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  int _currentPage = 1;
  bool _isFetching = false;

  CreatorNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<void> getCreator({int page = 1, bool append = false}) async {
    if (_isFetching) return; // prevent double-calls
    _isFetching = true;

    try {
      final response = await _dio.get(
        '/creators?page=$page',
        options: Options(headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
      );

      final newResponse = CreatorListResponse.fromMap(response.data);

      if (append && state.hasValue) {
        final oldData = state.value!;
        final combined = CreatorListResponse(
          message: newResponse.message,
          user: oldData.user != null && newResponse.user != null
              ? CreatorPaginatedData(
            currentPage: newResponse.user!.currentPage,
            data: [...oldData.user!.data, ...newResponse.user!.data],
            firstPageUrl: newResponse.user!.firstPageUrl,
            from: newResponse.user!.from,
            lastPage: newResponse.user!.lastPage,
            lastPageUrl: newResponse.user!.lastPageUrl,
            links: newResponse.user!.links,
            nextPageUrl: newResponse.user!.nextPageUrl,
            path: newResponse.user!.path,
            perPage: newResponse.user!.perPage,
            prevPageUrl: newResponse.user!.prevPageUrl,
            to: newResponse.user!.to,
            total: newResponse.user!.total,
          )
              : newResponse.user,
        );
        state = AsyncValue.data(combined);
      } else {
        state = AsyncValue.data(newResponse);
      }

      _currentPage = newResponse.user?.currentPage ?? 1;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    } finally {
      _isFetching = false;
    }
  }

  Future<void> loadNextPage() async {
    final nextPage = _currentPage + 1;
    if (state.hasValue &&
        nextPage <= (state.value?.user?.lastPage ?? 1)) {
      await getCreator(page: nextPage, append: true);
    }
  }
}

