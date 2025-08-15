import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:soundhive2/model/asset_model.dart';

import '../../services/loader_service.dart';
import '../provider.dart';
final assetsProvider = StateNotifierProvider<AssetsNotifier, AsyncValue<AssetResponse>>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return AssetsNotifier(dio, storage);
});

class AssetsNotifier extends StateNotifier<AsyncValue<AssetResponse>> {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  int _currentPage = 1;
  int _totalPages = 1;
  String currentStatus = '';
  List<Asset> _allAssets = [];



  AssetsNotifier(this._dio, this._storage) : super(const AsyncValue.loading());
  List<Asset> get allAssets => _allAssets;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  Future<void> getAssets(String status) async {
    state = const AsyncValue.loading();
    _allAssets.clear();  // Clear the existing assets before fetching new ones

    try {
      final response = await _dio.get(
        '/member/hive-assets/member-list',
        queryParameters: {'status': status},
      );

      final assetResponse = AssetResponse.fromMap(response.data);
      currentStatus = status;
      _allAssets.addAll(assetResponse.data);  // Directly add assets

      // Update the state with the data (since no pagination is used)
      state = AsyncValue.data(AssetResponse(
        message: assetResponse.message,
        data: _allAssets,  // Directly use the list of assets (no pagination object)
        statuses: assetResponse.statuses,
      ));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<AssetResponse> addAssets({
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
        final responseData = AssetResponse.fromJson(response.data);
        state = AsyncValue.data(responseData);
        return responseData;
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