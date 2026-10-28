// Deterministic iPhone/iPad parity journey; no live providers or cloud accounts.
import 'ios_channel9_provider_device_test.dart' as channel9_providers;
import 'android_parity_features_device_test.dart' as features;
import 'ios_native_layout_device_test.dart' as layouts;
import 'ios_platform_parity_device_test.dart' as native;
import 'player_fullscreen_device_test.dart' as fullscreen;
import 'singbook_journey_device_test.dart' as journey;

void main() {
  native.main();
  channel9_providers.main();
  journey.main();
  features.main();
  fullscreen.main();
  layouts.main();
}
