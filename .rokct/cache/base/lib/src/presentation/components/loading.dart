import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';

class Loading extends StatelessWidget {
  final Color bgColor;

  const Loading({super.key, this.bgColor = AppStyle.textGrey});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Platform.isAndroid
          ? CircularProgressIndicator(color: AppStyle.primary)
          : CupertinoActivityIndicator(color: bgColor, radius: 12),
    );
  }
}
