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


// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_style.dart';

/// The generic navbar machinery shared by paas_customer's
/// BottomNavigatorTwo/Three variants, recovered from
/// `lib/presentation/pages/main/widgets/bottom_navigator_two.dart` at
/// c273ab26^ (deleted during the ADR-008 refork). The commerce-specific tab
/// wrappers themselves (store/search/like tab lists, marketplace SVGs) were
/// deliberately left behind — tab IA belongs to hosts, this reusable engine
/// belongs here (ADR-005).
typedef ItemBuilder = Widget Function(
    BuildContext context, int index, FloatingNavbarItem items);

class FloatingNavbar extends StatefulWidget {
  final List<FloatingNavbarItem> items;
  final int currentIndex;
  final void Function(int val)? onTap;
  final Color selectedBackgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final Color backgroundColor;
  final ItemBuilder itemBuilder;
  final double width;
  final double elevation;

  FloatingNavbar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    ItemBuilder? itemBuilder,
    this.backgroundColor = AppStyle.white,
    this.selectedBackgroundColor = AppStyle.black,
    this.selectedItemColor = AppStyle.white,
    this.unselectedItemColor = AppStyle.textGrey,
    this.width = double.infinity,
    this.elevation = 0.0,
  })  : assert(items.length > 1),
        assert(items.length <= 5),
        assert(currentIndex <= items.length),
        assert(width > 50),
        itemBuilder = itemBuilder ??
            _defaultItemBuilder(
              unselectedItemColor: unselectedItemColor,
              selectedItemColor: selectedItemColor,
              width: width,
              backgroundColor: backgroundColor,
              currentIndex: currentIndex,
              items: items,
              onTap: onTap,
              selectedBackgroundColor: selectedBackgroundColor,
            );

  @override
  _FloatingNavbarState createState() => _FloatingNavbarState();
}

class _FloatingNavbarState extends State<FloatingNavbar> {
  List<FloatingNavbarItem> get items => widget.items;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(36.r)),
            color: widget.backgroundColor,
            boxShadow: const [
              BoxShadow(
                color: AppStyle.shadowBottom,
                blurRadius: 20,
                offset: Offset(0, -4),
                spreadRadius: 0,
              ),
            ],
          ),
          width: widget.width,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16.r,
              right: 16.r,
              bottom: 24.r,
              top: 12.r,
            ),
            child: Container(
              padding: REdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: AppStyle.bgGrey,
                borderRadius: BorderRadius.circular(32.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                mainAxisSize: MainAxisSize.max,
                children: items
                    .asMap()
                    .map(
                      (i, f) => MapEntry(i, widget.itemBuilder(context, i, f)),
                    )
                    .values
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

ItemBuilder _defaultItemBuilder({
  Function(int val)? onTap,
  required List<FloatingNavbarItem> items,
  int? currentIndex,
  Color? selectedBackgroundColor,
  Color? selectedItemColor,
  Color? unselectedItemColor,
  Color? backgroundColor,
  double width = double.infinity,
}) {
  return (BuildContext context, int index, FloatingNavbarItem item) => Expanded(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: currentIndex == index
                    ? selectedBackgroundColor
                    : AppStyle.transparent,
                shape: BoxShape.circle,
              ),
              child: InkWell(
                onTap: () => onTap!(index),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: width.isFinite
                      ? (width / items.length - 8)
                      : MediaQuery.sizeOf(context).width / items.length - 24,
                  padding: REdgeInsets.all(10),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      item.customWidget == null
                          ? Icon(
                              item.icon,
                              color: currentIndex == index
                                  ? selectedItemColor
                                  : unselectedItemColor,
                              size: currentIndex == index ? 26 : 24,
                            )
                          : item.customWidget!,
                      if (item.title != null)
                        Text(
                          '${item.title}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: currentIndex == index
                                ? selectedItemColor
                                : unselectedItemColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class FloatingNavbarItem {
  final String? title;
  final IconData? icon;
  final Widget? customWidget;

  FloatingNavbarItem({this.icon, this.title, this.customWidget})
      : assert(icon != null || customWidget != null);
}
