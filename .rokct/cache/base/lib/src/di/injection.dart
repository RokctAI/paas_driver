// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


import 'package:get_it/get_it.dart';

import 'package:base_sdk/src/domain/interface/address.dart';
import 'package:base_sdk/src/domain/interface/auth.dart';
import 'package:base_sdk/src/domain/interface/banners.dart';
import 'package:base_sdk/src/domain/interface/blogs.dart';
import 'package:base_sdk/src/domain/interface/brands.dart';
import 'package:base_sdk/src/domain/interface/cart.dart';
import 'package:base_sdk/src/domain/interface/categories.dart';
import 'package:base_sdk/src/domain/interface/currencies.dart';
import 'package:base_sdk/src/domain/interface/delivery_points.dart';
import 'package:base_sdk/src/domain/interface/draw.dart';
import 'package:base_sdk/src/domain/interface/gallery.dart';
import 'package:base_sdk/src/domain/interface/loans.dart';
import 'package:base_sdk/src/domain/interface/notification.dart';
import 'package:base_sdk/src/domain/interface/orders.dart';
import 'package:base_sdk/src/domain/interface/parcel.dart';
import 'package:base_sdk/src/domain/interface/payments.dart';
import 'package:base_sdk/src/domain/interface/products.dart';
import 'package:base_sdk/src/domain/interface/settings.dart';
import 'package:base_sdk/src/domain/interface/shops.dart';
import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/domain/interface/wallet.dart';
import 'package:base_sdk/src/handlers/http_service.dart';

final GetIt getIt = GetIt.instance;

T inject<T extends Object>() {
  return GetIt.I.get<T>();
}

/// Facade accessors for SDK-resident application code.
///
/// The HOST app registers concrete repository implementations (from the
/// feature SDKs) against these base_sdk interfaces during bootstrap
/// (setUpDependencies), so no feature SDK ever imports another feature
/// SDK's package. These getters resolve lazily at first use, i.e. after
/// registration has happened.
HttpService get dioHttp => getIt.get<HttpService>();

SettingsRepositoryFacade get settingsRepository =>
    getIt.get<SettingsRepositoryFacade>();
AuthRepositoryFacade get authRepository => getIt.get<AuthRepositoryFacade>();
ShopsRepositoryFacade get shopsRepository =>
    getIt.get<ShopsRepositoryFacade>();
ProductsRepositoryFacade get productsRepository =>
    getIt.get<ProductsRepositoryFacade>();
CategoriesRepositoryFacade get categoriesRepository =>
    getIt.get<CategoriesRepositoryFacade>();
BannersRepositoryFacade get bannersRepository =>
    getIt.get<BannersRepositoryFacade>();
CartRepositoryFacade get cartRepository => getIt.get<CartRepositoryFacade>();
OrdersRepositoryFacade get ordersRepository =>
    getIt.get<OrdersRepositoryFacade>();
AddressRepositoryFacade get addressesRepository =>
    getIt.get<AddressRepositoryFacade>();
BrandsRepositoryFacade get brandsRepository =>
    getIt.get<BrandsRepositoryFacade>();
GalleryRepositoryFacade get galleryRepository =>
    getIt.get<GalleryRepositoryFacade>();
CurrenciesRepositoryFacade get currenciesRepository =>
    getIt.get<CurrenciesRepositoryFacade>();
PaymentsRepositoryFacade get paymentsRepository =>
    getIt.get<PaymentsRepositoryFacade>();
UserRepositoryFacade get userRepository => getIt.get<UserRepositoryFacade>();
BlogsRepositoryFacade get blogsRepository =>
    getIt.get<BlogsRepositoryFacade>();
DrawRepositoryFacade get drawRepository => getIt.get<DrawRepositoryFacade>();
ParcelRepositoryFacade get parcelRepository =>
    getIt.get<ParcelRepositoryFacade>();
NotificationRepositoryFacade get notificationRepo =>
    getIt.get<NotificationRepositoryFacade>();
WalletRepositoryFacade get walletRepository =>
    getIt.get<WalletRepositoryFacade>();
LoansRepositoryFacade get loansRepository =>
    getIt.get<LoansRepositoryFacade>();
DeliveryPointsRepositoryFacade get deliveryPointsRepository =>
    getIt.get<DeliveryPointsRepositoryFacade>();

Map get translation => getIt.get<Map>();
