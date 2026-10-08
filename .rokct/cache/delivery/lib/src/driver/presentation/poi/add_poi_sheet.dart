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

// ADD A PLACE — the sheet a driver files a point of interest from.
//
// A MODAL SHEET AND NOT A ROUTE, on purpose: he opens it while passing,
// from the load card or from the sell screen, and lands back exactly where
// he was. Nothing about it belongs in the host's route table.
//
// It asks for what the place is called, what kind of place it is, the kind
// in his own words when he picks the catch-all, and a note for the next
// driver. WHERE IT IS is not asked — it is his current fix, because a point
// he types coordinates into is a point he was not standing at.
//
// WHICH SHOP IT IS FOR is asked ONLY when the driver is the one who knows.
// Ray, 2026-09-18: "driver doesnt own a shop, he either deliver for every
// shop in the platform or specific ones if choosen". So:
//
//   * OPENED OFF A LOAD ([shop] given): no question. The load names its own
//     shop and the sheet sends it, which is also what keeps a driver with
//     two open loads from meeting an ask he has no way to answer.
//   * ONE SHOP HE DELIVERS FOR: no question either. It is filled in
//     silently, because a picker with one entry is not a choice.
//   * SEVERAL: the picker, fed by `api.poi.get_my_poi_shops`. The server
//     refuses to guess which round a point belongs to, and it is right to:
//     guessing would file the round's knowledge against the wrong shop.
//
// WHO RUNS THE PLACE is asked here too, because the driver is standing in
// front of the person. He types a first name, a last name and a number, and
// the number is the part that matters: as he leaves the field the sheet asks
// the server who holds it (`api.poi.lookup_poi_owner`) and, when somebody
// does, fills the name in and says how many places that person already runs
// — so one owner with four spazas is one account, not four.
//
// THE FIRST NAME IS REQUIRED FOR A PLACE THAT IS A BUSINESS (a spaza shop,
// a stockist, the catch-all), and the commit stays inert without it rather
// than posting a call the server will refuse. It is optional for a landmark
// or a gate, which are nobody's.
//
// AND THE ONE QUESTION THE SERVER ASKS BACK. If the number is on file under
// another first name, the create writes NOTHING and answers a clash; the
// sheet then asks the driver whether it is the same person and, only on a
// yes, re-sends with `owner_confirmed_user`. That confirmation is a tap he
// took, never a default.
//
// WHAT IT STILL NEVER ASKS is whether the point is platform-wide, and which
// ACCOUNT the owner is. The first is an admin's flag on his profile; the
// second is the server's answer to the number. Offering either here would be
// offering him a decision he does not have.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/text_fields/outline_bordered_text_field.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'package:delivery_sdk/src/driver/application/poi/poi_provider.dart';
import 'package:delivery_sdk/src/driver/application/poi/poi_state.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_poi.dart';

class AddPoiSheet extends ConsumerStatefulWidget {
  const AddPoiSheet({super.key, this.shop, this.onFiled});

  /// The shop this place belongs to, when the CALLER already knows — the
  /// load he is working. Given, the sheet asks nothing about the shop and
  /// sends this one; a driver carrying two open loads therefore never
  /// meets an ambiguity, because the card he tapped answered it.
  final String? shop;

  /// Handed the point the server answered with — the one just filed, or
  /// the one that already stood there. The caller decides what to do with
  /// it; this sheet only closes.
  final void Function(DriverPoi point)? onFiled;

  /// Opens the sheet over whatever is on screen.
  static void open(
    BuildContext context, {
    String? shop,
    void Function(DriverPoi point)? onFiled,
  }) {
    AppHelpers.showCustomModalBottomSheet(
      context: context,
      isDarkMode: (Theme.of(context).brightness == Brightness.dark),
      modal: AddPoiSheet(shop: shop, onFiled: onFiled),
    );
  }

  @override
  ConsumerState<AddPoiSheet> createState() => _AddPoiSheetState();
}

class _AddPoiSheetState extends ConsumerState<AddPoiSheet> {
  final TextEditingController _label = TextEditingController();
  final TextEditingController _customType = TextEditingController();
  final TextEditingController _note = TextEditingController();
  final TextEditingController _ownerFirst = TextEditingController();
  final TextEditingController _ownerLast = TextEditingController();
  final TextEditingController _ownerPhone = TextEditingController();
  String? _type;

