import 'package:flutter/painting.dart';

/// Minimal color utility used across screens.
class ColorUtils {
  /// Convert a hex color string like '#FF6B6B' or 'FF6B6B' to a [Color].
  static Color fromHex(String hex) {
    final h = hex.replaceAll('#', '').toUpperCase();
    final buffer = StringBuffer();
    if (h.length == 6) buffer.write('FF');
    buffer.write(h);
    final value = int.tryParse(buffer.toString(), radix: 16);
    return Color(value ?? 0xFF6B7280);
  }
}

/// Fallback parse for local use
Color parseHexColor(String hex) => ColorUtils.fromHex(hex);
