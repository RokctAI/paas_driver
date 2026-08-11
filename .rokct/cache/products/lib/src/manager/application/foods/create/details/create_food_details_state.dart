import 'package:products_sdk/src/common/infrastructure/models/data/seller_gallery.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';

/// Plain immutable state (no freezed) — same reason as the stage 2 states.
class CreateFoodDetailsState {
  const CreateFoodDetailsState({
    this.title = '',
    this.description = '',
    this.tax = '',
    this.minQty = '',
    this.maxQty = '',
    this.qrcode = '',
    this.interval = '',
    this.active = true,
    this.isCreating = false,
    this.images = const [],
    this.listOfUrls = const [],
    this.createdProduct,
    this.error,
  });

  final String title;
  final String description;
  final String tax;
  final String minQty;
  final String maxQty;
  final String qrcode;
  final String interval;
  final bool active;
  final bool isCreating;

  /// Local file paths picked but not yet uploaded.
  final List<String> images;

  /// Already-uploaded gallery entries.
  final List<SellerGallery> listOfUrls;
  final SellerProductData? createdProduct;

  /// Set on a failed upload or create; the page decides how to show it. The
  /// app raised a snackbar from inside the notifier.
  final String? error;

  /// [createdProduct] is nullable-through: passing null clears it (the app's
  /// freezed copyWith did the same on `updateAddFoodInfo`). [error] clears
  /// unless passed, per the stage 2 convention.
  CreateFoodDetailsState copyWith({
    String? title,
    String? description,
    String? tax,
    String? minQty,
    String? maxQty,
    String? qrcode,
    String? interval,
    bool? active,
    bool? isCreating,
    List<String>? images,
    List<SellerGallery>? listOfUrls,
    SellerProductData? createdProduct,
    bool clearCreatedProduct = false,
    String? error,
  }) =>
      CreateFoodDetailsState(
        title: title ?? this.title,
        description: description ?? this.description,
        tax: tax ?? this.tax,
        minQty: minQty ?? this.minQty,
        maxQty: maxQty ?? this.maxQty,
        qrcode: qrcode ?? this.qrcode,
        interval: interval ?? this.interval,
        active: active ?? this.active,
        isCreating: isCreating ?? this.isCreating,
        images: images ?? this.images,
        listOfUrls: listOfUrls ?? this.listOfUrls,
        createdProduct:
            clearCreatedProduct ? null : (createdProduct ?? this.createdProduct),
        error: error,
      );
}
