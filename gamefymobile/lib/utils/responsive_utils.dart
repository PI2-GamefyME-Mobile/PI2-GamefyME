import 'package:flutter/material.dart';

class ResponsiveUtils {
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 360 && width < 600;
  }

  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static EdgeInsets adaptivePadding(BuildContext context, {
    double small = 8.0,
    double medium = 12.0,
    double large = 16.0,
  }) {
    if (isSmallScreen(context)) {
      return EdgeInsets.all(small);
    } else if (isMediumScreen(context)) {
      return EdgeInsets.all(medium);
    }
    return EdgeInsets.all(large);
  }

  static EdgeInsets adaptiveHorizontalPadding(BuildContext context, {
    double small = 8.0,
    double medium = 12.0,
    double large = 16.0,
  }) {
    if (isSmallScreen(context)) {
      return EdgeInsets.symmetric(horizontal: small);
    } else if (isMediumScreen(context)) {
      return EdgeInsets.symmetric(horizontal: medium);
    }
    return EdgeInsets.symmetric(horizontal: large);
  }

  static double adaptiveFontSize(BuildContext context, {
    double small = 12.0,
    double medium = 14.0,
    double large = 16.0,
  }) {
    if (isSmallScreen(context)) {
      return small;
    } else if (isMediumScreen(context)) {
      return medium;
    }
    return large;
  }

  static SizedBox adaptiveVerticalSpace(BuildContext context, {
    double small = 8.0,
    double medium = 12.0,
    double large = 16.0,
  }) {
    if (isSmallScreen(context)) {
      return SizedBox(height: small);
    } else if (isMediumScreen(context)) {
      return SizedBox(height: medium);
    }
    return SizedBox(height: large);
  }

  static SizedBox adaptiveHorizontalSpace(BuildContext context, {
    double small = 8.0,
    double medium = 12.0,
    double large = 16.0,
  }) {
    if (isSmallScreen(context)) {
      return SizedBox(width: small);
    } else if (isMediumScreen(context)) {
      return SizedBox(width: medium);
    }
    return SizedBox(width: large);
  }

  static double adaptiveIconSize(BuildContext context, {
    double small = 20.0,
    double medium = 24.0,
    double large = 28.0,
  }) {
    if (isSmallScreen(context)) {
      return small;
    } else if (isMediumScreen(context)) {
      return medium;
    }
    return large;
  }

  static double widthPercentage(BuildContext context, double percentage) {
    return screenWidth(context) * (percentage / 100);
  }

  static double heightPercentage(BuildContext context, double percentage) {
    return screenHeight(context) * (percentage / 100);
  }

  static BorderRadius adaptiveBorderRadius(BuildContext context, {
    double small = 8.0,
    double medium = 10.0,
    double large = 12.0,
  }) {
    if (isSmallScreen(context)) {
      return BorderRadius.circular(small);
    } else if (isMediumScreen(context)) {
      return BorderRadius.circular(medium);
    }
    return BorderRadius.circular(large);
  }

  static double adaptiveButtonHeight(BuildContext context, {
    double small = 40.0,
    double medium = 45.0,
    double large = 50.0,
  }) {
    if (isSmallScreen(context)) {
      return small;
    } else if (isMediumScreen(context)) {
      return medium;
    }
    return large;
  }

  static double adaptiveAvatarSize(BuildContext context, {
    double small = 36.0,
    double medium = 42.0,
    double large = 46.0,
  }) {
    if (isSmallScreen(context)) {
      return small;
    } else if (isMediumScreen(context)) {
      return medium;
    }
    return large;
  }
}
