class Galleries {
  Galleries({
    int? id,
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
    _id = json['id'];
    _title = json['title'];
    _type = json['type'];
    _loadableId = json['loadable_id'];
    _path = json['path'];
    _preview = json['preview'];
    _basePath = json['base_path'];
  }

  int? _id;
  String? _title;
  String? _type;
  int? _loadableId;
  String? _path;
  String? _preview;
  String? _basePath;

  Galleries copyWith({
    int? id,
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

  int? get id => _id;

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
