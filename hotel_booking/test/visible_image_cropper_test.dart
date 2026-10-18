import 'dart:io';
import 'dart:ui';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking/services/visible_image_cropper.dart';

void main() {
  test('saved pixels match visible window despite stale editor scale after reset', () async {
    final source = defaultImageParser(
      File('test/fixtures/avatar_minh_anh.png').readAsBytesSync(),
    ).image;
    final cropper = VisibleImageCropper()
      ..imageRect = const Rect.fromLTWH(0, 80, 400, 400)
      ..cropRect = const Rect.fromLTWH(44, 124, 312, 312);
    // Cached editor coordinates were producing a smaller, off-centre image.
    final encoded = await cropper(
      original: source,
      topLeft: const Offset(30, 20),
      bottomRight: const Offset(375, 365),
      outputFormat: ImageFormat.png,
    );
    final result = defaultImageParser(encoded).image;
    expect(result.width, 468);
    expect(result.height, 468);
    // Compare real decoded output pixels against the centred source selection.
    for (final point in [
      const Offset(60, 200),
      const Offset(200, 200),
      const Offset(360, 200),
    ]) {
      final actual = result.getPixel(point.dx.toInt(), point.dy.toInt());
      final expected = source.getPixel(
        point.dx.toInt() + 66,
        point.dy.toInt() + 66,
      );
      expect(
        [actual.r, actual.g, actual.b],
        [expected.r, expected.g, expected.b],
      );
    }
    // Drag the image while keeping the crop circle fixed: source selection moves.
    cropper.imageRect = const Rect.fromLTWH(-20, 60, 400, 400);
    expect(cropper.pixels(source).topLeft, const Offset(96, 96));
  });
}
