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


class Translation {
  Translation({
    int? id,
    String? locale,
    String? title,
    String? description,
    String? shortDesc,
    String? address,
    String? buttonText,
  }) {
    _id = id;
    _locale = locale;
    _title = title;
    _description = description;
    _shortDesc = shortDesc;
    _address = address;
    _buttonText = buttonText;
  }

  Translation.fromJson(dynamic json) {
    _id = json?['id'];
    _locale = json?['locale'];
    _title = json?['title'];
    _description = json?['description'];
    _shortDesc = json?['short_desc'] ?? json?['faq'];
    _address = json?['address'];
    _buttonText = json?['button_text'];

    // Add debug print
    // print("Raw translation JSON: $json");
    // print("Button text extracted in Translation.fromJson: ${json?['button_text']}");
  }

  int? _id;
  String? _locale;
  String? _title;
  String? _description;
  String? _shortDesc;
  String? _address;
  String? _buttonText;

  Translation copyWith({
    int? id,
    String? locale,
    String? title,
    String? description,
    String? shortDesc,
    String? address,
    String? buttonText,
  }) =>
      Translation(
        id: id ?? _id,
        locale: locale ?? _locale,
        title: title ?? _title,
        description: description ?? _description,
        shortDesc: shortDesc ?? _shortDesc,
        address: address ?? _address,
        buttonText: buttonText ?? _buttonText,
      );

  int? get id => _id;
  String? get locale => _locale;
  String? get title => _title;
  String? get description => _description;
  String? get shortDesc => _shortDesc;
  String? get address => _address;
  String? get buttonText {
    // print("Translation.buttonText getter called, returning: $_buttonText");
    return _buttonText;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['locale'] = _locale;
    map['title'] = _title;
    map['description'] = _description;
    map['short_desc'] = _shortDesc;
    map['address'] = _address;
    map['button_text'] = _buttonText;
    return map;
  }
}
