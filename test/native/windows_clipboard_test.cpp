// Standalone native regression check. Build with the Visual Studio x64 tools:
// cl /nologo /std:c++17 /EHsc /W4 /WX /DNOMINMAX windows_clipboard_test.cpp
//   /link user32.lib advapi32.lib
// Default checks are pure conversions. --credentials additionally exercises a
// unique temporary Windows vault entry, and deletes it before returning.
// --clipboard additionally replaces the current clipboard with test content.
#include "../../windows/runner/rich_clipboard.h"
#include "../../windows/runner/secure_credentials.h"

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
  Check(singbook::ReadSecureCredential(key, &stored) == nullptr && stored == sample,
        "vault round trip preserves exact bytes");
  Check(singbook::WriteSecureCredential(key, "replacement") == nullptr,
        "vault replaces an existing value");
  Check(singbook::ReadSecureCredential(key, &stored) == nullptr &&
            stored == "replacement",
        "vault reads replacement");
  Check(singbook::DeleteSecureCredential(key) == nullptr,
        "vault deletion succeeds");
  Check(singbook::ReadSecureCredential(key, &stored) == nullptr && !stored,
        "deleted vault value reads null");
  Check(singbook::DeleteSecureCredential(key) == nullptr,
        "vault deletion is idempotent");
  if (!stored) std::cout << "Temporary native test credential cleanup confirmed.\n";
}

void CheckClipboard() {
  HWND owner = CreateWindowExW(0, L"STATIC", L"Singbook clipboard regression", 0,
                               0, 0, 0, 0, HWND_MESSAGE, nullptr,
                               GetModuleHandleW(nullptr), nullptr);
  Check(owner != nullptr, "clipboard test owner window created");
  if (!owner) return;
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
  DestroyWindow(owner);
}
}  // namespace

int main(int argc, char** argv) {
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
  if (failures == 0) std::cout << "All Windows clipboard and credential checks passed.\n";
  return failures == 0 ? 0 : 1;
}
