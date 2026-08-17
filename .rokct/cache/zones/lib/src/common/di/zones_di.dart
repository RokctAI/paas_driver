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

import 'package:get_it/get_it.dart';

/// zones_sdk's DI entry point, called from the host app's generated `main()`.
///
/// Deliberately registers nothing today. zones_sdk's only cross-SDK need is
/// [DeliveryZonesFacade], and under ADR-005 the implementation is the host
/// app's to supply — it wraps whichever SDK actually stores the courier's
/// profile. `deliveryZoneProvider` resolves that facade from `GetIt` at build
/// time and falls back to a failing stand-in when the host has not registered
/// one, so composing zones_sdk without wiring it degrades visibly rather than
/// crashing at startup.
///
/// The class exists regardless because the composer generates a
/// `ZonesSdkDependencies.register(GetIt.instance)` call into every host that
/// lists this SDK; without it the host does not compile.
class ZonesSdkDependencies {
  static void register(GetIt getIt) {
    // Intentionally empty — see class doc. Host-supplied adapters are
    // registered by the app, e.g.:
    //
    //   getIt.registerLazySingleton<DeliveryZonesFacade>(
    //     () => DriverDeliveryZonesAdapter(),
    //   );
  }
}
