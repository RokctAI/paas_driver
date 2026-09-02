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

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/models/response/banners_paginate_response.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:base_sdk/src/application/home/home_notifier.dart';

import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:marketplace_sdk/src/common/presentation/pages/home/home_four/widgets/banner_item_three.dart';

class BannerThree extends StatefulWidget {
  final RefreshController bannerController;
  final PageController pageController;
  final List<BannerData> banners;
  final HomeNotifier notifier;

  const BannerThree({
    super.key,
    required this.bannerController,
    required this.pageController,
    required this.banners,
    required this.notifier,
  });

  @override
  State<BannerThree> createState() => _BannerThreeState();
}

class _BannerThreeState extends State<BannerThree> {
  late Timer _timer;
  int _currentPage = 0;
  bool _userInteracted = false;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _stopAutoPlay();
    super.dispose();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_userInteracted && widget.banners.length > 1) {
        _currentPage = (_currentPage + 1) % widget.banners.length;
        widget.pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.ease,
        );
      }
    });
  }

  void _stopAutoPlay() {
    _timer.cancel();
  }

  void _handleUserInteraction() {
    setState(() {
      _userInteracted = true;
    });
    _stopAutoPlay();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: widget.banners.isNotEmpty ? 120.h : 0,
          margin: EdgeInsets.only(bottom: widget.banners.isNotEmpty ? 8.h : 0),
          child: GestureDetector(
            onPanDown: (_) => _handleUserInteraction(),
            child: SmartRefresher(
              scrollDirection: Axis.horizontal,
              enablePullDown: false,
              enablePullUp: true,
              controller: widget.bannerController,
              onLoading: () async {
                await widget.notifier.fetchBannerPage(
                  context,
                  widget.bannerController,
                );
              },
              child: AnimationLimiter(
                child: PageView.builder(
                  controller: widget.pageController,
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.banners.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: BannerItemThree(banner: widget.banners[index]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        if (widget.banners.length > 1)
          SizedBox(
            height: 8.r,
            child: SmoothPageIndicator(
              controller: widget.pageController,
              count: widget.banners.length,
              effect: ExpandingDotsEffect(
                expansionFactor: 2.2,
                dotWidth: 8.r,
                strokeWidth: 10.r,
                dotHeight: 4.r,
                activeDotColor: AppStyle.black,
                dotColor: AppStyle.dotColor,
                paintStyle: PaintingStyle.fill,
              ),
              onDotClicked: (index) {
                _handleUserInteraction();
                widget.pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.ease,
                );
              },
            ),
          ),
        12.verticalSpace,
      ],
    );
  }
}
