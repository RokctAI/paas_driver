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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/services/enums.dart';

import 'package:products_sdk/src/common/application/product/product_provider.dart';
import 'package:base_sdk/src/models/data/typed_extra.dart';
import 'package:base_sdk/src/presentation/components/extras/color_extras.dart';
import 'package:base_sdk/src/presentation/components/extras/image_extras.dart';
import 'package:base_sdk/src/presentation/components/extras/text_extras.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

class WProductExtras extends ConsumerWidget {
  const WProductExtras({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productProvider);
    final notifier = ref.read(productProvider.notifier);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color:
            state.typedExtras.isEmpty ? AppStyle.transparent : AppStyle.cardDark,
        borderRadius: BorderRadius.circular(10.r),
      ),
      padding: REdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: state.typedExtras.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final TypedExtra typedExtra = state.typedExtras[index];
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                  color: AppStyle.cardDark,
                ),
                padding: REdgeInsets.symmetric(horizontal: 12, vertical: 14),
                margin: REdgeInsets.only(bottom: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typedExtra.title,
                      style: AppStyle.interNoSemi(
                        size: 16,
                        color: AppStyle.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    16.verticalSpace,
                    typedExtra.type == ExtrasType.text
                        ? TextExtras(
                            uiExtras: typedExtra.uiExtras,
                            groupIndex: typedExtra.groupIndex,
                            onUpdate: (uiExtra) {
                              notifier.updateSelectedIndexes(
                                context,
                                typedExtra.groupIndex,
                                uiExtra.index,
                              );
                            },
                          )
                        : typedExtra.type == ExtrasType.color
                            ? ColorExtras(
                                uiExtras: typedExtra.uiExtras,
                                groupIndex: typedExtra.groupIndex,
                                onUpdate: (uiExtra) {
                                  notifier.updateSelectedIndexes(
                                    context,
                                    typedExtra.groupIndex,
                                    uiExtra.index,
                                  );
                                },
                              )
                            : typedExtra.type == ExtrasType.image
                                ? ImageExtras(
                                    uiExtras: typedExtra.uiExtras,
                                    groupIndex: typedExtra.groupIndex,
                                    updateImage: notifier.changeActiveImageUrl,
                                    onUpdate: (uiExtra) {
                                      notifier.updateSelectedIndexes(
                                        context,
                                        typedExtra.groupIndex,
                                        uiExtra.index,
                                      );
                                    },
                                  )
                                : const SizedBox(),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
