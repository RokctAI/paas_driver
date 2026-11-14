import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:base_sdk/src/presentation/pages/initial/splash/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 40x80 PNG painted [top] above and [bottom] across its lowest eighth.
Future<ByteData> _png(Color top, Color bottom) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 40, 70), Paint()..color = top);
  canvas.drawRect(const Rect.fromLTWH(0, 70, 40, 10), Paint()..color = bottom);
  final image = await recorder.endRecording().toImage(40, 80);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!;
}

void main() {
  test('a light bottom strip reads as light artwork', () async {
    final data = await _png(Colors.black, Colors.white);
    expect(await splashArtworkBrightness(data), Brightness.light);
  });

  test('a dark bottom strip reads as dark artwork', () async {
    final data = await _png(Colors.white, const Color(0xFF101010));
    expect(await splashArtworkBrightness(data), Brightness.dark);
  });
}
