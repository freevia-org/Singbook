#ifndef RUNNER_SECURE_CREDENTIALS_H_
#define RUNNER_SECURE_CREDENTIALS_H_

#include <windows.h>
#include <wincred.h>

#include <algorithm>
#include <optional>
#include <string>
#include <vector>

namespace singbook {

inline bool CredentialTarget(const std::string& key, std::wstring* target) {
  if (key.empty() || key.size() > 180) return false;
  for (unsigned char character : key) {
    if (!((character >= 'a' && character <= 'z') ||
          (character >= 'A' && character <= 'Z') ||
          (character >= '0' && character <= '9') || character == '.' ||
          character == '_' || character == '-')) {
      return false;
    }
  }
  *target = L"org.freevia.singbook/";
  target->append(key.begin(), key.end());
  return true;
}

inline bool CredentialUtf8Valid(const std::string& value) {
  return value.empty() ||
         (value.size() <= CRED_MAX_CREDENTIAL_BLOB_SIZE &&
          MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, value.data(),
                              static_cast<int>(value.size()), nullptr, 0) > 0);
}

inline const char* ReadSecureCredential(const std::string& key,
                                       std::optional<std::string>* value) {
  value->reset();
  std::wstring target;
  if (!CredentialTarget(key, &target)) return "invalid_arguments";
  PCREDENTIALW credential = nullptr;
  if (!CredReadW(target.c_str(), CRED_TYPE_GENERIC, 0, &credential)) {
    return GetLastError() == ERROR_NOT_FOUND ? nullptr : "credential_read_failed";
  }
  const bool valid_size =
      credential->CredentialBlobSize <= CRED_MAX_CREDENTIAL_BLOB_SIZE &&
      (credential->CredentialBlobSize == 0 || credential->CredentialBlob);
  std::string stored;
  if (valid_size && credential->CredentialBlobSize > 0) {
    stored.assign(reinterpret_cast<const char*>(credential->CredentialBlob),
                  credential->CredentialBlobSize);
  }
  if (credential->CredentialBlob && credential->CredentialBlobSize > 0) {
    SecureZeroMemory(credential->CredentialBlob, credential->CredentialBlobSize);
  }
  CredFree(credential);
  if (!valid_size || !CredentialUtf8Valid(stored)) {
    if (!stored.empty()) SecureZeroMemory(stored.data(), stored.size());
    return "credential_read_failed";
  }
  *value = std::move(stored);
  return nullptr;
}

inline const char* WriteSecureCredential(const std::string& key,
                                        const std::string& value) {
  std::wstring target;
  if (!CredentialTarget(key, &target) ||
      value.size() > CRED_MAX_CREDENTIAL_BLOB_SIZE ||
      !CredentialUtf8Valid(value)) {
    return "invalid_arguments";
  }
  std::vector<BYTE> bytes(value.begin(), value.end());
  CREDENTIALW credential{};
  credential.Type = CRED_TYPE_GENERIC;
  credential.TargetName = target.data();
  credential.CredentialBlobSize = static_cast<DWORD>(bytes.size());
  credential.CredentialBlob = bytes.empty() ? nullptr : bytes.data();
  // Generic credentials remain scoped to the current Windows user's vault;
  // LOCAL_MACHINE persists them across this user's subsequent login sessions.
  credential.Persist = CRED_PERSIST_LOCAL_MACHINE;
  const bool success = CredWriteW(&credential, 0) != FALSE;
  if (!bytes.empty()) SecureZeroMemory(bytes.data(), bytes.size());
  return success ? nullptr : "credential_write_failed";
}

inline const char* DeleteSecureCredential(const std::string& key) {
  std::wstring target;
  if (!CredentialTarget(key, &target)) return "invalid_arguments";
  if (CredDeleteW(target.c_str(), CRED_TYPE_GENERIC, 0)) return nullptr;
  return GetLastError() == ERROR_NOT_FOUND ? nullptr : "credential_delete_failed";
}

}  // namespace singbook

#endif  // RUNNER_SECURE_CREDENTIALS_H_
