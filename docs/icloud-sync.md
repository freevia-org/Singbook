# iCloud sync backend

The Dart adapter reuses `GoogleDriveSyncService`'s `DriveAuthorization` and
`SyncCloudStore` contracts, so its baseline and conflict behavior remains shared.
Its account key is `icloud:<CloudKit user record name>`; account changes therefore
select a distinct baseline. CloudKit account absence or identity mismatch fails
closed and does not clear local library data.

## Native channel contract

Channel: `org.freevia.singbook/icloud_sync`. The app delegate installs
`ICloudSyncChannel(messenger:)` on its Flutter engine's binary messenger. Both
Apple targets use the private database in `iCloud.org.freevia.singbook` and the
`SingbookSyncItem` record type. The native side must have the matching CloudKit
container capability configured by the app integration.
The bridge constructs its CloudKit container lazily. Apple exposes missing
CloudKit entitlement and invalid-container failures through CloudKit account
status/operations rather than a public preflight entitlement query; these are
reported as unavailable so the app can fail closed. Configure the container
capability in the app targets before using the backend.

Every operation except `status` carries `accountID: "icloud:<recordName>"`.
Native code checks that the current available system account still has that
record name before accessing records.

| Method | Arguments | Result |
| --- | --- | --- |
| `status` | none | `{available: bool, recordName: string?}` |
| `list` | `accountID` | list of metadata maps |
| `get` | `accountID`, `id` | metadata map or null if absent |
| `read` | `accountID`, `id` | `{content: string}` |
| `create` | `accountID`, `name`, `content`, `properties` | saved metadata map |
| `update` | `accountID`, `id`, `changeTag`, `content`, `properties` | saved metadata |
| `delete` | `accountID`, `id`, `changeTag` | saved tombstone metadata |

Metadata includes `id` (UUID record name), `name`, string map `properties`,
`changeTag` (the exact CloudKit record change tag), UTF-8 `size`, and
`modifiedTime`. The `SingbookSyncItem` fields are `name` (String),
`contentAsset` (CKAsset), `contentSize` (Int), `propertiesJSON` (String holding
a JSON object of string keys and values), and `deleted` (Bool). The adapter
strictly decodes that JSON and rejects non-string or oversized values. The
complete UTF-8 body is uploaded through a temporary
asset file so a 16 MiB body does not exceed CloudKit's per-field string limit;
the temporary directory is removed after the CloudKit operation completes.
Names are canonical sync names and content is limited to 16 MiB. Lists follow
CloudKit cursors, fail on any per-record error, and stop with
`remote_library_too_large` after 40,000 total records. Tombstones count toward
that bound even though they are omitted from the returned list.

Delete saves a tombstone on the fetched record rather than physically deleting
it. A tombstone has `deleted = true`, size zero, no content asset, and
`propertiesJSON = "{}"`. `list`, `get`, and `read` treat tombstones as missing; updates cannot
resurrect them. Only a fresh `create` with a new UUID can create an item again.
This preserves conditional deletion: native code compares the supplied exact
change tag and saves the tombstone with
`CKModifyRecordsOperation.ifServerRecordUnchanged`. Updates use the same
compare-and-save sequence. A conflict reports `sync_conflict`. Successful
mutations return metadata from CloudKit's saved-record callback, including the
server change tag.

Each operation captures an account-change epoch and checks both that epoch and
the active CloudKit identity before dispatching its result to Flutter's main
queue. A switch away and back while an operation is pending still invalidates
that response.

The backend stores complete ChordPro text and protocol properties verbatim,
including legacy `x_verse` payload data. It does not manufacture OAuth tokens
or offer a separate sign-in flow; iCloud identity comes from CloudKit.
