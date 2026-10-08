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

import 'package:delivery_sdk/src/driver/presentation/load/load_return_plane.dart';

/// `/load/return` — unsold stock back to the shop. `?load=<load order>`
/// as on the sell route.
@RoutePage()
class DriverLoadReturnPage extends StatelessWidget {
  const DriverLoadReturnPage({
    super.key,
    @QueryParam('load') this.load,
  });

  final String? load;

  @override
  Widget build(BuildContext context) {
    return LoadReturnPlane(loadOrder: load);
  }
}
