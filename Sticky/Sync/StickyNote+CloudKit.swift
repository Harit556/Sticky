import CloudKit
import Foundation

extension StickyNote {
    static let ckRecordType = "StickyNote"

    // MARK: - CKRecord → StickyNote

    init?(from record: CKRecord) {
        guard
            let id            = UUID(uuidString: record.recordID.recordName),
            let title         = record["title"]         as? String,
            let createdAt     = record["createdAt"]     as? Date,
            let lastModified  = record["lastModifiedAt"] as? Date,
            let tasksData     = record["tasksData"]     as? Data,
            let themeData     = record["colorThemeData"] as? Data
        else { return nil }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard
            let tasks      = try? decoder.decode([TodoItem].self, from: tasksData),
            let colorTheme = try? decoder.decode(StickyColorTheme.self, from: themeData)
        else { return nil }

        var windowFrame: CodableRect? = nil
        if let frameData = record["windowFrameData"] as? Data {
            windowFrame = try? decoder.decode(CodableRect.self, from: frameData)
        }

        self.init(
            id:               id,
            title:            title,
            tasks:            tasks,
            colorTheme:       colorTheme,
            windowFrame:      windowFrame,
            createdAt:        createdAt,
            lastModifiedAt:   lastModified,
            isAlwaysOnTop:    (record["isAlwaysOnTop"]    as? Int ?? 1) == 1,
            autoSortCompleted:(record["autoSortCompleted"] as? Int ?? 0) == 1,
            isMinimized:      (record["isMinimized"]       as? Int ?? 0) == 1,
            soundEffect:      (record["soundEffectRaw"]        as? String).flatMap { SoundEffect(rawValue: $0) },
            confettiSize:     (record["confettiSizeRaw"]       as? String).flatMap { ConfettiSize(rawValue: $0) },
            confettiAmount:   (record["confettiAmountRaw"]     as? String).flatMap { ConfettiAmount(rawValue: $0) },
            confettiGravity:  (record["confettiGravityRaw"]    as? String).flatMap { ConfettiGravity(rawValue: $0) },
            confettiVolume:   (record["confettiVolumeRaw"]     as? String).flatMap { ConfettiVolume(rawValue: $0) },
            confettiColorScheme:(record["confettiColorSchemeRaw"] as? String).flatMap { ConfettiColorScheme(rawValue: $0) },
            confettiStyle:    (record["confettiStyleRaw"]      as? String).flatMap { ConfettiStyle(rawValue: $0) }
        )
    }

    // MARK: - StickyNote → CKRecord

    /// Creates a fresh CKRecord. Saved with .allKeys policy so no recordChangeTag needed.
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record   = CKRecord(recordType: Self.ckRecordType, recordID: recordID)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        record["title"]         = title         as CKRecordValue
        record["createdAt"]     = createdAt      as CKRecordValue
        record["lastModifiedAt"] = lastModifiedAt as CKRecordValue
        record["isAlwaysOnTop"]     = (isAlwaysOnTop     ? 1 : 0) as CKRecordValue
        record["autoSortCompleted"] = (autoSortCompleted ? 1 : 0) as CKRecordValue
        record["isMinimized"]       = (isMinimized       ? 1 : 0) as CKRecordValue

        // Optional raw-value fields — setValue(nil) clears the field on CloudKit
        record.setValue(soundEffect?.rawValue,        forKey: "soundEffectRaw")
        record.setValue(confettiSize?.rawValue,       forKey: "confettiSizeRaw")
        record.setValue(confettiAmount?.rawValue,     forKey: "confettiAmountRaw")
        record.setValue(confettiGravity?.rawValue,    forKey: "confettiGravityRaw")
        record.setValue(confettiVolume?.rawValue,     forKey: "confettiVolumeRaw")
        record.setValue(confettiColorScheme?.rawValue, forKey: "confettiColorSchemeRaw")
        record.setValue(confettiStyle?.rawValue,      forKey: "confettiStyleRaw")

        if let data = try? encoder.encode(tasks)      { record["tasksData"]      = data as CKRecordValue }
        if let data = try? encoder.encode(colorTheme) { record["colorThemeData"] = data as CKRecordValue }
        if let frame = windowFrame, let data = try? encoder.encode(frame) {
            record["windowFrameData"] = data as CKRecordValue
        }

        return record
    }
}