  /// True once the driver has said the owner on file is NOT the person in
  /// front of him, so the prefilled name is his to type over again. The
  /// lookup's own answer is cleared with it, which is what takes the
  /// "existing owner" line off the sheet.
  bool _ownerNameIsMine = false;

  /// The number the last lookup was for. A blur on an UNCHANGED number asks
  /// nothing and overwrites nothing — otherwise tabbing back through the
  /// field would undo a name the driver has just corrected.
  String? _lookedUpNumber;

  /// The shop he picked, when the sheet had to ask. Null while the answer
  /// is the caller's [AddPoiSheet.shop] or the single shop he delivers for.
  String? _pickedShop;

  /// The load's own shop wins over everything: on a load there is nothing
  /// to ask and nothing to pick.
  bool get _shopIsKnown => (widget.shop ?? '').trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(driverPoiProvider.notifier);
      notifier.loadTypes(context: context);
      // One sheet must never open holding the last one's owner.
      notifier.clearOwner();
      // Only off a load. On one, the shop is already answered and asking
      // the server which shops he delivers for would be a read nobody
      // reads.
      if (!_shopIsKnown) notifier.loadMyShops(context: context);
    });
  }

  @override
  void dispose() {
    _label.dispose();
    _customType.dispose();
    _note.dispose();
    _ownerFirst.dispose();
    _ownerLast.dispose();
    _ownerPhone.dispose();
    super.dispose();
  }

  bool _takesCustomType(List<DriverPoiType> types) {
    for (final type in types) {
      if (type.id == _type) return type.takesCustomType;
    }
    return false;
  }

  bool _canFile(DriverPoiState state) {
    if (_label.text.trim().isEmpty) return false;
    if ((_type ?? '').isEmpty) return false;
    // The catch-all type is not an answer by itself: without the words it
    // would file a place nobody can tell apart from any other.
    if (_takesCustomType(state.types) && _customType.text.trim().isEmpty) {
      return false;
    }
    // A place that IS a business is not filed without the name of whoever
    // runs it — the same rule the server applies, mirrored so the commit
    // stays inert rather than posting a call it knows will be refused.
    if (_needsOwner(state.types) && _ownerFirst.text.trim().isEmpty) {
      return false;
    }
    // Several shops and none picked: the server would refuse, so the
    // commit stays inert rather than sending a call it knows the answer to.
    if (_shopFor(state) == null && state.mustChooseShop) return false;
    return true;
  }

  /// Whether the kind of place he picked needs an owner's first name.
  bool _needsOwner(List<DriverPoiType> types) {
    for (final type in types) {
      if (type.id == _type) return type.needsOwner;
    }
    return false;
  }

  /// The shop this place is about to be filed against, or null when nobody
  /// has said. The load first, then his one shop, then his own pick.
  String? _shopFor(DriverPoiState state) {
    if (_shopIsKnown) return widget.shop!.trim();
    final picked = (_pickedShop ?? '').trim();
    if (picked.isNotEmpty) return picked;
    return state.settledShopId;
  }

  /// WHICH SHOP, asked only when the driver is the one who knows.
  ///
  /// Null on a load (the load answered it) and null when he delivers for
  /// exactly one shop (there is nothing to choose). Otherwise the list of
  /// shops he delivers for — every shop on the platform when the server
  /// says he is unrestricted, which is the same list and the same tap.
  Widget? _shopPicker(DriverPoiState state) {
    if (_shopIsKnown) return null;
    if (!state.mustChooseShop) return null;
    final shops = state.shopChoices?.shops ?? const <DriverPoiShop>[];
    return Column(
      key: const Key('addPoiShopPicker'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppHelpers.getTranslation('which_shop_is_this_place_for'),
          style: AppStyle.interRegular(
            size: 12,
            color: AppStyle.faintFor(Theme.of(context).brightness),
          ),
        ),
        8.verticalSpace,
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 200.h),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final shop in shops)
                  _ShopRow(
                    shop: shop,
                    selected: shop.id == _pickedShop,
                    onTap: () => setState(() => _pickedShop = shop.id),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// WHO RUNS THE PLACE. A first name, a last name and the number — and the
  /// number is the one that identifies the person, which is why leaving it
  /// asks the server about it.
  Widget _ownerSection(DriverPoiState state) {
    final owner = state.ownerLookup;
    final onFile = state.ownerIsOnFile && !_ownerNameIsMine;
    return Column(
      key: const Key('addPoiOwner'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppHelpers.getTranslation(
            _needsOwner(state.types)
                ? 'who_runs_this_place'
                : 'who_runs_this_place_optional',
          ),
          style: AppStyle.interRegular(
            size: 12,
            color: AppStyle.faintFor(Theme.of(context).brightness),
          ),
        ),
        8.verticalSpace,
        // The number first: it is what the lookup answers from, and an
        // owner already on file fills the two name fields below it.
        Focus(
          // ON LEAVING THE FIELD, not on every keystroke: a number is only
          // a number once he has finished typing it, and a read per digit
          // would be nine reads and nine wrong answers.
          onFocusChange: (hasFocus) {
            if (hasFocus) return;
            _lookUpOwner();
          },
          child: OutlinedBorderTextField(
            key: const Key('addPoiOwnerPhone'),
            label: AppHelpers.getTranslation('owners_phone_number'),
            textController: _ownerPhone,
            inputType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            isSuccess: onFile,
          ),
        ),
        if (onFile && owner != null) ...[
          8.verticalSpace,
          _OwnerOnFileLine(
            owner: owner,
            onNotThem: () {
              setState(() => _ownerNameIsMine = true);
              ref.read(driverPoiProvider.notifier).clearOwner();
            },
          ),
        ],
        12.verticalSpace,
        OutlinedBorderTextField(
          key: const Key('addPoiOwnerFirst'),
          label: AppHelpers.getTranslation('owners_first_name'),
          textController: _ownerFirst,
          textCapitalization: TextCapitalization.words,
          // READ-ONLY WHILE THE ACCOUNT IS ON FILE, because this is the
          // name the platform already holds for that number. "Not this
          // person" hands it back to him.
          readOnly: onFile,
          onChanged: (_) => setState(() {}),
        ),
        12.verticalSpace,
        OutlinedBorderTextField(
          key: const Key('addPoiOwnerLast'),
          label: AppHelpers.getTranslation('owners_last_name'),
          textController: _ownerLast,
          textCapitalization: TextCapitalization.words,
          readOnly: onFile,
        ),
      ],
    );
  }

  /// Asks the server who the typed number belongs to, and fills the name in
  /// when somebody holds it.
  ///
  /// The prefill only ever happens on a FOUND owner and only while the
  /// driver has not said the name is his to type: what the platform holds
  /// for a number is better than what a driver half-remembers, but it is
  /// still his call at the door.
  Future<void> _lookUpOwner() async {
    final number = _ownerPhone.text.trim();
    final notifier = ref.read(driverPoiProvider.notifier);
    if (number.isEmpty) {
      _lookedUpNumber = null;
      notifier.clearOwner();
      if (mounted) setState(() {});
      return;
    }
    if (number == _lookedUpNumber) return;
    _lookedUpNumber = number;
    await notifier.lookupOwner(number);
    if (!mounted) return;
    final owner = ref.read(driverPoiProvider).ownerLookup;
    setState(() {
      if (owner?.found != true) return;
      // A fresh number is a fresh question: whatever he said about the
      // LAST owner does not apply to this one.
      _ownerNameIsMine = false;
      _ownerFirst.text = (owner!.firstName ?? '').trim();
      _ownerLast.text = (owner.lastName ?? '').trim();
    });
  }

  /// "That number is on file under X — same person?"
  ///
  /// Asked only when the server said so, and answered only by a tap. A
  /// silent yes here would let a driver quietly rename somebody else's
  /// account, which is the whole reason the server refuses in the first
  /// place.
  Future<bool> _askIfSamePerson(DriverPoiOwnerClash clash) async {
    final onFile = (clash.firstName ?? '').trim();
    final answer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('addPoiOwnerClashDialog'),
        backgroundColor: AppStyle.cardFor(Theme.of(context).brightness),
        title: Text(
          AppHelpers.getTranslation('is_this_the_same_person'),
          style: AppStyle.interSemi(size: 16, color: AppStyle.inkFor(Theme.of(context).brightness)),
        ),
        content: Text(
          onFile.isEmpty
              ? AppHelpers.getTranslation(
                  'that_number_is_already_on_file_under_another_name')
              : '${AppHelpers.getTranslation('that_number_is_already_on_file_under')} '
                  '$onFile.',
          style: AppStyle.interRegular(
            size: 13,
            color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
          ),
        ),
        actions: [
          TextButton(
            key: const Key('addPoiOwnerClashCancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              AppHelpers.getTranslation('no_let_me_check_the_number'),
              style: AppStyle.interSemi(
                size: 14,
                color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
              ),
            ),
          ),
          TextButton(
            key: const Key('addPoiOwnerClashConfirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              AppHelpers.getTranslation('yes_same_person'),
              style: AppStyle.interSemi(size: 14, color: AppStyle.primary),
            ),
          ),
        ],
      ),
    );
    return answer == true;
  }

  Future<void> _file({bool ownerConfirmed = false}) async {
    final notifier = ref.read(driverPoiProvider.notifier);
    final point = await notifier.create(
          label: _label.text,
          type: _type ?? '',
          customType: _customType.text,
          note: _note.text,
          shop: _shopFor(ref.read(driverPoiProvider)),
          ownerFirstName: _ownerFirst.text,
          ownerLastName: _ownerLast.text,
          ownerPhone: _ownerPhone.text,
          ownerConfirmedUser: ownerConfirmed,
          context: context,
        );
    if (!mounted) return;
    if (point == null) {
      // The ONE null that is not a failure: the number is held under
      // another first name and nothing was written. Ask him, and re-send
      // only if he says it is the same person.
      final clash = ref.read(driverPoiProvider).ownerClash;
      if (clash == null || ownerConfirmed) return;
      if (!await _askIfSamePerson(clash)) return;
      if (!mounted) return;
      await _file(ownerConfirmed: true);
      return;
    }
    if (point.wasAlreadyThere) {
      AppHelpers.showCheckTopSnackBar(
        context,
        '${AppHelpers.getTranslation('this_place_is_already_on_the_map')} '
        '${point.title}',
      );
    }
    widget.onFiled?.call(point);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driverPoiProvider);
    final types = state.types;
    final shopPicker = _shopPicker(state);
    return Padding(
      key: const Key('addPoiSheet'),
      padding: EdgeInsets.fromLTRB(
        16.w,
        20.h,
        16.w,
        MediaQuery.paddingOf(context).bottom + 20.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppHelpers.getTranslation('add_a_place'),
            style: AppStyle.interSemi(size: 18, color: AppStyle.inkFor(Theme.of(context).brightness)),
          ),
          6.verticalSpace,
          Text(
            AppHelpers.getTranslation('the_next_driver_on_this_round_sees_it'),
            style: AppStyle.interRegular(
              size: 12,
              color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
            ),
          ),
          16.verticalSpace,
          OutlinedBorderTextField(
            key: const Key('addPoiLabel'),
            label: AppHelpers.getTranslation('what_is_this_place_called'),
            textController: _label,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          16.verticalSpace,
          Text(
            AppHelpers.getTranslation('what_kind_of_place'),
            style: AppStyle.interRegular(
              size: 12,
              color: AppStyle.faintFor(Theme.of(context).brightness),
            ),
          ),
          8.verticalSpace,
          if (types.isEmpty)
            Text(
              key: const Key('addPoiNoTypes'),
              AppHelpers.getTranslation('place_types_are_still_loading'),
              style: AppStyle.interRegular(
                size: 12,
                color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
              ),
            )
          else
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final type in types)
                  _TypeChip(
                    type: type,
                    selected: type.id == _type,
                    onTap: () => setState(() {
                      _type = type.id;
                      if (!type.takesCustomType) _customType.clear();
                    }),
                  ),
              ],
            ),
          if (_takesCustomType(types)) ...[
            12.verticalSpace,
            OutlinedBorderTextField(
              key: const Key('addPoiCustomType'),
              label: AppHelpers.getTranslation('what_kind_of_place_is_this'),
              textController: _customType,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
            ),
          ],
          if (shopPicker != null) ...[
            16.verticalSpace,
            shopPicker,
          ],
          16.verticalSpace,
          _ownerSection(state),
          16.verticalSpace,
          OutlinedBorderTextField(
            key: const Key('addPoiNote'),
            label: AppHelpers.getTranslation('note_optional'),
            textController: _note,
            textCapitalization: TextCapitalization.sentences,
          ),
          20.verticalSpace,
          CustomButton(
            key: const Key('addPoiConfirm'),
            title: AppHelpers.getTranslation('add_this_place'),
            background: AppStyle.primary,
            textColor: AppStyle.blackColor,
            isLoading: state.isSubmitting,
            onPressed: _canFile(state) && !state.isSubmitting ? _file : null,
          ),
        ],
      ),
    );
  }
}

