import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../model/ai_conversation_thread_model.dart';
import '../../model/category_model.dart';
import '../../model/creator_model.dart';
import '../provider.dart';
final getConversationProvider = StateNotifierProvider<GetConversationsNotifier, AsyncValue<ConversationThreadResponse>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return GetConversationsNotifier(dio, storage);
});

class GetConversationsNotifier extends StateNotifier<AsyncValue<ConversationThreadResponse>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  int _currentPage = 1;
  bool _isFetching = false;
  String _currentSearch = '';

  GetConversationsNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<void> getConversations({int page = 1, bool append = false, String search = ''}) async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      final Map<String, dynamic> queryParams = {'page': page};
      if (search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _dio.get(
        '/ai-workflow/conversations',
        queryParameters: queryParams,
        options: Options(headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
      );

      final newResponse = ConversationThreadResponse.fromMap(response.data);

      if (append && state.hasValue && search == _currentSearch) {
        final oldData = state.value!;
        final combined = ConversationThreadResponse(
          success: newResponse.success,
          message: newResponse.message,
          data: ConversationPaginatedData(
            currentPage: newResponse.data.currentPage,
            data: [...oldData.data.data, ...newResponse.data.data],
            firstPageUrl: newResponse.data.firstPageUrl,
            from: newResponse.data.from,
            lastPage: newResponse.data.lastPage,
            lastPageUrl: newResponse.data.lastPageUrl,
            links: newResponse.data.links,
            nextPageUrl: newResponse.data.nextPageUrl,
            path: newResponse.data.path,
            perPage: newResponse.data.perPage,
            prevPageUrl: newResponse.data.prevPageUrl,
            to: newResponse.data.to,
            total: newResponse.data.total,
          ),
        );
        state = AsyncValue.data(combined);
      } else {
        state = AsyncValue.data(newResponse);
      }

      _currentPage = newResponse.data.currentPage;
      _currentSearch = search;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    } finally {
      _isFetching = false;
    }
  }
  Future<void> searchConversations(String searchQuery) async {
    // Reset to first page when searching
    await getConversations(page: 1, search: searchQuery);
  }

  Future<void> loadNextPage() async {
    final nextPage = _currentPage + 1;
    if (state.hasValue &&
        nextPage <= (state.value?.data.lastPage ?? 1)) {
      await getConversations(page: nextPage, append: true, search: _currentSearch);
    }
  }

  void clearSearch() {
    _currentSearch = '';
    getConversations(page: 1);
  }
}

