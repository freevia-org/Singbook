// One iOS test target avoids rebuilding the native app for every suite.
// Every suite uses temporary databases; run only on a dedicated test simulator.
import 'app_device_test.dart' as app;
import 'ios_platform_device_test.dart' as platform;
import 'ios_native_layout_device_test.dart' as layouts;
import 'provider_device_test.dart' as providers;
import 'singbook_journey_device_test.dart' as journey;
import 'source_catalog_device_test.dart' as catalog;
import 'transpose_popup_device_test.dart' as transpose;

void main() {
  app.main();
  journey.main();
  transpose.main();
  platform.main();
  catalog.main();
  providers.main();
  layouts.main();
}
