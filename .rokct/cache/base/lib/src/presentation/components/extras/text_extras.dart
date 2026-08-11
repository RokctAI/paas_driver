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
