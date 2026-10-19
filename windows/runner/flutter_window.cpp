#include "flutter_window.h"

#include <optional>
#include <flutter/standard_method_codec.h>

#include "flutter/generated_plugin_registrant.h"
#include "rich_clipboard.h"
#include "secure_credentials.h"

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
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
