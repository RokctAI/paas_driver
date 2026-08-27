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


import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/presentation/pages/initial/no_connection/no_connection_page.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/presentation/components/keyboard_dismisser.dart';

class CustomScaffold extends ConsumerStatefulWidget {
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;

  const CustomScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.bottomNavigationBar,
    this.drawer,
  });

  @override
  ConsumerState<CustomScaffold> createState() => _CustomScaffoldState();
}

class _CustomScaffoldState extends ConsumerState<CustomScaffold>
    with WidgetsBindingObserver {
  StreamSubscription? connectivitySubscription;
  ValueNotifier<bool> isNetworkDisabled = ValueNotifier(false);

  void _checkCurrentNetworkState() {
    Connectivity().checkConnectivity().then((connectivityResult) {
      isNetworkDisabled.value = connectivityResult.contains(
        ConnectivityResult.none,
      );
    });
  }

  initStateFunc() {
    _checkCurrentNetworkState();
    connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      isNetworkDisabled.value = result.contains(ConnectivityResult.none);
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    initStateFunc();
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkCurrentNetworkState();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ValueListenableBuilder(
          valueListenable: isNetworkDisabled,
          builder: (_, bool networkDisabled, __) => Visibility(
            visible: !networkDisabled,
            child: KeyboardDismisser(
              child: Scaffold(
                resizeToAvoidBottomInset: false,
                appBar: widget.appBar,
                backgroundColor: widget.backgroundColor ?? AppStyle.bgGrey,
                body: widget.body,
                drawer: widget.drawer,
                floatingActionButton: widget.floatingActionButton,
                floatingActionButtonLocation:
                    widget.floatingActionButtonLocation,
                bottomNavigationBar: widget.bottomNavigationBar,
              ),
            ),
          ),
        ),
        ValueListenableBuilder(
          valueListenable: isNetworkDisabled,
          builder: (_, bool networkDisabled, __) => Visibility(
            visible: networkDisabled,
            child: const NoConnectionPage(),
          ),
        ),
      ],
    );
  }
}
