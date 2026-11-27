import 'package:flutter/painting.dart';

abstract class AppSpacing {
  static const double bubbleMarginH = 12;
  static const double bubbleMarginV = 4;
  static const double bubblePaddingH = 14;
  static const double bubblePaddingV = 10;
  static const double bubbleRadius = 12;
  static const double cardRadius = 14;
  static const double codeRadius = 10;
  static const double maxBubbleWidthFraction = 0.80;

  static const BorderRadius userBubbleBorderRadius = BorderRadius.only(
    topLeft: Radius.circular(bubbleRadius),
    topRight: Radius.circular(bubbleRadius),
    bottomLeft: Radius.circular(bubbleRadius),
    bottomRight: Radius.circular(4),
  );
  static const BorderRadius assistantBubbleBorderRadius = BorderRadius.only(
    topLeft: Radius.circular(4),
    topRight: Radius.circular(bubbleRadius),
    bottomLeft: Radius.circular(bubbleRadius),
    bottomRight: Radius.circular(bubbleRadius),
  );
}
