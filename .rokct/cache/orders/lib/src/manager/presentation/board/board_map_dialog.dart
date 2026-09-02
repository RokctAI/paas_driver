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

import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

/// The delivery card's map-pin affordance (POS `map_dialog.dart`, trimmed):
/// a dialog with the order's delivery point pinned and its address line.
/// Sheets and dialogs never take planes — this overlays, per the model.
class BoardMapDialog extends StatelessWidget {
  final OrderData order;

  const BoardMapDialog({super.key, required this.order});

  /// Shows the dialog when the order carries a usable location; silently
  /// no-ops otherwise (a delivery order without coordinates has nothing
  /// to pin).
  static void show(BuildContext context, OrderData order) {
    if (order.location?.latitude == null || order.location?.longitude == null) {
      return;
    }
    showDialog(
      context: context,
      builder: (_) => BoardMapDialog(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng point = LatLng(
      order.location?.latitude ?? 0,
      order.location?.longitude ?? 0,
    );
    final String? address = order.orderAddress?.address;
    return Dialog(
      backgroundColor: AppStyle.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
              child: Row(
                children: [
                  Icon(
                    FlutterRemix.map_pin_2_line,
                    size: 16,
                    color: AppStyle.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (address == null || address.isEmpty) ? '- -' : address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyle.interSemi(
                        size: 13,
                        color: AppStyle.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: AppStyle.textDarkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: SizedBox(
                height: 320,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: point,
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('order-address'),
                      position: point,
                    ),
                  },
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
