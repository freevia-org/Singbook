// Standalone native regression check. Build with the Visual Studio x64 tools:
// cl /nologo /std:c++17 /EHsc /W4 /WX /DNOMINMAX windows_clipboard_test.cpp
//   /link user32.lib advapi32.lib ole32.lib
// Default checks are pure conversions. --credentials additionally exercises a
// unique temporary Windows vault entry, and deletes it before returning.
// --clipboard temporarily replaces the current clipboard with test content,
// then restores the previous OLE clipboard object (or its empty state).
#include "../../windows/runner/rich_clipboard.h"
#include "../../windows/runner/secure_credentials.h"
#include "../../windows/runner/window_close_guard.h"

#include <ole2.h>

#include <cstdlib>
#include <iostream>

namespace {
int failures = 0;
void Check(bool condition, const char* description) {
  if (!condition) {
    std::cerr << "FAIL: " << description << '\n';
    failures++;
  }
}

void CheckWindowClose() {
  int requests = 0, closes = 0;
  singbook::WindowCloseGuard::Completion reply;
  auto guard = std::make_unique<singbook::WindowCloseGuard>(
      [&](singbook::WindowCloseGuard::Completion complete) {
        requests++;
        reply = std::move(complete);
      },
      [&]() { closes++; return true; });
  guard->RequestClose();
  guard->RequestClose();
  Check(requests == 1 && closes == 0, "pending close requests are coalesced");
  const auto stale_reply = reply;
  reply(false);
  Check(closes == 0, "cancel keeps the window alive");
  guard->RequestClose();
  Check(requests == 2, "close can be retried after cancellation or channel error");
  stale_reply(true);
  Check(closes == 0, "an earlier response cannot approve a later request");
  reply(true);
  guard->RequestClose();
  reply(true);
  Check(closes == 1 && requests == 2, "approval closes exactly once");

  guard = std::make_unique<singbook::WindowCloseGuard>(
      [&](singbook::WindowCloseGuard::Completion complete) {
        reply = std::move(complete);
      },
      [&]() { closes++; return true; });
  guard->RequestClose();
  guard.reset();
  reply(true);
  Check(closes == 1, "late replies cannot close a destroyed window");

  int posts = 0;
  guard = std::make_unique<singbook::WindowCloseGuard>(
      [](singbook::WindowCloseGuard::Completion complete) { complete(true); },
      [&]() { return ++posts > 1; });
  guard->RequestClose();
  guard->RequestClose();
  guard->RequestClose();
  Check(posts == 2, "failed close dispatch can be retried; success is one-shot");
}

size_t Offset(const std::string& data, const char* field) {
  const size_t position = data.find(field);
  if (position == std::string::npos) return std::string::npos;
  return static_cast<size_t>(
      std::strtoull(data.c_str() + position + std::strlen(field), nullptr, 10));
}

void CheckHtml(const std::string& document, const std::string& fragment) {
  std::string result;
  Check(singbook::BuildClipboardHtml(document, &result), "HTML encoding succeeds");
  const size_t start_html = Offset(result, "StartHTML:");
  const size_t end_html = Offset(result, "EndHTML:");
  const size_t start_fragment = Offset(result, "StartFragment:");
  const size_t end_fragment = Offset(result, "EndFragment:");
  const bool ordered = start_html <= start_fragment &&
                       start_fragment <= end_fragment && end_fragment <= end_html &&
                       end_html == result.size();
  Check(ordered, "CF_HTML byte offsets are ordered and end at payload size");
  if (!ordered) return;
  Check(result.substr(start_fragment, end_fragment - start_fragment) == fragment,
        "CF_HTML offsets select exact original UTF-8 fragment");
  Check(result.substr(start_html).find("<!--StartFragment-->") != std::string::npos,
        "HTML includes fragment marker inside document");
}

class ClipboardRestore {
 public:
  ClipboardRestore() = default;
  ClipboardRestore(const ClipboardRestore&) = delete;
  ClipboardRestore& operator=(const ClipboardRestore&) = delete;

  ~ClipboardRestore() {
    if (restore_needed_) {
      const bool restored = Restore();
      Check(restored, "original clipboard contents are restored");
      if (restored) std::cout << "Original clipboard contents restored.\n";
    }
    if (contents_) contents_->Release();
    if (ole_initialized_) OleUninitialize();
  }

  bool Capture() {
    const HRESULT init_result = OleInitialize(nullptr);
    if (FAILED(init_result)) return false;
    ole_initialized_ = true;

    if (!OpenClipboard(nullptr)) return false;
    was_empty_ = EnumClipboardFormats(0) == 0;
    CloseClipboard();

    if (!was_empty_ && FAILED(OleGetClipboard(&contents_))) return false;
    captured_ = true;
    return true;
  }

