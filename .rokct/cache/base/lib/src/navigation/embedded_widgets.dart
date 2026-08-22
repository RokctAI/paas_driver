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


import 'package:base_sdk/src/models/data/bonus_data.dart';
import 'package:base_sdk/src/models/data/cart_data.dart';
import 'package:base_sdk/src/models/data/order_active_model.dart';
import 'package:base_sdk/src/models/data/order_body_data.dart';
import 'package:base_sdk/src/models/data/product_data.dart';
import 'package:base_sdk/src/models/data/saved_card.dart';
import 'package:flutter/widgets.dart';

/// Cross-SDK widget indirection.
///
/// Legacy customer UI composes widgets across feature boundaries (product
/// modal inside search results, payment sheet inside checkout, ...). Feature
/// SDKs must not import each other, so consumers call these registry methods
/// and the host app supplies an implementation returning the real widgets.
abstract class EmbeddedWidgets {
  static EmbeddedWidgets I = _UnsetEmbeddedWidgets();

  Widget becomeDriverPage();
  Widget bonusScreen({required BonusModel? bonus});
  Widget cartClearDialog({required VoidCallback cancel, required VoidCallback clear, bool? isLoading});
  Widget cartOrderItem({required VoidCallback add, required VoidCallback remove, required CartDetail? cart, bool? isActive, Detail? cartTwo, bool? isOwn, String? symbol, bool? isAddComment});
  Widget chatPage({required String roleId, required String name});
  Widget introPage();
  Widget languageScreen({required VoidCallback onSave});
  Widget loanScreen();
  Widget orderMap({required dynamic markers, required dynamic latLng, required dynamic polylineCoordinates, required bool isLoading});
  Widget payFastWebView({required String url, Function(bool)? onComplete, Function(String, Map<String, String>)? onTokenCaptured, dynamic preloadedController});
  Widget paymentScreen({OrderBodyData? orderData, required Function(bool) onPaymentComplete, ScrollController? scrollController, bool? tokenizeOnly});
  Widget phoneVerify();
  Widget policyPage();
  Widget productScreen({String? productId, ProductData? data, String? cartId, required ScrollController controller});
  Widget resetPasswordPage();
  Widget savedCardsWidget({required Function(SavedCardModel?) onCardSelected, SavedCardModel? initialSelectedCard, bool? hideManagement});
  Widget termPage();
  void preloadPayFastWebView(BuildContext context, String paymentUrl);
}

class _UnsetEmbeddedWidgets implements EmbeddedWidgets {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError(
          'EmbeddedWidgets.I has not been set by the host app. Assign an '
          'implementation in main() before running the app.');
}
