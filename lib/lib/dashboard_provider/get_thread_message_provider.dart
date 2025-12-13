import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../model/ai_conversation_thread_model.dart';
import '../../model/artist_profile_id_model.dart';
import '../provider.dart';

final getThreadMessageProvider = StateNotifierProvider<GetThreadMessageNotifier, AsyncValue<ConversationSingleThreadResponse>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return GetThreadMessageNotifier(dio, storage);
});

class GetThreadMessageNotifier extends StateNotifier<AsyncValue<ConversationSingleThreadResponse>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  int _currentPage = 1;

  GetThreadMessageNotifier(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<void> getThreadMessage({required int id, bool append = false,}) async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
          '/ai-workflow/conversations/$id',
          options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
              }
          )
      );
      final newResponse = ConversationSingleThreadResponse.fromMap(response.data);

      if (append && state.hasValue) {
        final oldData = state.value!;
        final combined = ConversationSingleThreadResponse(
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
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}