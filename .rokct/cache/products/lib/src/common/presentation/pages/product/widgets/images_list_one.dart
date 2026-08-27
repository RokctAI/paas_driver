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

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/models/data/review_data.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

class ImagesOneList extends StatelessWidget {
  final List<Galleries>? list;
  final int? selectImageId;

  const ImagesOneList({
    super.key,
    required this.list,
    required this.selectImageId,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 6.r,
      width: MediaQuery.sizeOf(context).width,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: list
                    ?.map(
                      (e) => AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        margin: EdgeInsets.only(right: 6.r),
                        height: 6.r,
                        width: selectImageId == e.id ? 32.r : 8.r,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100.r),
                          color: selectImageId == e.id
                              ? AppStyle.black
                              : AppStyle.hintColor,
                        ),
                      ),
                    )
                    .toList() ??
                [],
          ),
        ),
      ),
    );
  }
}
