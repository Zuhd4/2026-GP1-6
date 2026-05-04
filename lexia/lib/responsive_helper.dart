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

  /// 🔹 ORIGINAL SCALE (لا نغيره عشان باقي الصفحات)
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

  // =========================================================
  // GAME MAP RESPONSIVE
  // كل ما الشاشة تكبر، عناصر خريطة الألعاب تصغر شوي
  // =========================================================

  static double gameScale({double minFactor = 0.72, double maxFactor = 1.00}) {
    final factor = (390 / _sw).clamp(minFactor, maxFactor);
    return factor;
  }

  static double gameSpace(double value) => value * gameScale();

  static double gameText(double value) =>
      value * gameScale(minFactor: 0.76, maxFactor: 1.00);

  static double gameIcon(double value) =>
      value * gameScale(minFactor: 0.74, maxFactor: 1.00);

  static double gameRadius(double value) =>
      value * gameScale(minFactor: 0.78, maxFactor: 1.00);

  // =========================================================
  // 🔥 DASHBOARD RESPONSIVE (جديد - خاص بالداشبورد فقط)
  // =========================================================

  static double dash(
    double value, {
    double minFactor = 0.72,
    double maxFactor = 0.88,
  }) {
    final base = _sw < _sh ? _sw : _sh;
    final factor = (base / 390).clamp(minFactor, maxFactor);
    return value * factor;
  }

  static double dashText(double value) =>
      dash(value, minFactor: 0.74, maxFactor: 0.86);

  static double dashRadius(double value) =>
      dash(value, minFactor: 0.78, maxFactor: 0.90);

  static double dashSpace(double value) =>
      dash(value, minFactor: 0.74, maxFactor: 0.88);

  static double dashIcon(double value) =>
      dash(value, minFactor: 0.74, maxFactor: 0.88);

  static double dashButtonH([double value = 48]) =>
      dash(value, minFactor: 0.78, maxFactor: 0.90);

  static double get dashPagePad => (_sw * 0.06).clamp(18.0, 24.0);

  static double get dashMaxContentWidth => 370;

  static EdgeInsets dashPageInsets() =>
      EdgeInsets.symmetric(horizontal: dashPagePad);

  static Widget dashPageWrap({required Widget child}) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dashMaxContentWidth),
        child: child,
      ),
    );
  }
}
