import 'package:flutter/material.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/domain/interface/gallery.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_gallery.dart';
import 'package:products_sdk/src/manager/application/foods/create/details/create_food_details_state.dart';
import 'package:products_sdk/src/manager/application/seller_product_requests.dart';

/// Port of `paas_manager`'s `CreateFoodDetailsNotifier` — the create-product
/// form: text fields, image picking/upload, and the create call.
///
/// Departures, both per stage 2 conventions:
/// - no `BuildContext`/snackbars — failures surface as `state.error`;
/// - the request map is built here (`buildCreateProductRequest`) because the
///   facade takes a ready map where the app repository took typed params.
///
/// `kitchenId` stays a plain int: kitchens live in kitchen_sdk and ADR-005
/// forbids importing it, so the page passes only the picked id through.
class CreateFoodDetailsNotifier extends StateNotifier<CreateFoodDetailsState> {
  CreateFoodDetailsNotifier(this._repository, this._galleryRepository)
      : super(const CreateFoodDetailsState());

  final SellerProductsRepositoryFacade _repository;
  final GalleryRepositoryFacade _galleryRepository;

  void updateAddFoodInfo() {
    state = state.copyWith(
      images: [],
      listOfUrls: [],
      title: '',
      description: '',
      minQty: '',
      maxQty: '',
      tax: '',
      costPrice: '',
      qrcode: '',
      active: false,
      clearCreatedProduct: true,
    );
  }

  Future<void> createProduct({
    int? categoryId,
    int? unitId,
    int? kitchenId,
    VoidCallback? created,
    VoidCallback? onError,
  }) async {
    state = state.copyWith(isCreating: true);
    final List<String> imageUrl =
        List.from(state.listOfUrls.map((e) => e.path));
    if (state.images.isNotEmpty) {
      final imageResponse = await _galleryRepository.uploadMultiImage(
        state.images,
        UploadType.products,
      );
      imageResponse.when(
        success: (data) {
          imageUrl.addAll(data.data?.title ?? []);
        },
        failure: (failure, status) {
          debugPrint('==> upload product image fail: $failure');
          state = state.copyWith(isCreating: true, error: failure);
        },
      );
    }
    final response = await _repository.createProduct(
      product: buildCreateProductRequest(
        title: state.title,
        description: state.description,
        tax: state.tax,
        costPrice: state.costPrice,
        minQty: state.minQty,
        maxQty: state.maxQty,
        active: state.active,
        qrcode: state.qrcode,
        interval: state.interval,
        categoryId: categoryId,
        unitId: unitId,
        kitchenId: kitchenId,
        images: imageUrl,
      ),
    );
    response.when(
      success: (data) {
        state = state.copyWith(isCreating: false, createdProduct: data.data);
        created?.call();
      },
      failure: (fail, status) {
        debugPrint('===> create product fail $fail');
        state = state.copyWith(isCreating: false, error: fail);
        onError?.call();
      },
    );
  }

  void setQrcode(String value) {
    state = state.copyWith(qrcode: value.trim());
  }

  void setActive(bool? value) {
    state = state.copyWith(active: !state.active);
  }

  void setMaxQty(String value) {
    state = state.copyWith(maxQty: value.trim());
  }

  void setMinQty(String value) {
    state = state.copyWith(minQty: value.trim());
  }

  void setTax(String value) {
    state = state.copyWith(tax: value.trim());
  }

  void setCostPrice(String value) {
    state = state.copyWith(costPrice: value.trim());
  }

  void setDescription(String value) {
    state = state.copyWith(description: value.trim());
  }

  void setTitle(String value) {
    state = state.copyWith(title: value.trim());
  }

  void setInterval(String value) {
    state = state.copyWith(interval: value.trim());
  }

  void setImageFile(String file) {
    final List<String> list = List.from(state.images)..add(file);
    state = state.copyWith(images: list);
  }

  void setUploadImage(SellerGallery gallery) {
    final List<SellerGallery> list = List.from(state.listOfUrls)
      ..insert(0, gallery);
    state = state.copyWith(listOfUrls: list);
  }

  void deleteImage(String value) {
    final List<String> list = List.from(state.images)..remove(value);
    final List<SellerGallery> urls = List.from(state.listOfUrls)
      ..removeWhere((element) => element.path == value);
    state = state.copyWith(images: list, listOfUrls: urls);
  }
}
