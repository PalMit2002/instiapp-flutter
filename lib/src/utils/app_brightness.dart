import 'package:flutter/material.dart';

/// Describes the contrast needs of a color.
class AppBrightness {
  final int index;
  const AppBrightness._internal(this.index);
  @override
  String toString() => 'AppBrightness.$index';

  /// The color is dark and will require a light text color to achieve readable
  /// contrast.
  ///
  /// For example, the color might be dark grey, requiring white text.

  static const AppBrightness dark = AppBrightness._internal(0);

  /// The color is light and will require a dark text color to achieve readable
  /// contrast.
  ///
  /// For example, the color might be bright white, requiring black text.

  static const AppBrightness light = AppBrightness._internal(1);

  /// The color is black and will require a light text color to achieve readable
  /// contrast.
  ///
  /// For example, the color might be black, requiring white text.
  static const AppBrightness black = AppBrightness._internal(2);

  static const Map<AppBrightness, Color> brightnessToCanvasColor = {
    light: Colors.white,
    dark: Color(0xff202020),
    black: Colors.black,
  };

  static const List<AppBrightness> values = [dark, light, black];

  Brightness toBrightness() {
    return index == 2 ? Brightness.dark : Brightness.values[index];
  }

  Color toColor() {
    return brightnessToCanvasColor[this]!;
  }
}
