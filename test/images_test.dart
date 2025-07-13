import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waypay/assets/resources.dart';

void main() {
  test('images assets test', () {
    expect(File(Images.waypayLogo).existsSync(), isTrue);
  });
}
