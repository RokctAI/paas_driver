import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

abstract class ImgService {
  ImgService._();

  static Future getVideoGallery(ValueChanged<String> onChange) async {
    XFile? file;
    try {
      file = await ImagePicker().pickVideo(source: ImageSource.gallery);
    } catch (ex) {
      debugPrint('===> trying to select video $ex');
    }
    if (file != null) {
      onChange.call(file.path);
    }
  }
  static Future getPhotoGallery(ValueChanged<String> onChange) async {
    XFile? file;
    try {
      file = await ImagePicker().pickImage(source: ImageSource.gallery);
    } catch (ex) {
      debugPrint('===> trying to select image $ex');
    }
    if (file != null) {
      onChange.call(file.path);
    }
  }
  static Future getPhotoCamera(ValueChanged<String> onChange) async {
    XFile? file;
    try {
      file = await ImagePicker().pickImage(source: ImageSource.camera);
    } catch (ex) {
      debugPrint('===> trying to select image $ex');
    }
    if (file != null) {
      onChange.call(file.path);
    }
  }

  static Future getGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      return image.path;
    }
    return null;
  }

  static Future getCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      return image.path;
    }
    return null;
  }
}
