// Copyright (c) 2026 RokctAI
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

library revenue_sdk;

// Common-only barrel, same rule as auth_sdk's: everything exported here lives
// under `src/common/`, because the composer's strip_unused_role_folders
// deletes the non-matching role folder from an app's cache (a driver app
// loses `lib/src/manager/`, a manager app loses `lib/src/driver/`) and the
// generated `main.dart` imports this barrel in every composed app — a single
// export into a role folder would break the other role's build.
//
// `common/` holds what is common *by design*: the seams a host implements
// against ([SellerStatisticsRepositoryFacade] and
// [CourierStatisticsRepositoryFacade]), the response models those seams'
// signatures return, and the DI entry point every generated `main.dart`
// calls. Role folders hold the role-specific concrete repositories and
// application state, reached only from code that itself survives the same
// strip — import them via direct `package:revenue_sdk/src/<role>/...` paths:
//
// - manager/: SellerStatisticsRepository, the income screen's
//   statistics notifier/provider/state (used by the manager income page
//   template installed into manager hosts), and ManagerRevenueDependencies
//   (src/manager/di/manager_revenue_di.dart).
// - driver/: CourierStatisticsRepository, the income screen's statistics
//   notifier/provider/state plus its OrdinalSales chart row (used by the
//   driver income page template installed into driver hosts), and
//   DriverRevenueDependencies (src/driver/di/driver_revenue_di.dart).
export 'src/common/di/revenue_di.dart';
export 'src/common/domain/interface/courier_statistics.dart';
export 'src/common/domain/interface/seller_statistics.dart';
export 'src/common/infrastructure/models/response/courier_statistics_income_response.dart';
export 'src/common/infrastructure/models/response/courier_statistics_order_response.dart';
export 'src/common/infrastructure/models/response/courier_statistics_response.dart';
export 'src/common/infrastructure/models/response/statistics_order_response.dart';
export 'src/common/infrastructure/models/response/statistics_response.dart';
