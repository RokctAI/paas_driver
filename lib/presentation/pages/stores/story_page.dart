import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../application/providers.dart';
import '../../../infrastructure/services/services.dart';
import '../../component/components.dart';
import '../../styles/style.dart';

@RoutePage()
class StoryPage extends ConsumerStatefulWidget {
  const StoryPage({Key? key}) : super(key: key);

  @override
  ConsumerState<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends ConsumerState<StoryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  // late StoryNotifier event;
  final pageController = PageController(initialPage: 0);
  int currentIndex = 0;

  final List<String> image = [
      "https://s3.juvo.app/public/images/intro/driver/1.jpg",
      "https://s3.juvo.app/public/images/intro/driver/2.jpg",
      "https://s3.juvo.app/public/images/intro/driver/3.jpg",
    ];

  final List<Map<String, dynamic>> titles = [
    {
        'text': AppHelpers.getTranslation(TrKeys.deliverymanbottomslide1),
        'style': Style.interNormal(size: 32.sp, letterSpacing: -0.3, color: Style.white),
      },
      {
        'text': AppHelpers.getTranslation(TrKeys.deliverymanbottomslide2),
        'style': Style.interNormal(size: 32.sp, letterSpacing: -0.3, color: Style.white),
      },
      {
        'text': AppHelpers.getTranslation(TrKeys.deliverymanbottomslide3),
        'style': Style.interNormal(size: 32.sp, letterSpacing: -0.3, color: Style.white),
      },
  ];

  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
      setState(() {});
      if (controller.value > 0.99) {
        if (ref.watch(storyProvider).currentIndex == 2) {
           context.router.maybePop();
        }
        pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeIn);
      }
    });
    controller.repeat();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    // event = ref.read(storyProvider.notifier);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storyProvider);
    final event = ref.read(storyProvider.notifier);
    return Scaffold(
        body: Stack(
          children: [
            PageView(
              physics: const ClampingScrollPhysics(),
              controller: pageController,
              onPageChanged: (s) {
                event.changeIndex(s);
                controller.reset();
                controller.repeat();
              },
              children: [
                ...image.map((e) => Stack(
                  children: [
                    Container(
                      width: MediaQuery.sizeOf(context).width,
                      height: MediaQuery.sizeOf(context).height,
                      foregroundDecoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Style.primaryColor.withOpacity(0.26),
                            Style.primaryColor.withOpacity(0),
                            Style.primaryColor.withOpacity(0),
                            Style.primaryColor.withOpacity(0.26)
                          ],
                        ),
                      ),
                      child: Container(
                        width: MediaQuery.sizeOf(context).width,
                        height: MediaQuery.sizeOf(context).height,
                        foregroundDecoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Style.black.withOpacity(0.4),
                              Style.black.withOpacity(0.4)
                            ],
                          ),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: e,
                          width: MediaQuery.sizeOf(context).width,
                          height: MediaQuery.sizeOf(context).height,
                          fit: BoxFit.cover,
                          progressIndicatorBuilder: (context, url, progress) {
                            return const ImageShimmer(
                              isCircle: false,
                              size: 0,
                            );
                          },
                          errorWidget: (context, url, error) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Style.greyColor,
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                FlutterRemix.image_line,
                                color: Style.black,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: EdgeInsets.all(16.r),
                        child: Column(
                          children: [
                            const Spacer(),
                            Text(
          titles[image.indexOf(e)]['text'], // Replace with 'text1'
          style: titles[image.indexOf(e)]['style'], // Replace with 'style1'
        ),
                            24.verticalSpace,
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            pageController.previousPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeIn);
                          },
                          child: Container(
                            height: MediaQuery.sizeOf(context).height,
                            width: MediaQuery.sizeOf(context).width / 2,
                            color: Style.transparent,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeIn);
                          },
                          child: Container(
                            height: MediaQuery.sizeOf(context).height,
                            width: MediaQuery.sizeOf(context).width / 2,
                            color: Style.transparent,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      right: 16.w,
                      top: 48.h,
                      child: GestureDetector(
                        onTap: () {
                          context.router.maybePop();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            FlutterRemix.close_fill,
                            color: Style.white,
                            size: 30.r,
                          ),
                        ),
                      ),
                    ),
                  ],
                ))
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Container(
                  height: 4.h,
                  width: MediaQuery.sizeOf(context).width,
                  margin: EdgeInsets.only(left: 20.w, bottom: 10.h),
                  child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        return AnimatedContainer(
                          margin: EdgeInsets.only(right: 8.w),
                          height: 4.h,
                          width: (MediaQuery.sizeOf(context).width - 60.w) / 3,
                          decoration: BoxDecoration(
                            color: state.currentIndex >= index
                                ? Style.primaryColor
                                : Style.white,
                            borderRadius: BorderRadius.circular(122.r),
                          ),
                          duration: const Duration(milliseconds: 500),
                          child: state.currentIndex == index
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(122.r),
                            child: LinearProgressIndicator(
                              value: controller.value,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Style.primaryColor),
                              backgroundColor: Style.white,
                            ),
                          )
                              : state.currentIndex > index
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(122.r),
                            child: const LinearProgressIndicator(
                              value: 1,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Style.primaryColor),
                              backgroundColor: Style.white,
                            ),
                          )
                              : const SizedBox.shrink(),
                        );
                      }),
                ),
              ),
            ),
          ],
        ));
  }
}