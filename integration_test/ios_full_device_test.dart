// One iOS test target avoids rebuilding the native app for every suite.
// Every suite uses temporary databases; run only on a dedicated test simulator.
import 'ios_channel9_provider_device_test.dart' as channel9_providers;
import 'app_device_test.dart' as app;
import 'android_parity_features_device_test.dart' as parity;
import 'ios_platform_device_test.dart' as platform;
import 'ios_provider_parity_device_test.dart' as provider_parity;
import 'player_fullscreen_device_test.dart' as fullscreen;
import 'ios_native_layout_device_test.dart' as layouts;
import 'ios_release23_device_test.dart' as release23;
import 'provider_device_test.dart' as providers;
import 'singbook_journey_device_test.dart' as journey;
import 'source_catalog_device_test.dart' as catalog;
import 'transpose_popup_device_test.dart' as transpose;

void main() {
  app.main();
  journey.main();
  parity.main();
  release23.main();
  transpose.main();
  platform.main();
  provider_parity.main();
  channel9_providers.main();
  fullscreen.main();
  catalog.main();
  providers.main();
  layouts.main();
}
