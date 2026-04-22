import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences mock helper.
Future<void> setUpMockPrefs({Map<String, Object>? values}) async {
  SharedPreferences.setMockInitialValues(values ?? <String, Object>{});
  // Ensure the binding is initialized for plugins.
  TestWidgetsFlutterBinding.ensureInitialized();
}
