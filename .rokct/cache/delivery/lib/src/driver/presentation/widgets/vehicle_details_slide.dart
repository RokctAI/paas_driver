import 'package:flutter/material.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

import 'package:delivery_sdk/src/driver/infrastructure/services/courier_helpers.dart';

/// Consumer-owned interface for what the vehicle-details step persists
/// (ADR-005; merchants_sdk's `SellerShopSetupCapture` precedent) —
/// delivery_sdk declares what it needs in its own terms and the driver host
/// supplies the adapter, so this widget never learns how the request-model
/// create call is made.
///
/// Implementations should not throw for expected failures: registration
/// always continues past this step, so a failed submit never traps a fresh
/// courier — the profile page offers the vehicle details again (edit car).
abstract class CourierVehicleCapture {
  Future<void> submitVehicle({
    required String type,
    required String brand,
    required String model,
    required String number,
    required String color,
    required String height,
    required String width,
    required String length,
    required String weight,
    String? imagePath,
  });
}

/// The registration vehicle-details step for the driver composition: the
/// legacy become-driver form's capture (type of technique, car brand, model,
/// state number, color, dimensions, weight, car photo — decision D5 scope:
/// exactly what the host page collected, no new document uploads), wired
/// into auth_sdk's post-register pipeline via this SDK's manifest
/// `registration_steps` entry.
class VehicleDetailsSlide extends StatefulWidget {
  final CourierVehicleCapture capture;

  /// Called after the (best-effort) submit so the host can advance the flow.
  final VoidCallback onContinue;

  const VehicleDetailsSlide({
    super.key,
    required this.capture,
    required this.onContinue,
  });

  @override
  State<VehicleDetailsSlide> createState() => _VehicleDetailsSlideState();
}

class _VehicleDetailsSlideState extends State<VehicleDetailsSlide> {
  final TextEditingController _brand = TextEditingController();
  final TextEditingController _model = TextEditingController();
  final TextEditingController _number = TextEditingController();
  final TextEditingController _color = TextEditingController();
  final TextEditingController _height = TextEditingController();
  final TextEditingController _width = TextEditingController();
  final TextEditingController _length = TextEditingController();
  final TextEditingController _weight = TextEditingController();
  String? _type;
  String? _imagePath;
  bool _submitting = false;

  /// The host become-driver page's fixed list — the wire values the
  /// `type_of_technique` field accepts.
  static const List<String> _typeKeys = [
    TrKeys.benzine,
    TrKeys.diesel,
    TrKeys.gas,
    TrKeys.motorbike,
    TrKeys.bike,
    TrKeys.foot,
  ];

  @override
  void initState() {
    super.initState();
    _brand.addListener(() => setState(() {}));
    _number.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [
      _brand, _model, _number, _color, _height, _width, _length, _weight
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _ready =>
      _type != null &&
      _brand.text.trim().isNotEmpty &&
      _number.text.trim().isNotEmpty &&
      !_submitting;

  Future<void> _submit() async {
    if (!_ready) return;
    setState(() => _submitting = true);
    try {
      await widget.capture.submitVehicle(
        type: _type!,
        brand: _brand.text.trim(),
        model: _model.text.trim(),
        number: _number.text.trim(),
        color: _color.text.trim(),
        height: _height.text.trim(),
        width: _width.text.trim(),
        length: _length.text.trim(),
        weight: _weight.text.trim(),
        imagePath: _imagePath,
      );
    } catch (e) {
      // Best-effort by contract: a failed write must never trap a fresh
      // courier in the flow - the profile page's edit-car modal offers the
      // details again later.
      debugPrint('==> VehicleDetailsSlide: vehicle submit failed: $e');
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

  Widget _field(TextEditingController controller, String trKey,
      {TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: !_submitting,
        keyboardType: keyboard,
        textInputAction: TextInputAction.next,
        style: TextStyle(fontSize: 15, color: AppStyle.textPrimary),
        decoration: _decoration(AppHelpers.getTranslation(trKey)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            AppHelpers.getTranslation(TrKeys.becomeDriver),
            textAlign: TextAlign.center,
            style: AppStyle.interBold(size: 22, color: AppStyle.textPrimary),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              initialValue: _type,
              decoration:
                  _decoration(AppHelpers.getTranslation(TrKeys.typeTechnique)),
              dropdownColor: AppStyle.cardDark,
              style: TextStyle(fontSize: 15, color: AppStyle.textPrimary),
              items: [
                for (final key in _typeKeys)
                  DropdownMenuItem(
                    value: key,
                    child: Text(AppHelpers.getTranslation(key)),
                  ),
              ],
              onChanged: _submitting
                  ? null
                  : (v) => setState(() => _type = v),
            ),
          ),
          _field(_brand, TrKeys.carBrand),
          _field(_model, TrKeys.carModels),
          _field(_number, TrKeys.stateNumber),
          _field(_color, TrKeys.color),
          Row(
            children: [
              Expanded(
                  child: _field(_height, TrKeys.height,
                      keyboard: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(
                  child: _field(_width, TrKeys.width,
                      keyboard: TextInputType.number)),
            ],
          ),
          Row(
            children: [
              Expanded(
                  child: _field(_length, TrKeys.length,
                      keyboard: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(
                  child: _field(_weight, TrKeys.kg,
                      keyboard: TextInputType.number)),
            ],
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppStyle.textPrimary,
              side: BorderSide(color: AppStyle.strokeDark, width: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _submitting
                ? null
                : () => CourierHelpers.openDialogImagePicker(
                      context: context,
                      onSuccess: (path) =>
                          setState(() => _imagePath = path.isEmpty ? null : path),
                    ),
            icon: const Icon(Icons.photo_camera_outlined, size: 18),
            label: Text(
              _imagePath == null
                  ? AppHelpers.getTranslation(TrKeys.carPicture)
                  : _imagePath!.split('/').last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
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
              onPressed: _ready ? _submit : null,
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
