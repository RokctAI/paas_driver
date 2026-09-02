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

import 'package:zones_sdk/src/manager/infrastructure/repositories/delivery_zones_repository.dart';

/// Host-side wiring for zones_sdk in the manager flavour (ADR-005).
///
/// Thin by design (manager migration M5): the shop-polygon endpoint knowledge
/// that used to live behind the host's users repository
/// (`package:manager/domain/di/dependency_manager.dart`) moved into
/// zones_sdk's own [ManagerDeliveryZonesRepository], so no host-owned
/// repository remains. This file is still host-composition code — it lives in
/// templates/ and is installed at compose time (manager flavour only, see
/// manifest.json app_type.manager), which is why it may deep-import zones_sdk
/// role code. The validator scans SDK lib/ only, so nothing here is a
/// cross-SDK import violation.
///
/// Registration is injected into the generated main.dart by the manifest's
/// app_type.manager `di_hooks` entry (isRegistered-guarded):
///
///   GetIt.instance.registerLazySingleton<DeliveryZonesFacade>(
///     () => ManagerDeliveryZonesAdapter());
///
/// Without it deliveryZoneProvider falls back to a 501 "not wired" stand-in
/// and the zone screen never reaches real shop data.
///
/// No ZoneEditPolicy registration, deliberately: a merchant drawing their own
/// shop's catchment has no equivalent of the driver's
/// `driver_can_edit_credentials` restriction, and registering nothing is the
/// contract's explicit way to say "unrestricted".
class ManagerDeliveryZonesAdapter extends ManagerDeliveryZonesRepository {}
