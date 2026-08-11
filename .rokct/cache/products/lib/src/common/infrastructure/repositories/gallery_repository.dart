// Copyright (c) 2024 RokctAI
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/domain/interface/gallery.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/enums.dart';

class GalleryRepository implements GalleryRepositoryFacade {
  @override
  Future<ApiResult<GalleryUploadResponse>> uploadImage(
    String file,
    UploadType uploadType,
  ) async {
    String docType = 'User';
    String docName = 'Profile';
    switch (uploadType) {
      case UploadType.extras:
        docType = 'Extra';
        docName = 'Extra';
        break;
      case UploadType.brands:
        docType = 'Brand';
        docName = 'Brand';
        break;
      case UploadType.categories:
        docType = 'Category';
        docName = 'Category';
        break;
      case UploadType.shopsLogo:
        docType = 'Shop';
        docName = 'Logo';
        break;
      case UploadType.shopsBack:
        docType = 'Shop';
        docName = 'Background';
        break;
      case UploadType.products:
        docType = 'Product';
        docName = 'Product';
        break;
      case UploadType.reviews:
        docType = 'Review';
        docName = 'Review';
        break;
      case UploadType.users:
        docType = 'User';
        docName = 'Profile';
        break;
    }
    final data = FormData.fromMap({
      'file': await MultipartFile.fromFile(file),
      'doctype': docType,
      'docname': docName,
      'is_private': 0,
    });
    try {
      final client = dioHttp.client(requireAuth: true);
      // NOTE: Using Frappe's standard file upload method
      final response = await client.post('/api/method/upload_file', data: data);
      // The response will contain the file URL, which needs to be saved
      // to the appropriate document in a separate API call.
      return ApiResult.success(
        data: GalleryUploadResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> upload image failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  // NOTE: The `uploadMultiImage` method is no longer needed, as multiple
  // images can be uploaded by calling `uploadImage` multiple times.
  @override
  Future<ApiResult<MultiGalleryUploadResponse>> uploadMultiImage(
    List<String?> filePaths,
    UploadType uploadType,
  ) async {
    List<String> uploadedImages = [];
    for (var path in filePaths) {
      if (path != null) {
        final res = await uploadImage(path, uploadType);
        res.when(
          success: (data) {
            if (data.imageData?.title != null) {
              uploadedImages.add(data.imageData!.title!);
            }
          },
          failure: (error, statusCode) {
            debugPrint('==> upload multi image failure: $error');
          },
        );
      }
    }
    return ApiResult.success(
      data: MultiGalleryUploadResponse(
        data: MultiGalleryUploadData(title: uploadedImages),
      ),
    );
  }
}
