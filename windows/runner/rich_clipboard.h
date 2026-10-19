#ifndef RUNNER_RICH_CLIPBOARD_H_
#define RUNNER_RICH_CLIPBOARD_H_

#include <windows.h>

#include <algorithm>
#include <cctype>
#include <cstring>
#include <limits>
#include <string>

namespace singbook {

// Offsets in the registered Windows HTML Format are UTF-8 byte offsets, not
// UTF-16 character offsets. Keep the original document (including its styles)
// and mark just the body as the fragment to paste into another document.
inline bool BuildClipboardHtml(const std::string& html, std::string* output) {
  if (html.find('\0') != std::string::npos) return false;
  constexpr char kStart[] = "<!--StartFragment-->";
  constexpr char kEnd[] = "<!--EndFragment-->";
  std::string document = html;
  size_t start = document.find(kStart);
  size_t end = document.find(kEnd);
  if (start == std::string::npos || end == std::string::npos ||
      end < start + sizeof(kStart) - 1) {
    std::string lower = document;
    std::transform(lower.begin(), lower.end(), lower.begin(),
                   [](unsigned char value) {
                     return static_cast<char>(std::tolower(value));
                   });
    const size_t body = lower.find("<body");
    const size_t body_open = body == std::string::npos
                                 ? std::string::npos
                                 : lower.find('>', body);
    const size_t body_end = lower.rfind("</body>");
    if (body_open != std::string::npos && body_end != std::string::npos &&
        body_end > body_open) {
      document.insert(body_end, kEnd);
      document.insert(body_open + 1, kStart);
    } else {
      document = std::string("<html><body>") + kStart + html + kEnd +
                 "</body></html>";
    }
    start = document.find(kStart);
    end = document.rfind(kEnd);
  }
  std::string header = "Version:1.0\r\nStartHTML:0000000000\r\n"
                       "EndHTML:0000000000\r\nStartFragment:0000000000\r\n"
                       "EndFragment:0000000000\r\n";
  constexpr size_t kLargestOffset = 9999999999ULL;
  if (document.size() > kLargestOffset - header.size()) return false;
  const size_t start_html = header.size();
  const auto set_offset = [&header](const char* name, size_t value) {
    const std::string decimal = std::to_string(value);
    header.replace(header.find(name) + std::strlen(name), 10,
                   std::string(10 - decimal.size(), '0') + decimal);
  };
  set_offset("StartHTML:", start_html);
  set_offset("EndHTML:", start_html + document.size());
  set_offset("StartFragment:", start_html + start + sizeof(kStart) - 1);
  set_offset("EndFragment:", start_html + end);
  *output = header + document;
  return true;
}

inline bool ClipboardUtf16(const std::string& text, std::wstring* output) {
  if (text.find('\0') != std::string::npos ||
      text.size() > static_cast<size_t>((std::numeric_limits<int>::max)())) {
    return false;
  }
  if (text.empty()) {
    output->clear();
    return true;
  }
  const int length = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
                                        text.data(), static_cast<int>(text.size()),
                                        nullptr, 0);
  if (length == 0) return false;
  output->resize(length);
  return MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, text.data(),
                             static_cast<int>(text.size()), output->data(),
                             length) == length;
}

class ClipboardMemory {
 public:
  ClipboardMemory(const void* bytes, size_t size)
      : handle_(GlobalAlloc(GMEM_MOVEABLE, size)) {
    if (!handle_) return;
    void* destination = GlobalLock(handle_);
    if (!destination) {
      GlobalFree(handle_);
      handle_ = nullptr;
      return;
    }
    std::memcpy(destination, bytes, size);
    GlobalUnlock(handle_);
  }
  ~ClipboardMemory() {
    if (handle_) GlobalFree(handle_);
  }
  ClipboardMemory(const ClipboardMemory&) = delete;
  ClipboardMemory& operator=(const ClipboardMemory&) = delete;
  bool valid() const { return handle_ != nullptr; }
  bool Publish(UINT format) {
    if (!SetClipboardData(format, handle_)) return false;
    // Windows owns this memory only after SetClipboardData succeeds.
    handle_ = nullptr;
    return true;
  }

 private:
  HGLOBAL handle_;
};

// Prepare both formats before emptying the existing clipboard. Return a stable
// channel error code; never include song text in diagnostics.
inline const char* WriteRichClipboard(HWND owner, const std::string& text,
                                     const std::string& html) {
  std::wstring unicode;
  std::wstring validated_html;
  std::string clipboard_html;
  if (!ClipboardUtf16(text, &unicode) ||
      !ClipboardUtf16(html, &validated_html) ||
      !BuildClipboardHtml(html, &clipboard_html)) {
    return "invalid_arguments";
  }
  const UINT html_format = RegisterClipboardFormatW(L"HTML Format");
  if (!html_format) return "clipboard_format_failed";
  ClipboardMemory plain(unicode.c_str(), (unicode.size() + 1) * sizeof(wchar_t));
  ClipboardMemory rich(clipboard_html.c_str(), clipboard_html.size() + 1);
  if (!plain.valid() || !rich.valid()) return "clipboard_allocation_failed";
  if (!OpenClipboard(owner)) return "clipboard_busy";
  const char* error = nullptr;
  if (!EmptyClipboard()) {
    error = "clipboard_write_failed";
  } else if (!plain.Publish(CF_UNICODETEXT) || !rich.Publish(html_format)) {
    error = "clipboard_write_failed";
  }
  CloseClipboard();
  return error;
}

}  // namespace singbook

#endif  // RUNNER_RICH_CLIPBOARD_H_
