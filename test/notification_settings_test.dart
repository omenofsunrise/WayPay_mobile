import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waypay_mobile/core/storage/user_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('notification type filters match website settings', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = UserStorage();
    await storage.saveNotificationSettings(
      enabled: true,
      showCreditCreation: false,
      showWhatsApp: false,
    );

    expect(storage.shouldShowNotificationType('credit'), isFalse);
    expect(storage.shouldShowNotificationType('whats_app'), isFalse);
    expect(storage.shouldShowNotificationType('admin_whats_app'), isTrue);
    expect(storage.shouldShowNotificationType('notification'), isTrue);

    await storage.saveNotificationSettings(enabled: false);
    expect(storage.shouldShowNotificationType('notification'), isFalse);
  });
}
