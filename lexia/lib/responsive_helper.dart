import 'package:flutter/material.dart';

class R {
  R._();

  static late MediaQueryData _mq;
  static late double _sw;
  static late double _sh;

  static void init(BuildContext context) {
    _mq = MediaQuery.of(context);
    _sw = _mq.size.width;
    _sh = _mq.size.height;
  }

  static double get sw => _sw;
  static double get sh => _sh;

  static double get safeTop => _mq.padding.top;
  static double get safeBottom => _mq.padding.bottom;

  /// Main clamped scale so UI does not become huge on large Android phones
  static double s(
    double value, {
    double minFactor = 0.88,
    double maxFactor = 1.00,
  }) {
    final factor = (_sw / 390).clamp(minFactor, maxFactor);
    return value * factor;
  }

  static double text(double value) =>
      s(value, minFactor: 0.90, maxFactor: 0.98);

  static double radius(double value) =>
      s(value, minFactor: 0.92, maxFactor: 1.00);

  static double space(double value) =>
      s(value, minFactor: 0.90, maxFactor: 1.00);

  static double icon(double value) =>
      s(value, minFactor: 0.92, maxFactor: 1.00);

  static double buttonH([double value = 48]) =>
      s(value, minFactor: 0.94, maxFactor: 1.00);

  static double inputH([double value = 50]) =>
      s(value, minFactor: 0.94, maxFactor: 1.00);

  static double get pagePad => _sw * 0.07;

  static double get pagePadWide => _sw * 0.08;

  static double get maxContentWidth => 430;

  static EdgeInsets pageInsets() => EdgeInsets.symmetric(horizontal: pagePad);

  static Widget pageWrap({required Widget child}) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: child,
      ),
    );
  }
}
