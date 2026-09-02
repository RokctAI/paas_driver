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

library products_sdk;

// Import concrete files via package:products_sdk/src/common/...
//
// Role folders are siblings of common/: `common/` holds the seams a host
// implements against plus the DTOs those seams return, `manager/` holds the
// seller-authoring implementation ported from paas_manager.
export 'src/common/di/products_di.dart';
export 'src/common/domain/interface/seller_products.dart';
export 'src/common/infrastructure/models/data/seller_product_data.dart';
export 'src/common/infrastructure/models/data/seller_stock.dart';
export 'src/common/infrastructure/models/data/seller_extras.dart';
export 'src/common/infrastructure/models/data/seller_extras_group.dart';
export 'src/common/infrastructure/models/data/seller_gallery.dart';
export 'src/common/infrastructure/models/data/seller_unit_data.dart';
export 'src/common/infrastructure/models/data/seller_category_data.dart';
export 'src/common/infrastructure/models/response/seller_products_paginate_response.dart';
export 'src/common/infrastructure/models/response/single_seller_product_response.dart';
export 'src/common/infrastructure/models/response/seller_extras_groups_response.dart';
export 'src/common/infrastructure/models/response/seller_group_extras_response.dart';
export 'src/common/infrastructure/models/response/single_seller_extras_group_response.dart';
export 'src/common/infrastructure/models/response/create_seller_extras_response.dart';
export 'src/common/infrastructure/models/response/seller_units_paginate_response.dart';
export 'src/common/domain/interface/seller_catalog.dart';
export 'src/common/infrastructure/models/response/seller_categories_paginate_response.dart';
export 'src/manager/application/foods/foods_notifier.dart';
export 'src/manager/application/foods/foods_provider.dart';
export 'src/manager/application/foods/foods_state.dart';
export 'src/manager/application/foods/food_tabs_notifier.dart';
export 'src/manager/application/foods/food_tabs_provider.dart';
export 'src/manager/application/foods/food_tabs_state.dart';
export 'src/manager/application/foods/food_categories_notifier.dart';
export 'src/manager/application/foods/food_categories_provider.dart';
export 'src/manager/application/foods/food_categories_state.dart';
export 'src/manager/application/seller_product_requests.dart';
export 'src/manager/application/foods/create/details/create_food_details_notifier.dart';
export 'src/manager/application/foods/create/details/create_food_details_provider.dart';
export 'src/manager/application/foods/create/details/create_food_details_state.dart';
export 'src/manager/application/foods/create/details/category/add_food_categories_notifier.dart';
export 'src/manager/application/foods/create/details/category/add_food_categories_provider.dart';
export 'src/manager/application/foods/create/details/category/add_food_categories_state.dart';
export 'src/manager/application/foods/create/details/category/add/add_category_notifier.dart';
export 'src/manager/application/foods/create/details/category/add/add_category_provider.dart';
export 'src/manager/application/foods/create/details/category/add/add_category_state.dart';
export 'src/manager/application/foods/create/details/units/create_food_units_notifier.dart';
export 'src/manager/application/foods/create/details/units/create_food_units_provider.dart';
export 'src/manager/application/foods/create/details/units/create_food_units_state.dart';
export 'src/manager/application/foods/create/stocks/create_food_stocks_notifier.dart';
export 'src/manager/application/foods/create/stocks/create_food_stocks_provider.dart';
export 'src/manager/application/foods/create/stocks/create_food_stocks_state.dart';
export 'src/manager/application/foods/create/stocks/addons/create_food_addons_notifier.dart';
export 'src/manager/application/foods/create/stocks/addons/create_food_addons_provider.dart';
export 'src/manager/application/foods/create/stocks/addons/create_food_addons_state.dart';
export 'src/manager/application/foods/edit/details/edit_food_details_notifier.dart';
export 'src/manager/application/foods/edit/details/edit_food_details_provider.dart';
export 'src/manager/application/foods/edit/details/edit_food_details_state.dart';
export 'src/manager/application/foods/edit/details/category/edit_food_categories_notifier.dart';
export 'src/manager/application/foods/edit/details/category/edit_food_categories_provider.dart';
export 'src/manager/application/foods/edit/details/category/edit_food_categories_state.dart';
export 'src/manager/application/foods/edit/details/units/edit_food_units_notifier.dart';
export 'src/manager/application/foods/edit/details/units/edit_food_units_provider.dart';
export 'src/manager/application/foods/edit/details/units/edit_food_units_state.dart';
export 'src/manager/application/foods/edit/stocks/edit_food_stocks_notifier.dart';
export 'src/manager/application/foods/edit/stocks/edit_food_stocks_provider.dart';
export 'src/manager/application/foods/edit/stocks/edit_food_stocks_state.dart';
export 'src/manager/application/foods/edit/stocks/addons/edit_food_addons_notifier.dart';
export 'src/manager/application/foods/edit/stocks/addons/edit_food_addons_provider.dart';
export 'src/manager/application/foods/edit/stocks/addons/edit_food_addons_state.dart';
export 'src/manager/application/addons/addons_notifier.dart';
export 'src/manager/application/addons/addons_provider.dart';
export 'src/manager/application/addons/addons_state.dart';
export 'src/manager/application/addons/create/create_addon_notifier.dart';
export 'src/manager/application/addons/create/create_addon_provider.dart';
export 'src/manager/application/addons/create/create_addon_state.dart';
export 'src/manager/application/addons/create/units/create_addon_units_notifier.dart';
export 'src/manager/application/addons/create/units/create_addon_units_provider.dart';
export 'src/manager/application/addons/create/units/create_addon_units_state.dart';
export 'src/manager/application/addons/edit/edit_addon_notifier.dart';
export 'src/manager/application/addons/edit/edit_addon_provider.dart';
export 'src/manager/application/addons/edit/edit_addon_state.dart';
export 'src/manager/application/addons/edit/units/edit_addon_units_notifier.dart';
export 'src/manager/application/addons/edit/units/edit_addon_units_provider.dart';
export 'src/manager/application/addons/edit/units/edit_addon_units_state.dart';
export 'src/manager/application/extras/extras_notifier.dart';
export 'src/manager/application/extras/extras_provider.dart';
export 'src/manager/application/extras/extras_state.dart';
export 'src/manager/application/extras/create/create_extras_group_notifier.dart';
export 'src/manager/application/extras/create/create_extras_group_provider.dart';
export 'src/manager/application/extras/create/create_extras_group_state.dart';
export 'src/manager/application/extras/update/update_extras_group_notifier.dart';
export 'src/manager/application/extras/update/update_extras_group_provider.dart';
export 'src/manager/application/extras/update/update_extras_group_state.dart';
export 'src/manager/application/extras/delete/delete_extras_group_notifier.dart';
export 'src/manager/application/extras/delete/delete_extras_group_provider.dart';
export 'src/manager/application/extras/delete/delete_extras_group_state.dart';
export 'src/manager/application/extras/details/extras_group_details_notifier.dart';
export 'src/manager/application/extras/details/extras_group_details_provider.dart';
export 'src/manager/application/extras/details/extras_group_details_state.dart';
export 'src/manager/application/extras/details/new_item/create_new_group_item_notifier.dart';
export 'src/manager/application/extras/details/new_item/create_new_group_item_provider.dart';
export 'src/manager/application/extras/details/new_item/create_new_group_item_state.dart';
export 'src/manager/application/extras/details/edit_item/edit_extras_item_notifier.dart';
export 'src/manager/application/extras/details/edit_item/edit_extras_item_provider.dart';
export 'src/manager/application/extras/details/edit_item/edit_extras_item_state.dart';
export 'src/manager/application/extras/details/delete_item/delete_extras_item_notifier.dart';
export 'src/manager/application/extras/details/delete_item/delete_extras_item_provider.dart';
export 'src/manager/application/extras/details/delete_item/delete_extras_item_state.dart';
