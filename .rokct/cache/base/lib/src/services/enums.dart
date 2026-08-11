enum ShopStatus { notRequested, newShop, edited, approved, rejected }

enum UploadType {
  extras,
  brands,
  categories,
  shopsLogo,
  shopsBack,
  products,
  reviews,
  users,
}

enum PriceFilter { byLow, byHigh }

enum ListAlignment { singleBig, vertically, horizontally }

enum ExtrasType { color, text, image }

enum DeliveryTypeEnum { delivery, pickup, pickupPoint }

enum ShippingDeliveryVisibilityType {
  cantOrder,
  onlyDelivery,
  onlyPickup,
  both,
}

enum OrderStatus { open, accepted, ready, onWay, delivered, canceled }

enum CouponType { fix, percent }

enum MessageOwner { you, partner }

enum BannerType { banner, look }

enum LookProductStockStatus { outOfStock, alreadyAdded, notAdded }

enum SignUpType { phone, email, both }

// Enums for payment methods
enum PaymentMethodType { directCard, savedCard }

/// Model types the AI translation endpoint accepts (`model_type` field).
///
/// agent_sdk's AiTranslationRequest referenced this from the retired
/// core_sdk's enums, where it was never actually defined (phantom import);
/// defined here during the 2026-07-11 refork so the feature compiles. Values
/// mirror the backend's translatable entity names.
enum AiTranslationModel {
  product('product'),
  category('category'),
  shop('shop'),
  brand('brand');

  const AiTranslationModel(this.type);

  final String type;
}
