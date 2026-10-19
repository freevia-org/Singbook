// Serial native checks for the Android/iOS parity update, using only temporary
// fixture libraries. Run on dedicated Singbook iPhone and iPad simulators.
import 'ios_native_layout_device_test.dart' as layouts;
import 'ios_platform_device_test.dart' as platform;
import 'ios_store_screenshots_device_test.dart' as store;

void main() {
  platform.main();
  store.main();
  layouts.main();
}
