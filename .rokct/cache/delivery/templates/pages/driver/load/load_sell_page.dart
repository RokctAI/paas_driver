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

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:delivery_sdk/src/driver/presentation/load/load_sale_plane.dart';

/// `/load/sell` — the sale at the door.
///
/// `?load=<load order>` names which load is being sold from; the plane
/// falls back to the driver's only open load when it is absent, which is
/// the shape of almost every van day. A load the slice does not hold shows
/// the "open this from your load" notice rather than an empty stepper list.
@RoutePage()
class DriverLoadSellPage extends StatelessWidget {
  const DriverLoadSellPage({
    super.key,
    @QueryParam('load') this.load,
  });

  final String? load;

  @override
  Widget build(BuildContext context) {
    return LoadSalePlane(loadOrder: load);
  }
}
