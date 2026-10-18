import 'dart:math' as math;
import 'dart:ui';

import 'package:crop_your_image/crop_your_image.dart';

/// Map the visible crop window to source pixels, including after reset/re-layout.
/// The editor's cached scale can differ from its displayed image rectangle.
class VisibleImageCropper extends ImageCropper<dynamic> {
  Rect? imageRect;
  Rect? cropRect;

  Rect pixels(dynamic image) {
    final displayed = imageRect;
    final selected = cropRect;
    if (displayed == null || selected == null || displayed.isEmpty) {
      throw StateError('Image geometry is not ready');
    }
    final width = (image.width as int).toDouble();
    final height = (image.height as int).toDouble();
    final x = width / displayed.width, y = height / displayed.height;
    final result = Rect.fromLTRB(
      (selected.left - displayed.left) * x,
      (selected.top - displayed.top) * y,
      (selected.right - displayed.left) * x,
      (selected.bottom - displayed.top) * y,
    ).intersect(Rect.fromLTWH(0, 0, width, height));
    if (result.isEmpty) throw StateError('Empty image selection');
    return result;
  }

  // Validate the displayed geometry instead of the editor's cached pixel rect.
  // The underlying decoder/cropper still receives only clamped source pixels.
  @override
  RectValidator<dynamic> get rectValidator => (image, _, _) {
    try {
      pixels(image);
      return null;
    } on Exception catch (error) {
      return error;
    }
  };

  @override
  RectCropper<dynamic> get rectCropper =>
      (image, {required topLeft, required size, required outputFormat}) {
        final rect = pixels(image);
        return defaultImageCropper.rectCropper(
          image,
          topLeft: rect.topLeft,
          size: rect.size,
          outputFormat: outputFormat,
        );
      };

  @override
  CircleCropper<dynamic> get circleCropper =>
      (image, {required center, required radius, required outputFormat}) {
        final rect = pixels(image);
        return defaultImageCropper.circleCropper(
          image,
          center: rect.center,
          radius: math.min(rect.width, rect.height) / 2,
          outputFormat: outputFormat,
        );
      };
}
