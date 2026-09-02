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

import 'package:base_sdk/src/models/data/typed_extra.dart';
import 'package:base_sdk/src/presentation/components/size_item.dart';

class TextExtras extends StatelessWidget {
  final int groupIndex;
  final List<UiExtra> uiExtras;
  final Function(UiExtra) onUpdate;

  const TextExtras({
    super.key,
    required this.groupIndex,
    required this.uiExtras,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: uiExtras.length,
      itemBuilder: (BuildContext context, int index) {
        return SizeItem(
          onTap: () {
            if (uiExtras[index].isSelected) {
              return;
            }
            onUpdate(uiExtras[index]);
          },
          isActive: uiExtras[index].isSelected,
          title: uiExtras[index].value,
        );
      },
    );
  }
}
