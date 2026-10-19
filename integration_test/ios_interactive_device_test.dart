// Operator-assisted native checks, grouped to require one build per device.
// Requires SINGBOOK_NATIVE_DIALOG_QA=true and a dedicated disposable library.
import 'ios_app_workflows_device_test.dart' as app;
import 'ios_native_dialog_device_test.dart' as native;

void main() {
  native.main();
  app.main();
}
