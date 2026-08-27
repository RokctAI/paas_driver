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
import 'package:base_sdk/src/presentation/theme/theme.dart';

class AddCardWidget extends StatelessWidget {
  final String number;
  final String startDate;
  final String name;
  final bool isActive;

  const AddCardWidget({
    super.key,
    required this.number,
    required this.startDate,
    required this.name,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        right: 20.w,
        left: 20.w,
        top: 46.h,
        bottom: 24.h,
      ),
      decoration: BoxDecoration(
        image: isActive
            ? const DecorationImage(
                alignment: Alignment.topRight,
                image: AssetImage("assets/images/cardBg.png"),
                fit: BoxFit.contain,
              )
            : null,
        color: AppStyle.white,
        borderRadius: BorderRadius.all(Radius.circular(10.r)),
        boxShadow: [
          BoxShadow(
            color: AppStyle.white.withOpacity(0.04),
            spreadRadius: 0,
            blurRadius: 2,
            offset: const Offset(0, 2), // changes position of shadow
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset("assets/images/card.png", width: 36.w),
          24.verticalSpace,
          Text(
            number,
            style: AppStyle.interBold(size: 18, color: AppStyle.black),
          ),
          12.verticalSpace,
          Row(
            children: [
              Text(
                startDate,
                style: AppStyle.interNormal(size: 12, color: AppStyle.black),
              ),
              10.horizontalSpace,
              isActive
                  ? Text(
                      "Cheese",
                      style: AppStyle.interNormal(
                        size: 12,
                        color: AppStyle.black,
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: AppStyle.interNormal(size: 12, color: AppStyle.black),
              ),
              isActive
                  ? Image.asset("assets/images/visa.png", height: 36.h)
                  : const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }
}