/// THE OWNER THE PLATFORM ALREADY HOLDS FOR THIS NUMBER.
///
/// It says his name and how many places he already runs, because that count
/// is the thing a driver could not otherwise know and the thing that makes
/// the link worth making: this is the fourth spaza of somebody who runs
/// three. And it offers the way out, since the person at the door is the
/// authority on who he is, not the account.
class _OwnerOnFileLine extends StatelessWidget {
  const _OwnerOnFileLine({required this.owner, required this.onNotThem});

  final DriverPoiOwner owner;
  final VoidCallback onNotThem;

  @override
  Widget build(BuildContext context) {
    final named = owner.fullName.isEmpty
        ? AppHelpers.getTranslation('this_number')
        : owner.fullName;
    final places = owner.placesCount;
    return Column(
      key: const Key('addPoiOwnerOnFile'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Remix.user_line, size: 14.r, color: AppStyle.primary),
            6.horizontalSpace,
            Expanded(
              child: Text(
                '${AppHelpers.getTranslation('existing_owner')}: $named'
                '${places > 0 ? ' · $places '
                    '${AppHelpers.getTranslation(places == 1 ? 'place' : 'places')}' : ''}',
                style: AppStyle.interSemi(size: 12, color: AppStyle.primary),
              ),
            ),
          ],
        ),
        TextButton(
          key: const Key('addPoiOwnerNotThem'),
          onPressed: onNotThem,
          child: Text(
            AppHelpers.getTranslation('not_this_person'),
            style: AppStyle.interRegular(
              size: 12,
              color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
            ),
          ),
        ),
      ],
    );
  }
}

