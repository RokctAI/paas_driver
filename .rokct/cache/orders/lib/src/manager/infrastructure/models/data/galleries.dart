// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
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

class Galleries {
  Galleries({
    String? id,
    String? title,
    String? type,
    int? loadableId,
    String? path,
    String? preview,
    String? basePath,
  }) {
    _id = id;
    _title = title;
    _type = type;
    _loadableId = loadableId;
    _path = path;
    _preview = preview;
    _basePath = basePath;
  }

  Galleries.fromJson(dynamic json) {
    _id = (json['id'] ?? json['name'])?.toString();
    _title = json['title'];
    _type = json['type'];
    _loadableId = json['loadable_id'];
    _path = json['path'];
    _preview = json['preview'];
    _basePath = json['base_path'];
  }

  String? _id;
  String? _title;
  String? _type;
  int? _loadableId;
  String? _path;
  String? _preview;
  String? _basePath;

  Galleries copyWith({
    String? id,
    String? title,
    String? type,
    int? loadableId,
    String? path,
    String? preview,
    String? basePath,
  }) =>
      Galleries(
        id: id ?? _id,
        title: title ?? _title,
        type: type ?? _type,
        loadableId: loadableId ?? _loadableId,
        path: path ?? _path,
        preview: preview ?? _preview,
        basePath: basePath ?? _basePath,
      );

  String? get id => _id;

  String? get title => _title;

  String? get type => _type;

  int? get loadableId => _loadableId;

  String? get path => _path;

  String? get preview => _preview;

  String? get basePath => _basePath;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['title'] = _title;
    map['type'] = _type;
    map['loadable_id'] = _loadableId;
    map['preview'] = _preview;
    map['base_path'] = _basePath;
    return map;
  }
}
