

import '../../services/local_storage.dart';

class CategoryModel {
  final int page;

  CategoryModel({
    required this.page
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map["lang"] = LocalStorage.getLanguage()?.locale ?? "en";
    map["page"] = page;
    map["perPage"] = 10;
    return map;
  }
}