/// ONE SHOP HE DELIVERS FOR, as a row he taps.
///
/// A row and not a chip: a shop's name is a whole name and wraps badly in a
/// Wrap, and an unrestricted driver's list is the platform's — long enough
/// that it has to scroll rather than reflow.
class _ShopRow extends StatelessWidget {
  const _ShopRow({
    required this.shop,
    required this.selected,
    required this.onTap,
  });

  final DriverPoiShop shop;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Material(
        color: selected ? AppStyle.primary : AppStyle.cardAltFor(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(10.r),
        child: InkWell(
          key: Key('addPoiShop-${shop.id}'),
          borderRadius: BorderRadius.circular(10.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    shop.label,
                    style: AppStyle.interSemi(
                      size: 13,
                      color: selected
                          ? AppStyle.inkFor(Theme.of(context).brightness)
                          : AppStyle.inkFor(Theme.of(context).brightness),
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Remix.check_line,
                    size: 16.r,
                    color: AppStyle.inkFor(Theme.of(context).brightness),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One kind-of-place chip. A chip for a type the customer map shows says
/// so, because filing one of those is filing something the public will see.
class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final DriverPoiType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppStyle.primary : AppStyle.cardAltFor(Theme.of(context).brightness),
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        key: Key('addPoiType-${type.id}'),
        borderRadius: BorderRadius.circular(10.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                type.label,
                style: AppStyle.interSemi(
                  size: 13,
                  color: selected ? AppStyle.inkFor(Theme.of(context).brightness) : AppStyle.inkFor(Theme.of(context).brightness),
                ),
              ),
              if (type.customerVisible) ...[
                6.horizontalSpace,
                Icon(
                  Remix.eye_line,
                  size: 13.r,
                  color:
                      selected ? AppStyle.blackColor : AppStyle.faintFor(Theme.of(context).brightness),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
