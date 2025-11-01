import 'package:flutter/material.dart';

class AppStyle {
  static const TextStyle _baseManrope = TextStyle(fontFamily: 'Manrope');
  static const TextStyle _baseInter = TextStyle(fontFamily: 'Inter');

  static TextStyle manrope({
    required double size,
    required FontWeight weight,
    Color? color,
    double? height,
  }) => _baseManrope.copyWith(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );

  static TextStyle inter({
    required double size,
    required FontWeight weight,
    Color? color,
    double? height,
  }) => _baseInter.copyWith(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );

  static final TextStyle manrope16 = manrope(size: 16, weight: FontWeight.w600);
  static final TextStyle medium20 = inter(size: 20, weight: FontWeight.w500);
  static final TextStyle medium16 = inter(size: 16, weight: FontWeight.w500);
  static final TextStyle regular14 = inter(size: 14, weight: FontWeight.w400);
  static final TextStyle semiBold20 = inter(size: 20, weight: FontWeight.w600);
  static final TextStyle semiBold23 = inter(size: 23, weight: FontWeight.w500);
  static final TextStyle semiBold14 = inter(size: 14, weight: FontWeight.w600);
  static final TextStyle bold12 = inter(size: 12, weight: FontWeight.w700);
}