  void MarkWillModify() { restore_needed_ = true; }

 private:
  bool Restore() {
    if (!captured_) return false;
    if (was_empty_) {
      if (!OpenClipboard(nullptr)) return false;
      const bool emptied = EmptyClipboard() != FALSE;
      CloseClipboard();
      if (emptied) restore_needed_ = false;
      return emptied;
    }

    const bool restored = SUCCEEDED(OleSetClipboard(contents_)) &&
                          SUCCEEDED(OleFlushClipboard());
    if (restored) restore_needed_ = false;
    return restored;
  }

  IDataObject* contents_ = nullptr;
  bool ole_initialized_ = false;
  bool captured_ = false;
  bool was_empty_ = true;
  bool restore_needed_ = false;
};

class TemporaryCredentialCleanup {
 public:
  TemporaryCredentialCleanup(const std::string& key,
                             std::optional<std::string>* stored)
      : key_(key), stored_(stored) {}
  TemporaryCredentialCleanup(const TemporaryCredentialCleanup&) = delete;
  TemporaryCredentialCleanup& operator=(const TemporaryCredentialCleanup&) =
      delete;

  ~TemporaryCredentialCleanup() {
    const bool deleted = singbook::DeleteSecureCredential(key_) == nullptr;
    Check(deleted, "temporary vault entry is deleted during cleanup");
    if (deleted) {
      std::cout << "Temporary native test credential cleanup confirmed.\n";
    }
    if (stored_ && *stored_ && !(**stored_).empty()) {
      SecureZeroMemory((**stored_).data(), (**stored_).size());
      stored_->reset();
    }
  }

 private:
  std::string key_;
  std::optional<std::string>* stored_;
};

void CheckVault() {
  const std::string key = "native_test_" + std::to_string(GetCurrentProcessId()) +
                          "_" + std::to_string(GetTickCount64());
  const std::string sample = "test-token-\xD0\x91\xF0\x9F\x8E\xB5";
  std::optional<std::string> stored;
  const bool absent = singbook::ReadSecureCredential(key, &stored) == nullptr && !stored;
  Check(absent, "missing vault entry reads null");
  // Never overwrite or delete an entry if this process did not create it.
  if (!absent) return;
  const bool created = singbook::WriteSecureCredential(key, sample) == nullptr;
  Check(created, "vault persists a UTF-8 value");
  if (!created) return;
  [[maybe_unused]] TemporaryCredentialCleanup cleanup(key, &stored);
  Check(singbook::ReadSecureCredential(key, &stored) == nullptr && stored == sample,
        "vault round trip preserves exact bytes");
  Check(singbook::WriteSecureCredential(key, "replacement") == nullptr,
        "vault replaces an existing value");
  Check(singbook::ReadSecureCredential(key, &stored) == nullptr &&
            stored == "replacement",
        "vault reads replacement");
}

void CheckClipboardContents(HWND owner) {
  const std::string text = "Singbook test \xD0\x91\xF0\x9F\x8E\xB5";
  const std::string html = "<p>" + text + "</p>";
  Check(singbook::WriteRichClipboard(owner, text, html) == nullptr,
        "native clipboard publishes both formats");
  const UINT html_format = RegisterClipboardFormatW(L"HTML Format");
  Check(IsClipboardFormatAvailable(CF_UNICODETEXT) != FALSE,
        "Unicode plain text format is available");
  Check(IsClipboardFormatAvailable(html_format) != FALSE,
        "standard Windows HTML Format is available");
  const bool opened = OpenClipboard(owner) != FALSE;
  Check(opened, "native clipboard can be reopened for verification");
  if (opened) {
    const HANDLE plain = GetClipboardData(CF_UNICODETEXT);
    const HANDLE rich = GetClipboardData(html_format);
    const auto* plain_data = plain ? static_cast<const wchar_t*>(GlobalLock(plain)) : nullptr;
    const auto* rich_data = rich ? static_cast<const char*>(GlobalLock(rich)) : nullptr;
    std::wstring expected;
    singbook::ClipboardUtf16(text, &expected);
    Check(plain_data && expected == plain_data,
          "stored clipboard Unicode text matches original");
    std::string expected_html;
    singbook::BuildClipboardHtml(html, &expected_html);
    Check(rich_data && expected_html == rich_data,
          "stored clipboard HTML bytes and offsets match original");
    if (plain_data) GlobalUnlock(plain);
    if (rich_data) GlobalUnlock(rich);
    CloseClipboard();
  }

  // Exercise the receiver side of the Windows paste contract without opening
  // or driving another application window. The hidden standard EDIT control
  // consumes CF_UNICODETEXT through the same WM_PASTE path used by native text
  // fields, which catches data that is advertised but cannot actually paste.
  HWND receiver = CreateWindowExW(0, L"EDIT", L"", WS_POPUP | ES_MULTILINE,
                                  0, 0, 320, 120, nullptr, nullptr,
                                  GetModuleHandleW(nullptr), nullptr);
  Check(receiver != nullptr, "hidden native paste receiver created");
  if (receiver) {
    SendMessageW(receiver, WM_PASTE, 0, 0);
    const int pasted_length = GetWindowTextLengthW(receiver);
    std::wstring pasted(static_cast<size_t>(pasted_length) + 1, L'\0');
    const int copied_length = GetWindowTextW(receiver, pasted.data(),
                                              pasted_length + 1);
    pasted.resize(static_cast<size_t>(copied_length));
    std::wstring expected;
    singbook::ClipboardUtf16(text, &expected);
    Check(pasted == expected,
          "native edit control pastes exact Unicode clipboard text");
    DestroyWindow(receiver);
  }
}

void CheckClipboard() {
  HWND owner = CreateWindowExW(0, L"STATIC", L"Singbook clipboard regression", 0,
                               0, 0, 0, 0, HWND_MESSAGE, nullptr,
                               GetModuleHandleW(nullptr), nullptr);
  Check(owner != nullptr, "clipboard test owner window created");
  if (!owner) return;

  {
    ClipboardRestore clipboard;
    if (!clipboard.Capture()) {
      Check(false, "original clipboard contents can be captured for restoration");
    } else {
      clipboard.MarkWillModify();
      CheckClipboardContents(owner);
    }
  }

  DestroyWindow(owner);
}
}  // namespace

