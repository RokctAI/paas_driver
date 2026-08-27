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


import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

abstract class ImgService {
  ImgService._();

  static Future getGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      return image.path;
    }
    return null;
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

  static Future getVideoGallery(ValueChanged<String> onChange) async {
    XFile? file;
    try {
      file = await ImagePicker().pickVideo(source: ImageSource.gallery);
    } catch (ex) {
      debugPrint('===> trying to select image $ex');
    }
    if (file != null) {
      onChange.call(file.path);
    }
  }

  static Future getCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      return image.path;
    }
    return null;
  }

  static Future getFilePdf(ValueChanged<String> onChange) async {
    FilePickerResult? file;
    try {
      file = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
    } catch (ex) {
      debugPrint('===> trying to select file $ex');
    }
    if (file?.paths.isNotEmpty ?? false) {
      onChange.call(file?.paths.first ?? '');
    }
  }
}
