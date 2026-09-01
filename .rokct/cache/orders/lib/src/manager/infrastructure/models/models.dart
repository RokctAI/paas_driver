// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

/// Barrel for the manager (seller) order models, mirroring the shape of
/// `paas_manager`'s `infrastructure/models/models.dart` for the slice this SDK
/// owns. Classes the fork resolved to base_sdk (Translation, CurrencyData,
/// LocationModel, Meta, TypedExtra, TransactionsResponse) are re-exported from
/// base so ported files keep compiling against one barrel.
library;

// base_sdk-owned models this slice reuses.
export 'package:base_sdk/src/models/data/currency_data.dart';
export 'package:base_sdk/src/models/data/location.dart';
export 'package:base_sdk/src/models/data/meta.dart';
export 'package:base_sdk/src/models/data/translation.dart';
export 'package:base_sdk/src/models/data/typed_extra.dart';
export 'package:base_sdk/src/models/response/transactions_response.dart';

// Manager order models owned by this SDK.
export 'data/address_data.dart';
export 'data/category_data.dart';
export 'data/collect_conversion.dart';
export 'data/extras.dart';
export 'data/galleries.dart';
export 'data/group.dart';
export 'data/kitchen_data.dart';
export 'data/order_calculate_data.dart';
export 'data/order_data.dart';
export 'data/order_json_ext.dart';
export 'data/payment_data.dart';
export 'data/product_data.dart';
export 'data/stock.dart';
export 'data/table_data.dart';
export 'data/unit_data.dart';
export 'data/user_data.dart';
export 'response/categories_paginate_response.dart';
export 'response/create_order_response.dart';
export 'response/order_status_response.dart';
export 'response/orders_paginate_response.dart';
export 'response/payments_response.dart';
export 'response/products_paginate_response.dart';
export 'response/shop_section_response.dart';
export 'response/single_order_response.dart';
export 'response/single_product_response.dart';
export 'response/single_user_response.dart';
export 'response/table_response.dart';
export 'response/users_paginate_response.dart';
