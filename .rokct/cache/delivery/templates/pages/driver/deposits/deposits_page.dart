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

import 'package:delivery_sdk/src/driver/presentation/deposit/deposit_status_page.dart';

/// Frame 49i's route shell (`/driver-deposits`). Installed as a template
/// because SDK lib/ pages never get a generated route class; everything
/// on screen lives in delivery_sdk's `DriverDepositStatusPlane`.
///
/// `?choose=1` — how corporate's wallet plane (49f) arrives from its Top
/// up pill — opens the method chooser (49g) over the plane on the first
/// frame; the plane alone is what a plain push shows.
@RoutePage()
class DriverDepositsPage extends StatelessWidget {
  const DriverDepositsPage({
    super.key,
    @QueryParam('choose') this.choose,
  });

  final String? choose;

  bool get _openChooser {
    final value = (choose ?? '').trim().toLowerCase();
    return value == '1' || value == 'true' || value == 'yes';
  }

  @override
  Widget build(BuildContext context) {
    return DriverDepositStatusPlane(openChooserOnStart: _openChooser);
  }
}
