import 'address_data.dart';
import 'package:base_sdk/src/models/data/currency_data.dart';

class UserData {
  UserData({
    int? id,
    String? uuid,
    String? firstname,
    String? lastname,
    String? email,
    String? phone,
    String? birthday,
    String? gender,
    bool? active,
    String? img,
    String? role,
    List<AddressData>? addresses,
    Wallet? wallet,

  }) {
    _id = id;
    _uuid = uuid;
    _firstname = firstname;
    _lastname = lastname;
    _email = email;
    _phone = phone;
    _birthday = birthday;
    _gender = gender;
    _active = active;
    _img = img;
    _role = role;
    _addresses = addresses;
    _wallet = wallet;

  }

  UserData.fromJson(dynamic json) {
    _id = json['id'];
    _uuid = json['uuid'];
    _firstname = json['firstname'];
    _lastname = json['lastname'];
    _email = json['email'];
    _phone = json['phone'];
    _birthday = json['birthday'];
    _gender = json['gender'];
    _active = json['active'].runtimeType == int
        ? (json['active'] != 0)
        : json['active'];
    _role = json['role'];
    _img = json['img'];
    if (json['addresses'] != null) {
      _addresses = [];
      json['addresses'].forEach((v) {
        _addresses?.add(AddressData.fromJson(v));
      });
    }
    _wallet = json['wallet'] != null ? Wallet.fromJson(json['wallet']) : null;

  }

  int? _id;
  String? _uuid;
  String? _firstname;
  String? _lastname;
  String? _email;
  String? _phone;
  String? _birthday;
  String? _gender;
  bool? _active;
  String? _img;
  String? _role;
  List<AddressData>? _addresses;
  Wallet? _wallet;


  UserData copyWith({
    int? id,
    String? uuid,
    String? firstname,
    String? lastname,
    String? email,
    String? phone,
    String? birthday,
    String? gender,
    bool? active,
    String? img,
    String? role,
    List<AddressData>? addresses,
    Wallet? wallet,

  }) =>
      UserData(
        id: id ?? _id,
        uuid: uuid ?? _uuid,
        firstname: firstname ?? _firstname,
        lastname: lastname ?? _lastname,
        email: email ?? _email,
        phone: phone ?? _phone,
        birthday: birthday ?? _birthday,
        gender: gender ?? _gender,
        active: active ?? _active,
        img: img ?? _img,
        role: role ?? _role,
        addresses: addresses ?? _addresses,
        wallet: wallet ?? _wallet,

      );

  int? get id => _id;
  String? get uuid => _uuid;
  String? get firstname => _firstname;
  String? get lastname => _lastname;
  String? get email => _email;
  String? get phone => _phone;
  String? get birthday => _birthday;
  String? get gender => _gender;
  bool? get active => _active;
  String? get img => _img;
  String? get role => _role;
  List<AddressData>? get addresses => _addresses;
  Wallet? get wallet => _wallet;


  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['uuid'] = _uuid;
    map['firstname'] = _firstname;
    map['lastname'] = _lastname;
    map['email'] = _email;
    map['phone'] = _phone;
    map['birthday'] = _birthday;
    map['gender'] = _gender;
    map['active'] = _active;
    map['img'] = _img;
    map['role'] = _role;
    if (_addresses != null) {
      map['addresses'] = _addresses?.map((v) => v.toJson()).toList();
    }
    if (_wallet != null) {
      map['wallet'] = _wallet?.toJson();
    }

    return map;
  }
}

class Wallet {
  Wallet({
    String? uuid,
    int? userId,
    int? currencyId,
    num? price,
    String? symbol,
    String? createdAt,
    String? updatedAt,
    CurrencyData? currency,
  }) {
    _uuid = uuid;
    _userId = userId;
    _currencyId = currencyId;
    _price = price;
    _symbol = symbol;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _currency = currency;
  }

  Wallet.fromJson(dynamic json) {
    _uuid = json['uuid'];
    _userId = json['user_id'];
    _currencyId = json['currency_id'];
    _price = json['price'];
    _symbol = json['symbol'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    _currency = json['currency'] != null
        ? CurrencyData.fromJson(json['currency'])
        : null;
  }

  String? _uuid;
  int? _userId;
  int? _currencyId;
  num? _price;
  String? _symbol;
  String? _createdAt;
  String? _updatedAt;
  CurrencyData? _currency;

  Wallet copyWith({
    String? uuid,
    int? userId,
    int? currencyId,
    num? price,
    String? symbol,
    String? createdAt,
    String? updatedAt,
    CurrencyData? currency,
  }) =>
      Wallet(
        uuid: uuid ?? _uuid,
        userId: userId ?? _userId,
        currencyId: currencyId ?? _currencyId,
        price: price ?? _price,
        symbol: symbol ?? _symbol,
        createdAt: createdAt ?? _createdAt,
        updatedAt: updatedAt ?? _updatedAt,
        currency: currency ?? _currency,
      );

  String? get uuid => _uuid;
  int? get userId => _userId;
  int? get currencyId => _currencyId;
  num? get price => _price;
  String? get symbol => _symbol;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;
  CurrencyData? get currency => _currency;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['uuid'] = _uuid;
    map['user_id'] = _userId;
    map['currency_id'] = _currencyId;
    map['price'] = _price;
    map['symbol'] = _symbol;
    map['created_at'] = _createdAt;
    map['updated_at'] = _updatedAt;
    if (_currency != null) {
      map['currency'] = _currency?.toJson();
    }
    return map;
  }
}