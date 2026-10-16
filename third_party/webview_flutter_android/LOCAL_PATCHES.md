# Local renderer recovery patch

This vendored package is based on `webview_flutter_android` 4.14.1, matching
the app's pinned `webview_flutter` 4.14.1 dependency. The copied upstream
package is distributed under the included BSD 3-Clause `LICENSE`.

The local changes are limited to:

- `WebViewClientProxyApi.java` reports Android renderer loss as handled and
  emits the failed native WebView identifier through an app-specific event.
- `ProxyApiRegistrar.java` and `WebViewFlutterPlugin.java` register and clean
  up that event channel. A separate debug-only method channel can terminate a
  selected WebView renderer for an Android integration test.
- `WebViewProxyApi.java` marks failed platform views and removes and destroys
  them when Flutter detaches the view. Destruction is idempotent because the
  plugin's Pigeon finalizer may also request it.

The event contains only the native WebView identifier. It does not include the
page URL, page contents, or cookies. Android production behavior exposes no
renderer-termination test channel; that channel is registered only when the
app is debuggable.
