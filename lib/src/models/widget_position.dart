enum WidgetPosition {
  bottomRight,
  bottomLeft,
}

extension WidgetPositionExtension on WidgetPosition {
  String get name {
    switch (this) {
      case WidgetPosition.bottomRight:
        return 'bottom-right';
      case WidgetPosition.bottomLeft:
        return 'bottom-left';
    }
  }

  static WidgetPosition fromString(String value) {
    switch (value.toLowerCase()) {
      case 'bottom-left':
        return WidgetPosition.bottomLeft;
      case 'bottom-right':
      default:
        return WidgetPosition.bottomRight;
    }
  }
}