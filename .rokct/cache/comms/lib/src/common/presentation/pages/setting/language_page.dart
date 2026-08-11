import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/application/language/language_provider.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/keyboard_dismisser.dart';
import 'package:base_sdk/src/presentation/components/loading.dart';
import 'package:base_sdk/src/presentation/components/select_item.dart';
import 'package:base_sdk/src/presentation/components/title_icon.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

class LanguageScreen extends ConsumerStatefulWidget {
  final VoidCallback onSave;

  const LanguageScreen({super.key, required this.onSave});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LanguagePageState();
}

class _LanguagePageState extends ConsumerState<LanguageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(languageProvider.notifier).getLanguages(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isLtr = LocalStorage.getLangLtr();
    final event = ref.read(languageProvider.notifier);
    final state = ref.watch(languageProvider);
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: KeyboardDismisser(
        child: Container(
          decoration: BoxDecoration(
            color: AppStyle.bgGrey.withOpacity(0.96),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
            ),
          ),
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height *
                0.3, // Use only 30% of screen height
          ),
          child: state.isLoading
              ? const Loading()
              : Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        8.verticalSpace,
                        Center(
                          child: Container(
                            height: 4.h,
                            width: 48.w,
                            decoration: BoxDecoration(
                              color: AppStyle.dragElement,
                              borderRadius: BorderRadius.all(
                                Radius.circular(40.r),
                              ),
                            ),
                          ),
                        ),
                        24.verticalSpace,
                        TitleAndIcon(
                          title: AppHelpers.getTranslation(TrKeys.language),
                          paddingHorizontalSize: 0,
                          titleSize: 18,
                        ),
                        24.verticalSpace,
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.list.length,
                          itemBuilder: (context, index) {
                            return SelectItem(
                              onTap: () {
                                event.change(index);
                              },
                              isActive: state.index == index,
                              title: state.list[index].title ?? "",
                            );
                          },
                        ),
                        CustomButton(
                          title: AppHelpers.getTranslation(TrKeys.save),
                          onPressed: () {
                            ref
                                .read(languageProvider.notifier)
                                .makeSelectedLang(context);
                            widget.onSave();
                          },
                        ),
                        36.verticalSpace,
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
