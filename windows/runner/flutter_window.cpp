#include "flutter_window.h"

#include <optional>
#include <flutter/standard_method_codec.h>
#include <flutter/method_result_functions.h>

#include "flutter/generated_plugin_registrant.h"
#include "rich_clipboard.h"
#include "secure_credentials.h"

namespace {
constexpr UINT kApprovedWindowClose = WM_APP + 1;
}

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  window_close_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "org.freevia.singbook/window_close",
          &flutter::StandardMethodCodec::GetInstance());
  const HWND window = GetHandle();
  fullscreen_ = std::make_unique<singbook::WindowFullscreen>(window);
  fullscreen_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "org.freevia.singbook/fullscreen",
          &flutter::StandardMethodCodec::GetInstance());
  fullscreen_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() != "setEnabled") {
          result->NotImplemented();
          return;
        }
        const auto* enabled = call.arguments()
                                  ? std::get_if<bool>(call.arguments())
                                  : nullptr;
        if (!enabled) {
          result->Error("invalid_arguments", "A fullscreen boolean is required");
          return;
        }
        if (!fullscreen_->SetEnabled(*enabled)) {
          result->Error("fullscreen_failed", "Could not change window fullscreen");
          return;
        }
        result->Success();
      });
  window_close_guard_ = std::make_unique<singbook::WindowCloseGuard>(
      [this](singbook::WindowCloseGuard::Completion complete) {
        window_close_channel_->InvokeMethod(
            "requestClose", nullptr,
            std::make_unique<flutter::MethodResultFunctions<flutter::EncodableValue>>(
                [complete](const flutter::EncodableValue* reply) {
                  const auto* approved = reply ? std::get_if<bool>(reply) : nullptr;
                  complete(approved && *approved);
                },
                [complete](const std::string&, const std::string&,
                           const flutter::EncodableValue*) { complete(false); },
                [complete]() { complete(false); }));
      },
      [window]() { return PostMessage(window, kApprovedWindowClose, 0, 0) != FALSE; });

  rich_clipboard_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "org.freevia.singbook/rich_clipboard",
          &flutter::StandardMethodCodec::GetInstance());
  rich_clipboard_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
#ifdef _DEBUG
        if (call.method_name() == "debugMimeTypes") {
          flutter::EncodableList formats;
          if (IsClipboardFormatAvailable(CF_UNICODETEXT)) {
            formats.emplace_back("text/plain");
          }
          if (IsClipboardFormatAvailable(
                  RegisterClipboardFormatW(L"HTML Format"))) {
            formats.emplace_back("text/html");
          }
          result->Success(flutter::EncodableValue(formats));
          return;
        }
#endif
        if (call.method_name() != "setHtmlText") {
          result->NotImplemented();
          return;
        }
        const auto* arguments =
            std::get_if<flutter::EncodableMap>(call.arguments());
        const std::string* text = nullptr;
        const std::string* html = nullptr;
        if (arguments) {
          const auto text_entry = arguments->find(flutter::EncodableValue("text"));
          const auto html_entry = arguments->find(flutter::EncodableValue("html"));
          if (text_entry != arguments->end()) {
            text = std::get_if<std::string>(&text_entry->second);
          }
          if (html_entry != arguments->end()) {
            html = std::get_if<std::string>(&html_entry->second);
          }
        }
        if (!text || !html) {
          result->Error("invalid_arguments", "Text and HTML are required");
          return;
        }
        const char* error = singbook::WriteRichClipboard(
            flutter_controller_->view()->GetNativeWindow(), *text, *html);
        if (error) {
          result->Error(error, "Could not copy text and HTML to the clipboard");
          return;
        }
        result->Success();
      });

  secure_credentials_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "org.freevia.singbook/secure_credentials",
          &flutter::StandardMethodCodec::GetInstance());
  secure_credentials_channel_->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() != "read" && call.method_name() != "write" &&
            call.method_name() != "delete") {
          result->NotImplemented();
          return;
        }
        const auto* arguments =
            std::get_if<flutter::EncodableMap>(call.arguments());
        const std::string* key = nullptr;
        const std::string* value = nullptr;
        if (arguments) {
          const auto key_entry = arguments->find(flutter::EncodableValue("key"));
          const auto value_entry = arguments->find(flutter::EncodableValue("value"));
          if (key_entry != arguments->end()) {
            key = std::get_if<std::string>(&key_entry->second);
          }
          if (value_entry != arguments->end()) {
            value = std::get_if<std::string>(&value_entry->second);
          }
        }
        if (!key || (call.method_name() == "write" && !value)) {
          result->Error("invalid_arguments", "A key and write value are required");
          return;
        }
        const char* error = nullptr;
        if (call.method_name() == "read") {
          std::optional<std::string> stored;
          error = singbook::ReadSecureCredential(*key, &stored);
          if (!error) {
            if (stored) {
              result->Success(flutter::EncodableValue(*stored));
              if (!stored->empty()) SecureZeroMemory(stored->data(), stored->size());
            } else {
              result->Success();
            }
            return;
          }
        } else if (call.method_name() == "write") {
          error = singbook::WriteSecureCredential(*key, *value);
        } else {
          error = singbook::DeleteSecureCredential(*key);
        }
        if (error) {
          result->Error(error, "Windows credential storage is unavailable");
          return;
        }
        result->Success();
      });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  fullscreen_channel_ = nullptr;
  fullscreen_ = nullptr;
  window_close_guard_ = nullptr;
  window_close_channel_ = nullptr;
  rich_clipboard_channel_ = nullptr;
  secure_credentials_channel_ = nullptr;
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  const bool update_fullscreen_bounds =
      fullscreen_ && fullscreen_->enabled() && !fullscreen_->changing() &&
      (message == WM_DPICHANGED || message == WM_DISPLAYCHANGE);
  // Flutter's default quit guard only asks Dart when this is the final
  // parentless HWND in the process. Other parentless HWNDs can bypass it.
  // Always consult the existing Dart exit observers for our library window.
  if (message == WM_CLOSE && window_close_guard_) {
    window_close_guard_->RequestClose();
    return 0;
  }
  if (message == kApprovedWindowClose) {
    // Approval already passed every Dart exit observer. Do not re-enter the
    // engine's cancel-and-redispatch protocol for the same request.
    return Win32Window::MessageHandler(hwnd, WM_CLOSE, 0, 0);
  }
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      if (update_fullscreen_bounds) fullscreen_->UpdateBounds();
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  const auto result = Win32Window::MessageHandler(hwnd, message, wparam, lparam);
  // Let Flutter/plugins and the normal DPI handler update the child view first,
  // then keep the outer window on monitor bounds rather than a windowed rect.
  if (update_fullscreen_bounds) fullscreen_->UpdateBounds();
  return result;
}
