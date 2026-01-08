import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat_widget_config.dart';

class TextStyleHelper {
  static TextStyle getChatTextStyle(
    ChatWidgetConfig config, {
    double size = 14,
    FontWeight? weight,
    Color? color,
  }) {
    final raw = config.fontFamily.trim();
    final fallbacks = config.fontFamilyFallbacks;

    final primary = raw
        .split(',')
        .map((s) => s.trim().replaceAll('"', '').replaceAll("'", ''))
        .where((s) => s.isNotEmpty)
        .map((s) => s.toLowerCase())
        .toList();
    
    final p = primary.isNotEmpty ? primary.first : '';

    final mapping = <String, String>{
      'system-ui': 'inter',
      '-apple-system': 'inter',
      'system-ui, -apple-system': 'inter',
      'segoe ui': 'inter',
      'arial': 'roboto',
      'helvetica': 'roboto',
      'georgia': 'merriweather',
      'times new roman': 'tinos',
      'times': 'tinos',
      'verdana': 'open sans',
      'trebuchet ms': 'rubik',
      'trebuchet': 'rubik',
      'courier new': 'roboto mono',
      'courier': 'roboto mono',
    };

    final String? mapped = mapping[p];

    if (mapped != null && mapped.isNotEmpty) {
      return _getGoogleFontByName(
        mapped,
        size: size,
        weight: weight,
        color: color,
        fallbacks: fallbacks,
      );
    }

    if (p.isNotEmpty) {
      try {
        return GoogleFonts.getFont(
          p,
          fontSize: size,
          fontWeight: weight,
          textStyle: TextStyle(
            color: color,
            fontFamilyFallback: fallbacks,
          ),
        );
      } catch (_) {
        // Fall through to default
      }
    }

    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      fontFamilyFallback: fallbacks,
    );
  }

  static TextStyle _getGoogleFontByName(
    String name, {
    required double size,
    FontWeight? weight,
    Color? color,
    required List<String> fallbacks,
  }) {
    switch (name) {
      case 'inter':
        return GoogleFonts.inter(
          fontSize: size,
          fontWeight: weight,
          textStyle: TextStyle(
            color: color,
            fontFamilyFallback: fallbacks,
          ),
        );
      case 'roboto':
        return GoogleFonts.roboto(
          fontSize: size,
          fontWeight: weight,
          textStyle: TextStyle(
            color: color,
            fontFamilyFallback: fallbacks,
          ),
        );
      case 'merriweather':
        return GoogleFonts.merriweather(
          fontSize: size,
          fontWeight: weight,
          textStyle: TextStyle(
            color: color,
            fontFamilyFallback: fallbacks,
          ),
        );
      case 'tinos':
        return GoogleFonts.tinos(
          fontSize: size,
          fontWeight: weight,
          textStyle: TextStyle(
            color: color,
            fontFamilyFallback: fallbacks,
          ),
        );
      case 'open sans':
      case 'opensans':
      case 'open-sans':
        return GoogleFonts.openSans(
          fontSize: size,
          fontWeight: weight,
          textStyle: TextStyle(
            color: color,
            fontFamilyFallback: fallbacks,
          ),
        );
      case 'rubik':
        return GoogleFonts.rubik(
          fontSize: size,
          fontWeight: weight,
          textStyle: TextStyle(
            color: color,
            fontFamilyFallback: fallbacks,
          ),
        );
      case 'roboto mono':
      case 'robotomono':
      case 'roboto-mono':
        return GoogleFonts.robotoMono(
          fontSize: size,
          fontWeight: weight,
          textStyle: TextStyle(
            color: color,
            fontFamilyFallback: fallbacks,
          ),
        );
      default:
        try {
          return GoogleFonts.getFont(
            name,
            fontSize: size,
            fontWeight: weight,
            textStyle: TextStyle(
              color: color,
              fontFamilyFallback: fallbacks,
            ),
          );
        } catch (_) {
          return TextStyle(
            fontSize: size,
            fontWeight: weight,
            color: color,
            fontFamilyFallback: fallbacks,
          );
        }
    }
  }
}