int main(int argc, char** argv) {
  CheckWindowClose();
  const std::string unicode = "\xD0\x91\xD1\x8A\xD0\xBB\xD0\xB3\xD0\xB0\xD1\x80\xD0\xB8\xD1\x8F \xF0\x9F\x8E\xB5";
  CheckHtml("<p>" + unicode + "</p>", "<p>" + unicode + "</p>");
  CheckHtml("<!doctype html><html><head><style>p{color:blue}</style></head>"
            "<body><p>" + unicode + "</p></body></html>", "<p>" + unicode + "</p>");
  CheckHtml("<HTML><BODY class='song'><p>test</p></BODY></HTML>", "<p>test</p>");
  CheckHtml("<html><body><!--StartFragment--><b>test</b><!--EndFragment--></body></html>",
            "<b>test</b>");
  CheckHtml("", "");
  std::wstring wide;
  Check(singbook::ClipboardUtf16(unicode, &wide) && wide.size() == 11,
        "UTF-8 converts Cyrillic and supplementary characters to UTF-16");
  Check(singbook::ClipboardUtf16("", &wide) && wide.empty(), "empty text is valid");
  Check(!singbook::ClipboardUtf16(std::string("\xC3\x28", 2), &wide),
        "invalid UTF-8 is rejected");
  Check(!singbook::ClipboardUtf16(std::string("a\0b", 3), &wide),
        "embedded null cannot silently truncate clipboard text");
  std::string result;
  Check(!singbook::BuildClipboardHtml(std::string("a\0b", 3), &result),
        "embedded null cannot silently truncate clipboard HTML");
  std::wstring target;
  Check(singbook::CredentialTarget("google_drive_AZaz09._-", &target) &&
            target == L"org.freevia.singbook/google_drive_AZaz09._-",
        "vault key is isolated under application namespace");
  Check(!singbook::CredentialTarget("", &target) &&
            !singbook::CredentialTarget("../another/app", &target) &&
            !singbook::CredentialTarget(std::string(181, 'a'), &target),
        "empty, unsafe, and oversized vault keys are rejected");
  Check(singbook::CredentialUtf8Valid(unicode) &&
            !singbook::CredentialUtf8Valid(std::string("\xFF", 1)) &&
            !singbook::CredentialUtf8Valid(std::string(CRED_MAX_CREDENTIAL_BLOB_SIZE + 1, 'x')),
        "vault values enforce UTF-8 and native blob byte limit");
  for (int index = 1; index < argc; index++) {
    if (std::string(argv[index]) == "--credentials") CheckVault();
    else if (std::string(argv[index]) == "--clipboard") CheckClipboard();
    else Check(false, "unknown native test option");
  }
  if (failures == 0) std::cout << "All Windows close, clipboard and credential checks passed.\n";
  return failures == 0 ? 0 : 1;
}
