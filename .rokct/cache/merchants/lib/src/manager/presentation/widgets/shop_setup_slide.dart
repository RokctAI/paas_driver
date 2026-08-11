import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:flutter/material.dart';

/// Consumer-owned interface for what the shop-setup step persists: the shop
/// identity a freshly registered seller typed (name, and optionally phone +
/// address). Mirrors lms_sdk's `StudentSchoolCapture` contract — merchants_sdk
/// declares what it needs in its own terms and the manager host supplies the
/// adapter (ADR-005), so this widget never learns how the create call is made.
///
/// Implementations should not throw for expected failures: registration
/// always continues past this step, so a failed create never traps a new
/// seller — the restaurant tab handles the no-shop state and offers the
/// details again.
abstract class SellerShopSetupCapture {
  Future<void> submitShop({
    required String name,
    String? phone,
    String? address,
  });
}

/// The registration shop-setup step for the manager composition: the minimal
/// "become a seller" capture (shop name — the one field the backend's
/// create endpoint requires — plus phone and address), replacing the retired
/// host `CreateShopPage` funnel for the registration path only. Everything
/// else that page collected (images, tax, delivery settings, prices,
/// documents) is management-page material, editable later through the
/// restaurant tab's edit modal over `update_shop`.
///
/// Lives in merchants_sdk because the shop is a merchants concern; the host
/// wires it into auth_sdk's post-register pipeline as a `RegistrationStep`
/// (manifest `registration_steps`) and owns advancing the flow via
/// [onContinue] — this widget never learns the registration shell's types.
class ShopSetupSlide extends StatefulWidget {
  final SellerShopSetupCapture capture;

  /// Prefill for the phone field — the registration pipeline hands the step
  /// the freshly registered account, whose phone is usually the shop's.
  final String? initialPhone;

  /// Called after the (best-effort) create so the host can advance the flow.
  final VoidCallback onContinue;

  const ShopSetupSlide({
    super.key,
    required this.capture,
    required this.onContinue,
    this.initialPhone,
  });

  @override
  State<ShopSetupSlide> createState() => _ShopSetupSlideState();
}

class _ShopSetupSlideState extends State<ShopSetupSlide> {
  final TextEditingController _name = TextEditingController();
  late final TextEditingController _phone =
      TextEditingController(text: widget.initialPhone ?? '');
  final TextEditingController _address = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Rebuild so the Continue button en/disables as the name changes.
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (_submitting || name.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await widget.capture.submitShop(
        name: name,
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      );
    } catch (e) {
      // Same rule as lms's school slide: a failed write must never trap a
      // new seller in the flow — the restaurant tab offers the shop details
      // again later.
      debugPrint('==> ShopSetupSlide: shop submit failed: $e');
    }
    if (!mounted) return;
    setState(() => _submitting = false);
    widget.onContinue();
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        filled: true,
        fillColor: AppStyle.cardDarkAlt,
        hintText: hint,
        hintStyle: TextStyle(fontSize: 15, color: AppStyle.textDarkSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppStyle.strokeDark, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppStyle.primary, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppStyle.strokeDark, width: 0.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    // Same rounded sheet card as lms's registration slides: the registration
    // scaffold owns positioning, this returns just the card.
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppStyle.strokeDark, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppHelpers.getTranslation(TrKeys.setUpYourShop),
            textAlign: TextAlign.center,
            style: AppStyle.interBold(size: 22, color: AppStyle.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            AppHelpers.getTranslation(TrKeys.shopSetupExplainer),
            textAlign: TextAlign.center,
            style: AppStyle.interNormal(
                size: 13, color: AppStyle.textDarkSecondary),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _name,
            enabled: !_submitting,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            style: TextStyle(fontSize: 15, color: AppStyle.textPrimary),
            decoration:
                _decoration(AppHelpers.getTranslation(TrKeys.shopName)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            enabled: !_submitting,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            style: TextStyle(fontSize: 15, color: AppStyle.textPrimary),
            decoration:
                _decoration(AppHelpers.getTranslation(TrKeys.phoneNumber)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            enabled: !_submitting,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            style: TextStyle(fontSize: 15, color: AppStyle.textPrimary),
            decoration:
                _decoration(AppHelpers.getTranslation(TrKeys.address)),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppStyle.primary,
                foregroundColor: AppStyle.blackColor,
                disabledBackgroundColor: AppStyle.primary.withOpacity(0.35),
                disabledForegroundColor: AppStyle.blackColor.withOpacity(0.6),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed:
                  (_name.text.trim().isEmpty || _submitting) ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      AppHelpers.getTranslation(TrKeys.continueText),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
