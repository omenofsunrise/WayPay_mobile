import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waypay_mobile/assets/resources.dart';

void main() {
  test('images assets test', () {
    expect(File(Images.appIcon).existsSync(), isTrue);
    expect(File(Images.backgroundLogo).existsSync(), isTrue);
    expect(File(Images.error).existsSync(), isTrue);
    expect(File(Images.waypayLogo).existsSync(), isTrue);
    expect(File(Images.whatsappLogo).existsSync(), isTrue);
  });
}
