// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.content.pm.ApplicationInfo;
import android.os.Build;
import android.webkit.WebView;
import android.webkit.WebViewRenderProcess;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;
import java.util.Map;

/**
 * Java platform implementation of the webview_flutter plugin.
 *
 * <p>Register this in an add to app scenario to gracefully handle activity and context changes.
 */
public class WebViewFlutterPlugin implements FlutterPlugin, ActivityAware {
  private FlutterPluginBinding pluginBinding;
  private ProxyApiRegistrar proxyApiRegistrar;
  private EventChannel rendererGoneChannel;
  private MethodChannel rendererTestChannel;

  /**
   * Add an instance of this to {@link io.flutter.embedding.engine.plugins.PluginRegistry} to
   * register it.
   *
   * <p>Registration should eventually be handled automatically by v2 of the
   * GeneratedPluginRegistrant. https://github.com/flutter/flutter/issues/42694
   */
  public WebViewFlutterPlugin() {}

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    pluginBinding = binding;

    proxyApiRegistrar =
        new ProxyApiRegistrar(
            binding.getBinaryMessenger(),
            binding.getApplicationContext(),
            new FlutterAssetManager.PluginBindingFlutterAssetManager(
                binding.getApplicationContext().getAssets(), binding.getFlutterAssets()));

    rendererGoneChannel =
        new EventChannel(
            binding.getBinaryMessenger(), "org.freevia.singbook/webview_renderer_events");
    rendererGoneChannel.setStreamHandler(
        new EventChannel.StreamHandler() {
          @Override
          public void onListen(Object arguments, EventChannel.EventSink events) {
            if (proxyApiRegistrar != null) {
              proxyApiRegistrar.setRendererGoneEvents(events);
            }
          }

          @Override
          public void onCancel(Object arguments) {
            if (proxyApiRegistrar != null) {
              proxyApiRegistrar.setRendererGoneEvents(null);
            }
          }
        });

    final boolean isDebuggable =
        (binding.getApplicationContext().getApplicationInfo().flags
                & ApplicationInfo.FLAG_DEBUGGABLE)
            != 0;
    if (isDebuggable) {
      rendererTestChannel =
          new MethodChannel(
              binding.getBinaryMessenger(), "org.freevia.singbook/webview_renderer_test");
      rendererTestChannel.setMethodCallHandler(
          (call, result) -> {
            if (!"terminateRenderer".equals(call.method)) {
              result.notImplemented();
              return;
            }
            if (!(call.arguments instanceof Map)) {
              result.error("invalid_arguments", "A WebView identifier is required.", null);
              return;
            }
            final Object rawIdentifier = ((Map<?, ?>) call.arguments).get("webViewIdentifier");
            if (!(rawIdentifier instanceof Number)) {
              result.error("invalid_arguments", "A WebView identifier is required.", null);
              return;
            }
            final long identifier = ((Number) rawIdentifier).longValue();
            final WebView webView =
                proxyApiRegistrar.getInstanceManager().getInstance(identifier);
            if (webView == null) {
              result.error("webview_unavailable", "The test WebView is no longer active.", null);
              return;
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
              final WebViewRenderProcess renderer = webView.getWebViewRenderProcess();
              if (renderer != null && renderer.terminate()) {
                result.success(true);
                return;
              }
              // The controller can be created before Chromium starts its
              // renderer. Let the integration test retry after the first page
              // navigation instead of reporting a false successful crash.
              result.success(false);
              return;
            }
            // WebViewRenderProcess.terminate is API 29+. This fallback is used
            // only by the debug test hook on older devices.
            webView.loadUrl("chrome://crash");
            result.success(true);
          });
    }

    binding
        .getPlatformViewRegistry()
        .registerViewFactory(
            "plugins.flutter.io/webview",
            new FlutterViewFactory(proxyApiRegistrar.getInstanceManager()));

    proxyApiRegistrar.setUp();
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    if (rendererGoneChannel != null) {
      rendererGoneChannel.setStreamHandler(null);
      rendererGoneChannel = null;
    }
    if (rendererTestChannel != null) {
      rendererTestChannel.setMethodCallHandler(null);
      rendererTestChannel = null;
    }
    if (proxyApiRegistrar != null) {
      proxyApiRegistrar.setRendererGoneEvents(null);
      proxyApiRegistrar.tearDown();
      proxyApiRegistrar.getInstanceManager().stopFinalizationListener();
      proxyApiRegistrar = null;
    }
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding activityPluginBinding) {
    if (proxyApiRegistrar != null) {
      proxyApiRegistrar.setContext(activityPluginBinding.getActivity());
    }
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    proxyApiRegistrar.setContext(pluginBinding.getApplicationContext());
  }

  @Override
  public void onReattachedToActivityForConfigChanges(
      @NonNull ActivityPluginBinding activityPluginBinding) {
    proxyApiRegistrar.setContext(activityPluginBinding.getActivity());
  }

  @Override
  public void onDetachedFromActivity() {
    proxyApiRegistrar.setContext(pluginBinding.getApplicationContext());
  }

  /** Maintains instances used to communicate with the corresponding objects in Dart. */
  @Nullable
  public AndroidWebkitLibraryPigeonInstanceManager getInstanceManager() {
    return proxyApiRegistrar.getInstanceManager();
  }
}
