import CloudKit
import Foundation

/// Handles all CloudKit private-database operations.
/// StickyStore is the local source of truth; this class pushes/pulls changes on top.
///
/// IMPORTANT: CKContainer(identifier:) aborts with a breakpoint trap if the app
/// has no iCloud entitlement. We must NEVER touch CKContainer unless we know
/// the entitlement is present. We guard via `ubiquityIdentityToken` — nil when
/// either the user isn't signed into iCloud or the app lacks the entitlement.
@MainActor
final class CloudKitSync {
    static let shared = CloudKitSync()

    private let containerIdentifier = "iCloud.com.stickytodos.app"

    /// Flip to `true` after enabling the iCloud + CloudKit capability in Xcode
    /// AND adding `com.apple.developer.icloud-container-identifiers` to entitlements.
    /// Touching CKContainer(identifier:) without those entitlements crashes the app
    /// with a debug breakpoint that cannot be caught at runtime.
    private static let cloudKitEnabled = false

    /// Lazily created — only when CloudKit is enabled. Always nil otherwise.
    private lazy var container: CKContainer? = {
        guard Self.cloudKitEnabled else {
            print("[CloudKit] sync disabled — flip CloudKitSync.cloudKitEnabled when iCloud entitlement is configured")
            return nil
        }
        return CKContainer(identifier: containerIdentifier)
    }()

    private var db: CKDatabase? { container?.privateCloudDatabase }

    private init() {}

    // MARK: - Account check

    func isAvailable() async -> Bool {
        guard let container else { return false }
        return (try? await container.accountStatus()) == .available
    }

    // MARK: - Fetch all

    func fetchAll() async throws -> [StickyNote] {
        guard let db else { return [] }
        let query = CKQuery(recordType: "StickyNote", predicate: NSPredicate(value: true))
        let (results, _) = try await db.records(
            matching: query,
            inZoneWith: nil,
            desiredKeys: nil,
            resultsLimit: 500
        )
        return results.compactMap { (_, result) -> StickyNote? in
            guard case .success(let record) = result else { return nil }
            return StickyNote(from: record)
        }
    }

    // MARK: - Push one sticky

    /// Saves a sticky to CloudKit using .allKeys policy (last-write-wins).
    func push(_ sticky: StickyNote) async {
        guard let db, await isAvailable() else { return }
        let record = sticky.toCKRecord()
        do {
            try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
                let op = CKModifyRecordsOperation(recordsToSave: [record])
                op.savePolicy = .allKeys
                op.isAtomic = false
                op.modifyRecordsResultBlock = { c.resume(with: $0) }
                db.add(op)
            }
        } catch {
            print("[CloudKit] push error for \(sticky.id): \(error)")
        }
    }

    // MARK: - Delete one sticky

    func delete(id: UUID) async {
        guard let db, await isAvailable() else { return }
        let recordID = CKRecord.ID(recordName: id.uuidString)
        do {
            try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
                let op = CKModifyRecordsOperation(recordIDsToDelete: [recordID])
                op.modifyRecordsResultBlock = { c.resume(with: $0) }
                db.add(op)
            }
        } catch {
            print("[CloudKit] delete error for \(id): \(error)")
        }
    }
}
