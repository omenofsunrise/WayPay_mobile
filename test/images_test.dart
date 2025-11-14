import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waypay_mobile/assets/resources.dart';

void main() {
  test('images assets test', () {
    expect(File(Images.waypay_mobileLogo).existsSync(), isTrue);
  });
}
