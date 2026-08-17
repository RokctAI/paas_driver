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

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/application/profile/profile_provider.dart';
//import 'package:foodyman/infrastructure/services/app_helpers.dart';
//import 'package:foodyman/infrastructure/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/buttons/pop_button.dart';
import 'package:base_sdk/src/presentation/components/loading.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';
import 'package:base_sdk/src/services/app_assets.dart';
import 'package:base_sdk/src/presentation/components/app_bars/common_app_bar.dart';

@RoutePage()
class TermPage extends ConsumerStatefulWidget {
  const TermPage({super.key});

  @override
  ConsumerState<TermPage> createState() => _TermPageState();
}

class _TermPageState extends ConsumerState<TermPage> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).getTerm(context: context);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    return Scaffold(
      //backgroundColor: AppStyle.bgGrey,
      body: state.isTermLoading
          ? const Center(child: Loading())
          : Column(
              children: [
                CommonAppBar(
                  child: Row(
                    children: [
                      Image.asset(AppAssets.pngLogo, width: 40, height: 40),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            state.term?.title ?? "",
                            style: AppStyle.interSemi(color: AppStyle.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                state.isTermLoading
                    ? const Center(child: Loading())
                    : Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(16.r),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Html(
                                data: state.term?.description ?? "",
                                style: {"body": Style()},
                              ),
                            ],
                          ),
                        ),
                      ),
              ],
            ),

      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: const PopButton(),
    );
  }
}
