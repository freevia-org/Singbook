import Foundation
import CloudKit
import FlutterMacOS

/// Install from AppDelegate using its engine's binary messenger.
final class ICloudSyncChannel {
  private enum PayloadError: Error { case missing, tooLarge, invalid }
  private struct RequestContext {
    let accountID: String
    let epoch: UInt64
  }
  private lazy var container = CKContainer(identifier: "iCloud.org.freevia.singbook")
  private let type = "SingbookSyncItem"
  private lazy var db = container.privateCloudDatabase
  private let channel: FlutterMethodChannel
  private var accountObserver: NSObjectProtocol?
  private let epochLock = NSLock()
  private var accountEpoch: UInt64 = 0
  private let maxBytes = 16 * 1024 * 1024
  private let maxRecords = 40000
  private let tombstoneKey = "deleted"
  private let sizeKey = "contentSize"

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "org.freevia.singbook/icloud_sync", binaryMessenger: messenger)
    accountObserver = NotificationCenter.default.addObserver(forName: .CKAccountChanged, object: nil, queue: nil) { [weak self] _ in
      guard let self else { return }
      self.epochLock.lock()
      self.accountEpoch += 1
      self.epochLock.unlock()
    }
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        DispatchQueue.main.async { result(FlutterError(code: "icloud_unavailable", message: nil, details: nil)) }
        return
      }
      self.handle(call, result: result)
    }
  }

  deinit {
    if let accountObserver { NotificationCenter.default.removeObserver(accountObserver) }
  }

  private func fail(_ result: @escaping FlutterResult, _ code: String) {
    DispatchQueue.main.async {
      result(FlutterError(code: code, message: nil, details: nil))
    }
  }

  private func identity(_ expected: String?, _ done: @escaping (String?) -> Void) {
    container.accountStatus { status, error in
      guard error == nil, status == .available else { done(nil); return }
      self.container.fetchUserRecordID { record, _ in
        guard let record else { done(nil); return }
        let scoped = "icloud:" + record.recordName
        done(expected == nil || scoped == expected ? record.recordName : nil)
      }
    }
  }

  private func currentEpoch() -> UInt64 {
    epochLock.lock(); defer { epochLock.unlock() }
    return accountEpoch
  }

  private func decodedProperties(_ record: CKRecord) -> [String: String]? {
    guard let json = record["propertiesJSON"] as? String,
          json.utf8.count <= 65536,
          let data = json.data(using: .utf8),
          let value = try? JSONSerialization.jsonObject(with: data),
          let object = value as? [String: Any] else { return nil }
    var properties: [String: String] = [:]
    for (key, rawValue) in object {
      guard key.utf8.count <= 128,
            let property = rawValue as? String,
            property.utf8.count <= 4096 else { return nil }
      properties[key] = property
    }
    return properties
  }

  private func encodedProperties(_ properties: [String: String]) -> String? {
    guard properties.count <= 256,
          properties.allSatisfy({ $0.key.utf8.count <= 128 && $0.value.utf8.count <= 4096 }),
          let data = try? JSONSerialization.data(withJSONObject: properties, options: [.sortedKeys]),
          data.count <= 65536 else { return nil }
    return String(data: data, encoding: .utf8)
  }

  private func metadata(_ record: CKRecord) -> [String: Any]? {
    guard let properties = decodedProperties(record) else { return nil }
    return ["id": record.recordID.recordName,
     "name": record["name"] as? String ?? "",
     "properties": properties,
     "changeTag": record.recordChangeTag ?? "",
     "size": record[self.sizeKey] as? Int ?? 0,
     "modifiedTime": (record.modificationDate ?? Date()).ISO8601Format()]
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "status" {
      let statusEpoch = currentEpoch()
      identity(nil) { name in
        DispatchQueue.main.async {
          let stillCurrent = statusEpoch == self.currentEpoch()
          let activeName = stillCurrent ? name : nil
          result(["available": activeName != nil,
                  "recordName": activeName as Any? ?? NSNull()])
        }
      }
      return
    }
    guard let args = call.arguments as? [String: Any],
          let account = args["accountID"] as? String,
          account.hasPrefix("icloud:") else { fail(result, "account_unavailable"); return }
    let context = RequestContext(accountID: account, epoch: currentEpoch())
    identity(account) { [weak self] name in
      guard let self else {
        DispatchQueue.main.async { result(FlutterError(code: "icloud_unavailable", message: nil, details: nil)) }
        return
      }
      guard name != nil, context.epoch == self.currentEpoch() else { self.fail(result, "account_unavailable"); return }
      // Revalidate at response time as well. A device account switch while a
      // CloudKit request is pending must never look like a successful sync.
      let checkedResult: FlutterResult = { [weak self] value in
        guard let self else {
          DispatchQueue.main.async { result(FlutterError(code: "icloud_unavailable", message: nil, details: nil)) }
          return
        }
        self.identity(account) { stillCurrent in
          DispatchQueue.main.async {
            guard stillCurrent != nil, context.epoch == self.currentEpoch() else { self.fail(result, "account_unavailable"); return }
            result(value)
          }
        }
      }
      self.perform(call.method, args, context, checkedResult)
    }
  }

  private func validate(_ context: RequestContext, done: @escaping (Bool) -> Void) {
    guard context.epoch == currentEpoch() else { done(false); return }
    identity(context.accountID) { recordName in
      done(recordName != nil && context.epoch == self.currentEpoch())
    }
  }

  private func fetch(_ id: String, _ done: @escaping (CKRecord?, Error?) -> Void) {
    db.fetch(withRecordID: CKRecord.ID(recordName: id)) { record, error in
      if let ck = error as? CKError, ck.code == .unknownItem { done(nil, nil) }
      else { done(record, error) }
    }
  }

  private func contentURL(_ content: String) throws -> URL {
    let data = Data(content.utf8)
    guard data.count <= maxBytes else { throw NSError(domain: "icloud", code: 1) }
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent("singbook-cloudkit-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let url = dir.appendingPathComponent("body")
    do { try data.write(to: url, options: .atomic); return url }
    catch { try? FileManager.default.removeItem(at: dir); throw error }
  }

  private func attachContent(_ content: String, to record: CKRecord) throws -> URL {
    let url = try contentURL(content)
    record["contentAsset"] = CKAsset(fileURL: url)
    record[self.sizeKey] = content.utf8.count as CKRecordValue
    return url.deletingLastPathComponent()
  }

  private func assetText(_ record: CKRecord) throws -> String {
    guard let asset = record["contentAsset"] as? CKAsset, let url = asset.fileURL else { throw PayloadError.missing }
    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
    guard let size = attributes[.size] as? NSNumber else { throw PayloadError.invalid }
    guard size.intValue <= maxBytes else { throw PayloadError.tooLarge }
    guard let value = String(data: try Data(contentsOf: url, options: .mappedIfSafe), encoding: .utf8) else { throw PayloadError.invalid }
    return value
  }

  private func perform(_ method: String, _ args: [String: Any], _ context: RequestContext, _ result: @escaping FlutterResult) {
    switch method {
    case "list":
      let query = CKQuery(recordType: type, predicate: NSPredicate(value: true))
      var rows = [[String: Any]]()
      var scanned = 0
      var recordFailure = false
      func page(_ cursor: CKQueryOperation.Cursor?) {
        let op: CKQueryOperation
        if let cursor { op = CKQueryOperation(cursor: cursor) } else { op = CKQueryOperation(query: query) }
        op.desiredKeys = ["name", "propertiesJSON", self.sizeKey, self.tombstoneKey]
        op.recordMatchedBlock = { _, outcome in
          switch outcome {
          case .success(let record):
            scanned += 1
            if scanned > self.maxRecords { op.cancel() }
            if record[self.tombstoneKey] as? Bool != true {
              guard let item = self.metadata(record) else { recordFailure = true; op.cancel(); return }
              rows.append(item)
            }
          case .failure:
            recordFailure = true
            op.cancel()
          }
        }
        op.queryCompletionBlock = { next, error in
          guard scanned <= self.maxRecords else { self.fail(result, "remote_library_too_large"); return }
          guard !recordFailure else { self.fail(result, "invalid_remote_data"); return }
          guard error == nil else { self.fail(result, "icloud_unavailable"); return }
          if let next { page(next) } else { result(rows) }
        }
        self.db.add(op)
      }
      page(nil)

    case "get", "read", "update", "delete":
      guard let id = args["id"] as? String, UUID(uuidString: id) != nil else { fail(result, "invalid_remote_data"); return }
      fetch(id) { record, error in
        guard error == nil else { self.fail(result, "icloud_unavailable"); return }
        guard let record, record[self.tombstoneKey] as? Bool != true else { self.fail(result, "remote_file_missing"); return }
        if method == "get" {
          guard let item = self.metadata(record) else { self.fail(result, "invalid_remote_data"); return }
          result(item)
          return
        }
        if method == "read" {
          do { result(["content": try self.assetText(record)]) }
          catch PayloadError.tooLarge { self.fail(result, "remote_file_too_large") }
          catch PayloadError.missing { self.fail(result, "invalid_remote_data") }
          catch PayloadError.invalid { self.fail(result, "invalid_remote_data") }
          catch { self.fail(result, "icloud_unavailable") }
          return
        }
        guard let expectedTag = args["changeTag"] as? String,
              expectedTag == record.recordChangeTag else { self.fail(result, "sync_conflict"); return }
        if method == "delete" {
          // Physical deletes cannot be guarded by savePolicy. Saving a tombstone
          // as the fetched record keeps the same server change-tag protection.
          record[self.tombstoneKey] = true as CKRecordValue
          record[self.sizeKey] = 0 as CKRecordValue
          record["contentAsset"] = nil
          record["propertiesJSON"] = "{}" as CKRecordValue
          self.modify([record], temporaryDirectories: [], context: context, result: result)
          return
        }
        guard let content = args["content"] as? String,
              let properties = args["properties"] as? [String: String],
              let propertiesJSON = self.encodedProperties(properties) else { self.fail(result, "invalid_local_data"); return }
        do {
          let directory = try self.attachContent(content, to: record)
          record["propertiesJSON"] = propertiesJSON as CKRecordValue
          record[self.tombstoneKey] = false as CKRecordValue
          self.modify([record], temporaryDirectories: [directory], context: context, result: result)
        } catch { self.fail(result, "local_file_too_large") }
      }

    case "create":
      guard let name = args["name"] as? String,
            let content = args["content"] as? String,
            let properties = args["properties"] as? [String: String],
            let propertiesJSON = encodedProperties(properties) else { fail(result, "invalid_local_data"); return }
      let record = CKRecord(recordType: type, recordID: CKRecord.ID(recordName: UUID().uuidString.lowercased()))
      record["name"] = name as CKRecordValue
      record["propertiesJSON"] = propertiesJSON as CKRecordValue
      record[self.tombstoneKey] = false as CKRecordValue
      do {
        let directory = try attachContent(content, to: record)
        modify([record], temporaryDirectories: [directory], context: context, result: result)
      } catch { fail(result, "local_file_too_large") }
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func modify(_ records: [CKRecord], temporaryDirectories: [URL], context: RequestContext, result: @escaping FlutterResult) {
    // Identity and epoch are rechecked immediately before submission, after any
    // preceding fetch/validation work. Never enqueue a write across an account switch.
    validate(context) { [weak self] valid in
      guard let self else {
        temporaryDirectories.forEach { try? FileManager.default.removeItem(at: $0) }
        DispatchQueue.main.async { result(FlutterError(code: "icloud_unavailable", message: nil, details: nil)) }
        return
      }
      guard valid else {
        temporaryDirectories.forEach { try? FileManager.default.removeItem(at: $0) }
        self.fail(result, "account_unavailable")
        return
      }
      self.submit(records, temporaryDirectories: temporaryDirectories, result: result)
    }
  }

  private func submit(_ records: [CKRecord], temporaryDirectories: [URL], result: @escaping FlutterResult) {
    let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
    operation.savePolicy = .ifServerRecordUnchanged
    var savedRecord: CKRecord?
    var saveError: Error?
    operation.perRecordSaveBlock = { _, outcome in
      switch outcome {
      case .success(let record): savedRecord = record
      case .failure(let error): saveError = error
      }
    }
    operation.modifyRecordsResultBlock = { outcome in
      temporaryDirectories.forEach { try? FileManager.default.removeItem(at: $0) }
      switch outcome {
      case .success:
        if let saveError { self.fail(result, self.errorCode(saveError)) }
        else if let record = savedRecord, let item = self.metadata(record) { result(item) }
        else { self.fail(result, "invalid_remote_data") }
      case .failure(let error): self.fail(result, self.errorCode(error))
      }
    }
    db.add(operation)
  }

  private func errorCode(_ error: Error) -> String {
    (error as? CKError)?.code == .serverRecordChanged ? "sync_conflict" : "icloud_unavailable"
  }
}
