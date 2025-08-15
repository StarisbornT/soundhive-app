

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../model/apiresponse_model.dart';
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
    required String investmentId,
    required double amount,
    bool saveBeneficiary = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      LoaderService.showLoader(context);
      final response = await _dio.post(
        '/member/investment/join',
        data: jsonEncode({
          'investment_id': investmentId,
          'amount': amount,
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
        '/member/service/purchase',
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
    required String memberServiceId,
  }) async {
    state = const AsyncValue.loading();
    try {
      LoaderService.showLoader(context);
      final response = await _dio.post(
        '/member/service/purchase/mark-as-completed/$memberServiceId',
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
          '/member/creator/create',
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

  Future<ApiResponseModel> sendIdVerification({
    required BuildContext context,
    required Map<String, dynamic> payload
  }) async {
    state = const AsyncValue.loading();
    try {
      LoaderService.showLoader(context);
      final formData = jsonEncode(payload);
      final response = await _dio.post(
          '/member/idverify/create',
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
          '/member/account/generate'
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

  Future<ApiResponseModel> createCreativeProfile({
    required BuildContext context,
    required Map<String, dynamic> payload
  }) async {
    state = const AsyncValue.loading();
    try {
      // LoaderService.showLoader(context);
      final formData = jsonEncode(payload);
      final response = await _dio.post(
          '/member/creator/setup-creative-profile',
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
          '/member/creator/updates/jobtitle',
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
          '/member/creator/updates/jobdescription',
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
          '/member/creator/updates/job-social',
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
          '/member/creator/updates/update-profile',
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
          '/member/service/create',
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



}