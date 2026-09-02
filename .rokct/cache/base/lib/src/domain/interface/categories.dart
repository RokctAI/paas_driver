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


import 'package:base_sdk/src/models/response/categories_paginate_response.dart';
import 'package:base_sdk/src/handlers/handlers.dart';

abstract class CategoriesRepositoryFacade {
  Future<ApiResult<CategoriesPaginateResponse>> getAllCategories({
    required int page,
  });

  Future<ApiResult<CategoriesPaginateResponse>> searchCategories({
    required String text,
  });

  Future<ApiResult<CategoriesPaginateResponse>> getCategoriesByShop({
    required String shopId,
  });
}
