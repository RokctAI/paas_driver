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

library zones_sdk;

// Common-only barrel, same rule as revenue_sdk's and auth_sdk's: everything
// exported here lives under `src/common/`, because the composer's
// strip_unused_role_folders deletes the non-matching role folder from an
// app's cache (a driver app loses `lib/src/manager/`, a manager app loses
// `lib/src/driver/`) and the generated `main.dart` imports this barrel in
// every composed app — a single export into a role folder would break the
// other role's build. (The pre-manager version of this barrel exported the
// driver slice, which is exactly the break a manager compose would have hit.)
//
// `common/` holds what is common *by design*: the seam every host implements
// against ([DeliveryZonesFacade]), the edit-policy contract a restricting
// flavour may register ([ZoneEditPolicy]), and the DI entry point every
// generated `main.dart` calls. Role folders hold each flavour's notifier/
// provider/state, reached only from code that itself survives the same strip
// — the installed page templates — via direct
// `package:zones_sdk/src/<role>/...` imports:
//
// - driver/: the courier zone editor's notifier/provider/state (gated on
//   ZoneEditPolicy when the host registers one) plus its legacy response
//   models.
// - manager/: the merchant shop-catchment editor's notifier/provider/state,
//   ported from paas_manager's application/restaurant/delivery_zone/.
export 'src/common/di/zones_di.dart';
export 'src/common/domain/interface/delivery_zones.dart';
export 'src/common/domain/interface/zone_edit_policy_contract.dart';
