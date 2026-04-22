import CloudKit
import Foundation

/// Handles all CloudKit private-database operations.
/// StickyStore is the local source of truth; this class pushes/pulls changes on top.
@MainActor
final class CloudKitSync {
    static let shared = CloudKitSync()

    private let container = CKContainer(identifier: "iCloud.com.stickytodos.app")
    private var db: CKDatabase { container.privateCloudDatabase }

    private init() {}

    // MARK: - Account check

    func isAvailable() async -> Bool {
        (try? await container.accountStatus()) == .available
    }

    // MARK: - Fetch all

    func fetchAll() async throws -> [StickyNote] {
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
        guard await isAvailable() else { return }
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
        guard await isAvailable() else { return }
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
