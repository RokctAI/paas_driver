import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:driver/presentation/styles/style.dart';

class Loading extends StatelessWidget {
  final Color bgColor;

  const Loading({super.key, this.bgColor = Style.greyColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Platform.isAndroid
          ? CircularProgressIndicator(color: Style.primary, strokeWidth: 5.r)
          : CupertinoActivityIndicator(radius: 12.r),
    );
  }
}
