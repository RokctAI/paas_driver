import 'package:driver/infrastructure/models/data/push_data.dart';

import 'product_data.dart';

class OrderDetailModel {
  OrderDetailData? data;

  OrderDetailModel({this.data});

  OrderDetailModel.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null ? OrderDetailData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class OrderDetailData {
  int? id;
  int? userId;
  num? totalPrice;
  num? rate;
  num? tax;
  num? serviceFee;
  num? originPrice;
  num? totalDiscount;
  num? commissionFee;
  num? couponPrice;
  String? status;
  Location? location;
  AddressModel? address;
  String? deliveryType;
  num? deliveryFee;
  num? otp;
  dynamic deliveryman;
  String? deliveryDate;
  String? deliveryTime;
  String? createdAt;
  String? note;
  String? afterDeliveredImage;
  bool? current;
  String? updatedAt;
  num? distance;
  Shop? shop;
  Currency? currency;
  User? user;
  List<Details>? details;
  Transaction? transaction;
  dynamic review;

  OrderDetailData({
    this.id,
    this.userId,
    this.totalPrice,
    this.serviceFee,
    this.originPrice,
    this.rate,
    this.tax,
    this.commissionFee,
    this.status,
    this.distance,
    this.note,
    this.location,
    this.address,
    this.current,
    this.afterDeliveredImage,
    this.deliveryType,
    this.deliveryFee,
    this.otp,
    this.deliveryman,
    this.deliveryDate,
    this.deliveryTime,
    this.createdAt,
    this.updatedAt,
    this.shop,
    this.currency,
    this.user,
    this.details,
    this.transaction,
    this.totalDiscount,
    this.couponPrice,
    this.review,
  });

  OrderDetailData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    totalPrice = json['total_price'];
    serviceFee = json['service_fee'];
    originPrice = json['origin_price'];
    rate = json['rate'];
    tax = json['tax'];
    couponPrice = json['coupon'] != null ? json['coupon']["price"] : null;
    totalDiscount = json['total_discount'];
    note = json['note'];
    afterDeliveredImage = json['image_after_delivered'];
    distance = json["km"];
    commissionFee = json['commission_fee'];
    status = json['status'];
    current = json["current"] == null
        ? false
        : ((json["current"].runtimeType == int)
              ? (json["current"] == 0 ? false : true)
              : json["current"]);
    location = json['location'] != null
        ? Location.fromJson(json['location'])
        : null;
    address = (json['address'] != null)
        ? AddressModel.fromJson(json['address'])
        : null;
    deliveryType = json['delivery_type'];
    deliveryFee = json['delivery_fee'];
    otp = json['otp'];
    deliveryman = json['deliveryman'];
    deliveryDate = json['delivery_date'];
    deliveryTime = json['delivery_time'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    shop = json['shop'] != null ? Shop.fromJson(json['shop']) : null;
    currency = json['currency'] != null
        ? Currency.fromJson(json['currency'])
        : null;
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    if (json['details'] != null) {
      details = <Details>[];
      json['details'].forEach((v) {
        details!.add(Details.fromJson(v));
      });
    }
    transaction = json['transaction'] != null
        ? Transaction.fromJson(json['transaction'])
        : null;
    review = json['review'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['service_fee'] = serviceFee;
    data['origin_price'] = originPrice;
    data['coupon_price'] = couponPrice;
    data['total_discount'] = totalDiscount;
    data['total_price'] = totalPrice;
    data['rate'] = rate;
    data['image_after_delivered'] = afterDeliveredImage;
    data['tax'] = tax;
    data['commission_fee'] = commissionFee;
    data['status'] = status;
    if (location != null) {
      data['location'] = location!.toJson();
    }
    data['address'] = address;
    data['delivery_type'] = deliveryType;
    data['delivery_fee'] = deliveryFee;
    data['otp'] = otp;
    data['deliveryman'] = deliveryman;
    data['delivery_date'] = deliveryDate;
    data['delivery_time'] = deliveryTime;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (shop != null) {
      data['shop'] = shop!.toJson();
    }
    if (currency != null) {
      data['currency'] = currency!.toJson();
    }
    if (user != null) {
      data['user'] = user!.toJson();
    }
    if (details != null) {
      data['details'] = details!.map((v) => v.toJson()).toList();
    }
    if (transaction != null) {
      data['transaction'] = transaction!.toJson();
    }
    data['review'] = review;
    return data;
  }
}

class Location {
  String? latitude;
  String? longitude;

  Location({this.latitude, this.longitude});

  Location.fromJson(Map<String, dynamic> json) {
    latitude = json['latitude'].toString();
    longitude = json['longitude'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    return data;
  }
}

class Shop {
  int? id;
  String? uuid;
  int? userId;
  num? price;
  num? pricePerKm;
  num? tax;
  num? percentage;
  String? phone;
  bool? visibility;
  String? backgroundImg;
  String? logoImg;
  num? minAmount;
  String? status;
  String? type;
  DeliveryTime? deliveryTime;
  String? createdAt;
  String? updatedAt;
  Location? location;
  int? productsCount;
  Translation? translation;
  List<String>? locales;

  Shop({
    this.id,
    this.uuid,
    this.userId,
    this.price,
    this.pricePerKm,
    this.tax,
    this.percentage,
    this.phone,
    this.visibility,
    this.backgroundImg,
    this.logoImg,
    this.minAmount,
    this.status,
    this.type,
    this.deliveryTime,
    this.createdAt,
    this.updatedAt,
    this.location,
    this.productsCount,
    this.translation,
    this.locales,
  });

  Shop.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uuid = json['uuid'];
    userId = json['user_id'];
    price = json['price'];
    pricePerKm = json['price_per_km'];
    tax = json['tax'];
    percentage = json['percentage'];
    phone = json['phone'];
    visibility = json['visibility'].runtimeType == int
        ? (json['visibility'] == 1)
        : json['visibility'];
    backgroundImg = json['background_img'];
    logoImg = json['logo_img'];
    minAmount = json['min_amount'];
    status = json['status'];
    type = json['type'].toString();
    deliveryTime = json['delivery_time'] != null
        ? DeliveryTime.fromJson(json['delivery_time'])
        : null;
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    location = json['location'] != null
        ? Location.fromJson(json['location'])
        : null;
    productsCount = json['products_count'];
    translation = json['translation'] != null
        ? Translation.fromJson(json['translation'])
        : null;
    locales = json['locales'] != null ? json['locales'].cast<String>() : [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['uuid'] = uuid;
    data['user_id'] = userId;
    data['price'] = price;
    data['price_per_km'] = pricePerKm;
    data['tax'] = tax;
    data['percentage'] = percentage;
    data['phone'] = phone;
    data['visibility'] = visibility;
    data['background_img'] = backgroundImg;
    data['logo_img'] = logoImg;
    data['min_amount'] = minAmount;
    data['status'] = status;
    data['type'] = type;
    if (deliveryTime != null) {
      data['delivery_time'] = deliveryTime!.toJson();
    }
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (location != null) {
      data['location'] = location!.toJson();
    }
    data['products_count'] = productsCount;
    if (translation != null) {
      data['translation'] = translation!.toJson();
    }
    data['locales'] = locales;
    return data;
  }
}

class DeliveryTime {
  String? to;
  String? from;
  String? type;

  DeliveryTime({this.to, this.from, this.type});

  DeliveryTime.fromJson(Map<String, dynamic> json) {
    to = json['to'].toString();
    from = json['from'].toString();
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['to'] = to;
    data['from'] = from;
    data['type'] = type;
    return data;
  }
}

class Translation {
  int? id;
  String? locale;
  String? title;
  String? description;
  String? address;

  Translation({
    this.id,
    this.locale,
    this.title,
    this.description,
    this.address,
  });

  Translation.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    locale = json['locale'];
    title = json['title'];
    description = json['description'];
    address = json['address'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['locale'] = locale;
    data['title'] = title;
    data['description'] = description;
    data['address'] = address;
    return data;
  }
}

class Currency {
  int? id;
  String? symbol;
  String? title;
  bool? active;

  Currency({this.id, this.symbol, this.title, this.active});

  Currency.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    symbol = json['symbol'];
    title = json['title'];
    active = json['active'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['symbol'] = symbol;
    data['title'] = title;
    data['active'] = active;
    return data;
  }
}

class User {
  int? id;
  String? uuid;
  String? firstname;
  String? lastname;
  String? email;
  String? phone;
  String? birthday;
  String? gender;
  bool? active;
  String? img;
  String? role;
  String? emailVerifiedAt;
  String? registeredAt;

  User({
    this.id,
    this.uuid,
    this.firstname,
    this.lastname,
    this.email,
    this.phone,
    this.birthday,
    this.gender,
    this.active,
    this.img,
    this.role,
    this.emailVerifiedAt,
    this.registeredAt,
  });

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uuid = json['uuid'];
    firstname = json['firstname'];
    lastname = json['lastname'];
    email = json['email'];
    phone = json['phone'];
    birthday = json['birthday'];
    gender = json['gender'];
    active = json['active'].runtimeType == int
        ? (json['active'] == 0 ? false : true)
        : json['active'];
    img = json['img'];
    role = json['role'];
    emailVerifiedAt = json['email_verified_at'];
    registeredAt = json['registered_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['uuid'] = uuid;
    data['firstname'] = firstname;
    data['lastname'] = lastname;
    data['email'] = email;
    data['phone'] = phone;
    data['birthday'] = birthday;
    data['gender'] = gender;
    data['active'] = active;
    data['img'] = img;
    data['role'] = role;
    data['email_verified_at'] = emailVerifiedAt;
    data['registered_at'] = registeredAt;
    return data;
  }
}

class Details {
  String? note;
  int? id;
  int? orderId;
  int? stockId;
  num? originPrice;
  num? totalPrice;
  num? tax;
  num? discount;
  int? quantity;
  bool? bonus;
  String? createdAt;
  String? updatedAt;
  Stock? stock;

  Details({
    this.id,
    this.orderId,
    this.stockId,
    this.originPrice,
    this.totalPrice,
    this.tax,
    this.discount,
    this.quantity,
    this.bonus,
    this.createdAt,
    this.updatedAt,
    this.stock,
    this.note,
  });

  Details.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    orderId = json['order_id'];
    stockId = json['stock_id'];
    originPrice = json['origin_price'];
    totalPrice = json['total_price'];
    tax = json['tax'];
    discount = json['discount'];
    quantity = json['quantity'];
    bonus = json['bonus'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    note = json['note'];
    stock = json['stock'] != null ? Stock.fromJson(json['stock']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['order_id'] = orderId;
    data['stock_id'] = stockId;
    data['origin_price'] = originPrice;
    data['total_price'] = totalPrice;
    data['tax'] = tax;
    data['discount'] = discount;
    data['quantity'] = quantity;
    data['bonus'] = bonus;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (stock != null) {
      data['stock'] = stock!.toJson();
    }
    if (note != null) {
      data['note'] = note;
    }
    return data;
  }
}

class Stock {
  int? id;
  int? countableId;
  num? price;
  int? quantity;
  num? tax;
  num? totalPrice;
  List<Extras>? extras;
  Product? product;

  Stock({
    this.id,
    this.countableId,
    this.price,
    this.quantity,
    this.tax,
    this.totalPrice,
    this.extras,
    this.product,
  });

  Stock.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    countableId = json['countable_id'];
    price = json['price'];
    quantity = json['quantity'];
    tax = json['tax'];
    totalPrice = json['total_price'];
    if (json['extras'] != null) {
      extras = <Extras>[];
      json['extras']?.forEach((v) {
        extras?.add(Extras.fromJson(v));
      });
    }
    product = json['product'] != null
        ? Product.fromJson(json['product'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['countable_id'] = countableId;
    data['price'] = price;
    data['quantity'] = quantity;
    data['tax'] = tax;
    data['total_price'] = totalPrice;
    if (extras != null) {
      data['extras'] = extras!.map((v) => v.toJson()).toList();
    }
    if (product != null) {
      data['product'] = product!.toJson();
    }
    return data;
  }
}

class Extras {
  int? id;
  int? extraGroupId;
  String? value;
  bool? active;
  Group? group;

  Extras({this.id, this.extraGroupId, this.value, this.active, this.group});

  Extras.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    extraGroupId = json['extra_group_id'];
    value = json['value'];
    active = json['active'];
    group = json['group'] != null ? Group.fromJson(json['group']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['extra_group_id'] = extraGroupId;
    data['value'] = value;
    data['active'] = active;
    if (group != null) {
      data['group'] = group!.toJson();
    }
    return data;
  }
}

class Group {
  int? id;
  String? type;
  bool? active;
  Translation? translation;
  List<String>? locales;

  Group({this.id, this.type, this.active, this.translation, this.locales});

  Group.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    type = json['type'];
    active = json['active'];
    translation = json['translation'] != null
        ? Translation.fromJson(json['translation'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['type'] = type;
    data['active'] = active;
    if (translation != null) {
      data['translation'] = translation!.toJson();
    }
    data['locales'] = locales;
    return data;
  }
}

class Product {
  int? id;
  String? uuid;
  int? shopId;
  int? categoryId;
  int? brandId;
  num? tax;
  num? interval;
  String? barCode;
  String? status;
  bool? active;
  bool? addon;
  String? img;
  int? minQty;
  int? maxQty;
  String? createdAt;
  String? updatedAt;
  Translation? translation;
  Unit? unit;
  List<String>? locales;

  Product({
    this.id,
    this.uuid,
    this.shopId,
    this.categoryId,
    this.brandId,
    this.tax,
    this.barCode,
    this.status,
    this.active,
    this.addon,
    this.img,
    this.minQty,
    this.maxQty,
    this.createdAt,
    this.updatedAt,
    this.translation,
    this.unit,
    this.locales,
  });

  Product.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uuid = json['uuid'];
    shopId = json['shop_id'];
    categoryId = json['category_id'];
    brandId = json['brand_id'];
    tax = json['tax'];
    interval = json['interval'];
    barCode = json['bar_code'];
    status = json['status'];
    active = json['active'];
    addon = json['addon'];
    img = json['img'];
    minQty = json['min_qty'];
    maxQty = json['max_qty'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    translation = json['translation'] != null
        ? Translation.fromJson(json['translation'])
        : null;
    unit = json['unit'] != null ? Unit.fromJson(json['unit']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['uuid'] = uuid;
    data['shop_id'] = shopId;
    data['category_id'] = categoryId;
    data['brand_id'] = brandId;
    data['tax'] = tax;
    data['interval'] = interval;
    data['bar_code'] = barCode;
    data['status'] = status;
    data['active'] = active;
    data['addon'] = addon;
    data['img'] = img;
    data['min_qty'] = minQty;
    data['max_qty'] = maxQty;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (translation != null) {
      data['translation'] = translation!.toJson();
    }
    if (unit != null) {
      data['unit'] = unit!.toJson();
    }
    data['locales'] = locales;
    return data;
  }
}

class Transaction {
  int? id;
  int? payableId;
  num? price;
  String? paymentTrxId;
  String? note;
  String? status;
  String? statusDescription;
  String? createdAt;
  String? updatedAt;
  PaymentSystem? paymentSystem;

  Transaction({
    this.id,
    this.payableId,
    this.price,
    this.paymentTrxId,
    this.note,
    this.status,
    this.statusDescription,
    this.createdAt,
    this.updatedAt,
    this.paymentSystem,
  });

  Transaction.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    payableId = json['payable_id'];
    price = json['price'];
    paymentTrxId = json['payment_trx_id'];
    note = json['note'];
    status = json['status'];
    statusDescription = json['status_description'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    paymentSystem = json['payment_system'] != null
        ? PaymentSystem.fromJson(json['payment_system'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['payable_id'] = payableId;
    data['price'] = price;
    data['payment_trx_id'] = paymentTrxId;
    data['note'] = note;
    data['status'] = status;
    data['status_description'] = statusDescription;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (paymentSystem != null) {
      data['payment_system'] = paymentSystem!.toJson();
    }
    return data;
  }
}

class PaymentSystem {
  int? id;
  String? tag;
  bool? active;

  PaymentSystem({this.id, this.tag, this.active});

  PaymentSystem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    tag = json['tag'];
    active = json['active'].runtimeType == int
        ? (json['active'] == 0 ? false : true)
        : json['active'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['tag'] = tag;
    data['active'] = active;
    return data;
  }
}
