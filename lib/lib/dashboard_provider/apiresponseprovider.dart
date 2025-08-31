

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../model/apiresponse_model.dart';
import '../../model/bvn_response_model.dart';
import '../../services/loader_service.dart';
import '../provider.dart';

final apiresponseProvider = StateNotifierProvider<ApiResponseProvider, AsyncValue<void>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return ApiResponseProvider(dio, storage);
});

class ApiResponseProvider extends StateNotifier<AsyncValue<void>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  ApiResponseProvider(this._dio, this._storage) : super(const AsyncValue.loading());

  Future<ApiResponseModel> joinInvestment({
    required BuildContext context,
    required Map<dynamic, dynamic> payload
  }) async {
    state = const AsyncValue.loading();
    try {
      LoaderService.showLoader(context);
      final response = await _dio.post(
        '/soundhive-vests/buy',
        data: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        state = const AsyncValue.data(null);
        return ApiResponseModel.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Something went wrong');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Let the caller handle the error
    } finally {
      LoaderService.hideLoader(context);
    }
  }

  Future<ApiResponseModel> buyAsset({
    required BuildContext context,
    required String hiveAssetId,
    bool saveBeneficiary = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      LoaderService.showLoader(context);
      final response = await _dio.post(
        '/member/marketplace/purchase',
        data: jsonEncode({
          'hive_asset_id': hiveAssetId,
        }),
      );

      if (response.statusCode == 200) {
        state = const AsyncValue.data(null);
        return ApiResponseModel.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Something went wrong');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Let the caller handle the error
    } finally {
      LoaderService.hideLoader(context);
    }
  }

  Future<ApiResponseModel> buyServices({
    required BuildContext context,
    required Map<dynamic, dynamic> payload
  }) async {
    state = const AsyncValue.loading();
    try {
      LoaderService.showLoader(context);
      final response = await _dio.post(
        '/service/payment',
        data: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        state = const AsyncValue.data(null);
        return ApiResponseModel.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Something went wrong');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Let the caller handle the error
    } finally {
      LoaderService.hideLoader(context);
    }
  }

  Future<ApiResponseModel> initiateDispute({
    required BuildContext context,
    required Map<dynamic, dynamic> payload
  }) async {
    state = const AsyncValue.loading();
    try {
      LoaderService.showLoader(context);
      final response = await _dio.post(
        '/dispute/initiate',
        data: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        state = const AsyncValue.data(null);
        return ApiResponseModel.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Something went wrong');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Let the caller handle the error
    } finally {
      LoaderService.hideLoader(context);
    }
  }
  Future<ApiResponseModel> cancelDispute({
    required BuildContext context,
    required int bookingId,
    required Map<dynamic, dynamic> payload
  }) async {
    state = const AsyncValue.loading();
    try {
      LoaderService.showLoader(context);
      final response = await _dio.post(
        '/dispute/close/$bookingId',
        data: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        state = const AsyncValue.data(null);
        return ApiResponseModel.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Something went wrong');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Let the caller handle the error
    } finally {
      LoaderService.hideLoader(context);
    }
  }
  Future<ApiResponseModel> markAsCompleted({
    required BuildContext context,
    required int memberServiceId,
  }) async {
    state = const AsyncValue.loading();
    try {
      LoaderService.showLoader(context);
      final response = await _dio.post(
        '/service/booking/$memberServiceId',
      );

      if (response.statusCode == 200) {
        state = const AsyncValue.data(null);
        return ApiResponseModel.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Something went wrong');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Let the caller handle the error
    } finally {
      LoaderService.hideLoader(context);
    }
  }
  Future<ApiResponseModel> addAssets({
    required BuildContext context,
    required String assetType,
    required String assetName,
    required String assetDescription,
    required String assetUrl,
    required String image,
    required double amount,
  }) async {
    state = const AsyncValue.loading();
    try {
      LoaderService.showLoader(context);
      final formData = FormData.fromMap({
        'asset_type': assetType,
        'asset_name': assetName,
        'asset_description': assetDescription,
        'asset_url': assetUrl,
        'price': amount,
        'image_url': image,
      });
      final response = await _dio.post(
          '/member/hive-assets/create',
          data: formData
      );

      if (response.statusCode == 200) {
        state = const AsyncValue.data(null); // line or error
        return ApiResponseModel.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Something went wrong');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Let the caller handle the error
    } finally {
      LoaderService.hideLoader(context);
    }
  }

  Future<ApiResponseModel> verifyIdentity({
    required BuildContext context,
   required Map<String, dynamic> payload
  }) async {
    state = const AsyncValue.loading();
    try {
      LoaderService.showLoader(context);
      final formData = jsonEncode(payload);
      final response = await _dio.post(
          '/verify/identity',
          data: formData
      );

      if (response.statusCode == 200) {
        state = const AsyncValue.data(null); // line or error
        return ApiResponseModel.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Something went wrong');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Let the caller handle the error
    } finally {
      LoaderService.hideLoader(context);
    }
  }


  Future<BvnResponseModel> sendIdVerification({
    required BuildContext context,
    required Map<String, dynamic> payload
  }) async {
    state = const AsyncValue.loading();
    try {
      LoaderService.showLoader(context);
      final formData = jsonEncode(payload);
      final response = await _dio.post(
          '/bvn/initiate',
          data: formData
      );

      if (response.statusCode == 200) {
        state = const AsyncValue.data(null);
        return BvnResponseModel.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Something went wrong');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Let the caller handle the error
    } finally {
      LoaderService.hideLoader(context);
    }
  }

  Future<ApiResponseModel> verifyId({
    required BuildContext context,
    required Map<String, dynamic> payload
  }) async {
    state = const AsyncValue.loading();
    try {
      LoaderService.showLoader(context);
      final formData = jsonEncode(payload);
      final response = await _dio.post(
          '/member/idverify/validate-verification',
          data: formData
      );

      if (response.statusCode == 200) {
        state = const AsyncValue.data(null); // line or error
        return ApiResponseModel.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Something went wrong');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Let the caller handle the error
    } finally {
      LoaderService.hideLoader(context);
    }
  }

  Future<ApiResponseModel> generateAccount({ required BuildContext context,}) async {
    state = const AsyncValue.loading();
    try {
      LoaderService.showLoader(context);
      final response = await _dio.post(
          '/generate/account'
      );

      if (response.statusCode == 200) {
        state = const AsyncValue.data(null);
        return ApiResponseModel.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Something went wrong');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Let the caller handle the error
    } finally {
      LoaderService.hideLoader(context);
    }
  }

  Future<ApiResponseModel> createCreativeProfile({
    required BuildContext context,
    required Map<String, dynamic> payload
  }) async {
    state = const AsyncValue.loading();
    try {
      // LoaderService.showLoader(context);
      final formData = jsonEncode(payload);
      final response = await _dio.post(
          '/creative/profile',
          data: formData
      );

      if (response.statusCode == 200) {
        state = const AsyncValue.data(null); // line or error
        return ApiResponseModel.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Something went wrong');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Let the caller handle the error
    } finally {
      // LoaderService.hideLoader(context);
    }
  }

  Future<ApiResponseModel> editJobTitle({
    required BuildContext context,
    required Map<String, dynamic> payload
  }) async {
    state = const AsyncValue.loading();
    try {
      LoaderService.showLoader(context);
      final formData = jsonEncode(payload);
      final response = await _dio.post(
          '/update/job-title',
          data: formData
      );

      if (response.statusCode == 200) {
        state = const AsyncValue.data(null); // line or error
        return ApiResponseModel.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Something went wrong');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Let the caller handle the error
    } finally {
      LoaderService.hideLoader(context);
    }
  }

  Future<ApiResponseModel> editDescription({
    required BuildContext context,
    required Map<String, dynamic> payload
  }) async {
    state = const AsyncValue.loading();
    try {
      LoaderService.showLoader(context);
      final formData = jsonEncode(payload);
      final response = await _dio.post(
          '/update/bio',
          data: formData
      );

      if (response.statusCode == 200) {
        state = const AsyncValue.data(null); // line or error
        return ApiResponseModel.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Something went wrong');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Let the caller handle the error
    } finally {
      LoaderService.hideLoader(context);
    }
  }

  Future<ApiResponseModel> editSocials({
    required BuildContext context,
    required Map<String, dynamic> payload
  }) async {
    state = const AsyncValue.loading();
    try {
      LoaderService.showLoader(context);
      final formData = jsonEncode(payload);
      final response = await _dio.post(
          '/update/socials',
          data: formData
      );

      if (response.statusCode == 200) {
        state = const AsyncValue.data(null); // line or error
        return ApiResponseModel.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Something went wrong');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Let the caller handle the error
    } finally {
      LoaderService.hideLoader(context);
    }
  }

  Future<ApiResponseModel> updateProfile({
    required BuildContext context,
    required Map<String, dynamic> payload
  }) async {
    state = const AsyncValue.loading();
    try {
      LoaderService.showLoader(context);
      final formData = jsonEncode(payload);
      final response = await _dio.post(
          '/update/image',
          data: formData
      );

      if (response.statusCode == 200) {
        state = const AsyncValue.data(null);
        return ApiResponseModel.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Something went wrong');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    } finally {
      LoaderService.hideLoader(context);
    }
  }

  Future<ApiResponseModel> createService({
    required Map<String, dynamic> payload
  }) async {
    state = const AsyncValue.loading();
    try {
      // LoaderService.showLoader(context);
      final formData = jsonEncode(payload);
      final response = await _dio.post(
          '/create-service',
          data: formData
      );

      if (response.statusCode == 200) {
        state = const AsyncValue.data(null); // line or error
        return ApiResponseModel.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Something went wrong');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Let the caller handle the error
    } finally {
      // LoaderService.hideLoader(context);
    }
  }

  Future<ApiResponseModel> addService({
    required BuildContext context,
    required String serviceType,
    required String category,
    required String workType,
    required List<String> availableToWork,
    required double price,
    required String serviceDescription,
    required String imageUrl,
    required String portfolio,
  }) async {
    state = const AsyncValue.loading();
    try {
      LoaderService.showLoader(context);
      final formData = FormData.fromMap({
        'service_type': serviceType,
        'category': category,
        'work_type': workType,
        'price': price,
        'available_to_work[]': availableToWork,
        'service_description': serviceDescription,
        'image_url': imageUrl,
        'portfolio': portfolio
      });
      final response = await _dio.post(
          '/member/hive-services/create',
          data: formData
      );

      if (response.statusCode == 200) {
        state = const AsyncValue.data(null); // line or error
        return ApiResponseModel.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Something went wrong');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Let the caller handle the error
    } finally {
      LoaderService.hideLoader(context);
    }
  }

  Future<void> logout({
    required BuildContext context,
  }) async {
    state = const AsyncValue.loading();
    try {
      LoaderService.showLoader(context);
      await _storage.deleteAll();
      await Future.delayed(const Duration(milliseconds: 500));
      Map<String, String> allData = await _storage.readAll();
      print("Storage After Delete: $allData");

    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    } finally {
      LoaderService.hideLoader(context);
    }
  }

}