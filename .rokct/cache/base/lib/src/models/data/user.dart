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


import 'package:base_sdk/src/models/data/address_new_data.dart';

class UserModel {
  UserModel({
    String? id,
    String? uuid,
    String? firstname,
    String? lastname,
    String? referral,
    String? email,
    String? phone,
    String? birthday,
    String? gender,
    String? emailVerifiedAt,
    String? registeredAt,
    bool? active,
    String? img,
    String? role,
    String? password,
    String? confirmPassword,
    List<AddressNewModel>? addresses,
    bool? isDemoAccount,
  }) {
    _id = id;
    _uuid = uuid;
    _firstname = firstname;
    _lastname = lastname;
    _referral = referral;
    _email = email;
    _phone = phone;
    _birthday = birthday;
    _gender = gender;
    _emailVerifiedAt = emailVerifiedAt;
    _registeredAt = registeredAt;
    _active = active;
    _img = img;
    _role = role;
    _password = password;
    _addresses = addresses;
    _confirmPassword = confirmPassword;
    _isDemoAccount = isDemoAccount;
  }

  UserModel.fromJson(dynamic json) {
    _id = json['id']?.toString();
    _uuid = json['uuid'];
    _firstname = json['firstname'];
    _lastname = json['lastname'];
    _email = json['email'];
    _phone = json['phone'];
    _birthday = json['birthday'];
    _gender = json['gender'];
    _emailVerifiedAt = json['email_verified_at'];
    _registeredAt = json['registered_at'];
    _active = json['active'].runtimeType == int
        ? (json['active'] != 0)
        : json['active'];
    _img = json['img'];
    _role = json['role'];
    _isDemoAccount = parseDemoAccountMarker(json['is_demo_account']);
    if (json['addresses'] != null) {
      _addresses = [];
      json['addresses'].forEach((v) {
        _addresses?.add(AddressNewModel.fromJson(v));
      });
    }
  }

  String? _id;
  String? _uuid;
  String? _firstname;
  String? _lastname;
  String? _referral;
  String? _email;
  String? _phone;
  String? _birthday;
  String? _gender;
  String? _emailVerifiedAt;
  String? _registeredAt;
  bool? _active;
  String? _img;
  String? _role;
  String? _password;
  String? _confirmPassword;
  List<AddressNewModel>? _addresses;
  bool? _isDemoAccount;

  UserModel copyWith({
    String? id,
    String? uuid,
    String? firstname,
    String? lastname,
    String? referral,
    String? email,
    String? phone,
    String? birthday,
    String? gender,
    String? emailVerifiedAt,
    String? registeredAt,
    bool? active,
    String? img,
    String? role,
    String? password,
    String? conPassword,
    List<AddressNewModel>? addresses,
    bool? isDemoAccount,
  }) =>
      UserModel(
        id: id ?? _id,
        uuid: uuid ?? _uuid,
        firstname: firstname ?? _firstname,
        lastname: lastname ?? _lastname,
        referral: referral ?? _referral,
        email: email ?? _email,
        phone: phone ?? _phone,
        birthday: birthday ?? _birthday,
        gender: gender ?? _gender,
        emailVerifiedAt: emailVerifiedAt ?? _emailVerifiedAt,
        registeredAt: registeredAt ?? _registeredAt,
        active: active ?? _active,
        img: img ?? _img,
        role: role ?? _role,
        confirmPassword: conPassword ?? _confirmPassword,
        password: password ?? _password,
        addresses: addresses ?? _addresses,
        isDemoAccount: isDemoAccount ?? _isDemoAccount,
      );

  String? get id => _id;

  String? get uuid => _uuid;

  String? get firstname => _firstname;

  String? get lastname => _lastname;

  String? get referral => _referral;

  String? get email => _email;

  String? get phone => _phone;

  String? get birthday => _birthday;

  String? get gender => _gender;

  String? get emailVerifiedAt => _emailVerifiedAt;

  String? get registeredAt => _registeredAt;

  bool? get active => _active;

  String? get img => _img;

  String? get role => _role;

  List<AddressNewModel>? get addresses => _addresses;

  String? get password => _password;

  String? get conPassword => _confirmPassword;

  /// The backend's server-asserted demo marker (`is_demo_account` on the
  /// login payload's user). True only for the real accounts the
  /// production backend flags as demo; false when the key is absent, so
  /// every existing payload reads as a real account. The login flow flips
  /// `DemoSession` on it - never on the address or the password.
  bool get isDemoAccount => _isDemoAccount ?? false;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['uuid'] = _uuid;
    map['firstname'] = _firstname;
    map['lastname'] = _lastname;
    map['referral'] = _referral;
    map['email'] = _email;
    map['phone'] = _phone;
    map['birthday'] = _birthday;
    map['gender'] = _gender;
    map['email_verified_at'] = _emailVerifiedAt;
    map['registered_at'] = _registeredAt;
    map['active'] = _active;
    map['img'] = _img;
    map['role'] = _role;
    map['is_demo_account'] = _isDemoAccount;
    if (_addresses != null) {
      map['addresses'] = _addresses?.map((v) => v.toJson()).toList();
    }
    return map;
  }

  Map<String, dynamic> toJsonForSignUp({typeFirebase = false}) => {
        "firstname": _firstname,
        if (_lastname?.isNotEmpty ?? false) "lastname": _lastname,
        if (_phone?.isNotEmpty ?? false) "phone": _phone?.replaceAll('+', ""),
        if (_email?.isNotEmpty ?? false) "email": _email,
        if (_password?.isNotEmpty ?? false) "password": _password,
        if (_confirmPassword?.isNotEmpty ?? false)
          "password_conformation": _confirmPassword,
        if (_referral?.isNotEmpty ?? false) 'referral': _referral,
        if (typeFirebase) "type": "firebase",
      };
}

/// Decodes the backend's `is_demo_account` marker. Frappe Check fields
/// arrive as 0/1, JSON booleans as true/false; anything else (absent,
/// null, an unexpected string) is NOT a demo account - the marker must
/// only ever be asserted, never inferred.
bool parseDemoAccountMarker(dynamic raw) {
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  return false;
}
