import 'package:base_sdk/src/models/response/languages_response.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_gallery.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';

/// Plain immutable state (no freezed) — same reason as the stage 2 states.
class EditFoodDetailsState {
  const EditFoodDetailsState({
    this.isLoading = false,
    this.active = false,
    this.title = '',
    this.interval = '',
    this.description = '',
    this.minQty = '',
    this.maxQty = '',
    this.tax = '',
    this.costPrice = '',
    this.barcode = '',
    this.product,
    this.images = const [],
    this.listOfUrls = const [],
    this.mapOfDesc = const {},
    this.language,
    this.error,
  });

  final bool isLoading;
  final bool active;
  final String title;
  final String interval;
  final String description;
  final String minQty;
  final String maxQty;
  final String tax;

  /// Manager-only cost price; empty means "not provided" and the update
  /// request omits the field (leaving the stored value untouched).
  final String costPrice;
  final String barcode;
  final SellerProductData? product;

  /// Local file paths picked but not yet uploaded.
  final List<String> images;

  /// Already-uploaded gallery entries.
  final List<SellerGallery> listOfUrls;

  /// Locale -> `[title, description]`, one entry per authored language.
  final Map<String, List<String>> mapOfDesc;
  final LanguageData? language;

  /// Set on a failed upload or update; the page decides how to show it.
  final String? error;

  EditFoodDetailsState copyWith({
    bool? isLoading,
    bool? active,
    String? title,
    String? interval,
    String? description,
    String? minQty,
    String? maxQty,
    String? tax,
    String? costPrice,
    String? barcode,
    SellerProductData? product,
    List<String>? images,
    List<SellerGallery>? listOfUrls,
    Map<String, List<String>>? mapOfDesc,
    LanguageData? language,
    String? error,
  }) =>
      EditFoodDetailsState(
        isLoading: isLoading ?? this.isLoading,
        active: active ?? this.active,
        title: title ?? this.title,
        interval: interval ?? this.interval,
        description: description ?? this.description,
        minQty: minQty ?? this.minQty,
        maxQty: maxQty ?? this.maxQty,
        tax: tax ?? this.tax,
        costPrice: costPrice ?? this.costPrice,
        barcode: barcode ?? this.barcode,
        product: product ?? this.product,
        images: images ?? this.images,
        listOfUrls: listOfUrls ?? this.listOfUrls,
        mapOfDesc: mapOfDesc ?? this.mapOfDesc,
        language: language ?? this.language,
        error: error,
      );
}
