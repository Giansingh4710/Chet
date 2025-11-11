//
//  BackupManager.swift
//  Chet
//
//  Manages automatic and manual backup/restore of app data to iCloud Drive
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

// MARK: - Backup Data Models

struct ChetBackup: Codable {
    let createdAt: Date
    let appVersion: String
    let settings: BackupSettings
    let rootFolders: [BackupFolder] // Nested structure starting from root

    struct BackupSettings: Codable {
        // Display & UI
        var colorScheme: String
        var fontType: String
        var compactRowView: Bool

        // Shabad Display
        var larivaarOn: Bool
        var textScale: Double
        var swipeToGoToNextShabad: Bool
        var qwertyKeyboard: Bool

        // Text Scales
        var englishTranslationTextScale: Double
        var punjabiTranslationTextScale: Double
        var hindiTranslationTextScale: Double
        var spanishTranslationTextScale: Double
        var transliterationTextScale: Double

        // Translation Sources
        var visraamSource: String
        var englishSource: String
        var punjabiSource: String
        var hindiSource: String
        var spanishSource: String
        var transliterationSource: String

        // Widget Settings
        var randSbdRefreshInterval: Int
        var favSbdRefreshInterval: Int
    }
}

struct BackupFolder: Codable, Identifiable {
    let id: UUID
    let name: String
    let isSystemFolder: Bool
    let sortIndex: Int
    let shabads: [BackupShabad] // Shabads in this folder
    let subfolders: [BackupFolder] // Nested subfolders
}

struct BackupShabad: Codable, Identifiable {
    let id: UUID
    let shabadId: Int // API shabad ID
    let title: String // Gurmukhi text of the selected line
    let indexOfSelectedLine: Int
    let sortIndex: Int
    let addedAt: Date
}

// MARK: - Backup Manager

@MainActor
class BackupManager {
    static let shared = BackupManager()

    private let maxBackupCount = 10
    private var lastBackupTime: Date?
    private let minimumBackupInterval: TimeInterval = 300 // 5 minutes

    private init() {
        // Load last backup time from UserDefaults
        if let timestamp = UserDefaults.standard.object(forKey: "lastAutoBackupTime") as? Date {
            lastBackupTime = timestamp
        }
    }

    // MARK: - Export Methods

    /// Exports all app data and settings to JSON
    func exportToJSON(modelContext: ModelContext) async throws -> Data {
        // Get current app version
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

        // Export settings
        let settings = SettingsStorage.exportAll()

        // Fetch root folders (folders without parent)
        let rootFolderDescriptor = FetchDescriptor<Folder>(
            predicate: #Predicate { $0.parentFolder == nil },
            sortBy: [SortDescriptor(\.sortIndex)]
        )
        let rootFolders = try modelContext.fetch(rootFolderDescriptor)

        // Recursively convert folders to backup format
        let backupRootFolders = rootFolders.map { folder in
            convertFolderToBackup(folder)
        }

        // Create backup object
        let backup = ChetBackup(
            createdAt: Date(),
            appVersion: appVersion,
            settings: settings,
            rootFolders: backupRootFolders
        )

        // Encode to JSON with pretty printing
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        return try encoder.encode(backup)
    }

    /// Recursively converts a Folder and its contents to BackupFolder format
    private func convertFolderToBackup(_ folder: Folder) -> BackupFolder {
        // Convert shabads in this folder
        let backupShabads = folder.savedShabads
            .sorted(by: { $0.sortIndex > $1.sortIndex })
            .map { shabad in
                // Get the correct verse index (use 0 if -1)
                let verseIndex = shabad.indexOfSelectedLine >= 0 ? shabad.indexOfSelectedLine : 0
                let title = shabad.sbdRes.verses[verseIndex].verse.gurmukhi

                return BackupShabad(
                    id: shabad.id,
                    shabadId: shabad.sbdRes.shabadInfo.shabadId,
                    title: title,
                    indexOfSelectedLine: shabad.indexOfSelectedLine,
                    sortIndex: shabad.sortIndex,
                    addedAt: shabad.addedAt
                )
            }

        // Recursively convert subfolders
        let backupSubfolders = folder.subfolders
            .sorted(by: { $0.sortIndex < $1.sortIndex })
            .map { subfolder in
                convertFolderToBackup(subfolder)
            }

        return BackupFolder(
            id: folder.id,
            name: folder.name,
            isSystemFolder: folder.isSystemFolder,
            sortIndex: folder.sortIndex,
            shabads: backupShabads,
            subfolders: backupSubfolders
        )
    }

    /// Saves backup data to iCloud Drive (or local Documents if iCloud unavailable)
    func saveToiCloud(data: Data, filename: String? = nil) async throws -> URL {
        // Try to get iCloud Drive Documents directory first
        let backupURL: URL

        if let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents")
            .appendingPathComponent("Chet Backups")
        {
            // iCloud is available
            backupURL = iCloudURL
            print("💾 Using iCloud Drive for backup")
        } else {
            // Fallback to local Documents directory
            guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                throw BackupError.iCloudNotAvailable
            }
            backupURL = documentsURL.appendingPathComponent("Chet Backups")
            print("💾 iCloud not available, using local storage for backup")
        }

        // Create directory if it doesn't exist
        try FileManager.default.createDirectory(at: backupURL, withIntermediateDirectories: true)

        // Generate filename with timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let finalFilename = filename ?? "Chet_Backup_\(timestamp).chet"

        let fileURL = backupURL.appendingPathComponent(finalFilename)

        // Write data to file
        try data.write(to: fileURL)

        print("✅ Backup saved to: \(fileURL.path)")

        // Clean up old backups (keep only last 10)
        try await cleanupOldBackups(in: backupURL)

        return fileURL
    }

    /// Performs automatic backup (debounced)
    func performAutoBackup(modelContext: ModelContext) async {
        // Check if enough time has passed since last backup
        if let lastTime = lastBackupTime,
           Date().timeIntervalSince(lastTime) < minimumBackupInterval
        {
            print("⏳ Skipping auto-backup: too soon since last backup")
            return
        }

        do {
            print("💾 Starting auto-backup...")
            let data = try await exportToJSON(modelContext: modelContext)
            _ = try await saveToiCloud(data: data)

            // Update last backup time
            lastBackupTime = Date()
            UserDefaults.standard.set(lastBackupTime, forKey: "lastAutoBackupTime")

            print("✅ Auto-backup completed successfully")
        } catch {
            print("❌ Auto-backup failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Restore Methods

    /// Restores app data and settings from JSON backup
    func restoreFromJSON(
        data: Data,
        modelContext: ModelContext,
        onProgress: @MainActor @escaping (Int) -> Void
    ) async throws {
        // Decode backup
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(ChetBackup.self, from: data)

        // Restore settings
        SettingsStorage.importAll(from: backup.settings)

        // Create a root import folder to contain all restored data
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        let timestamp = dateFormatter.string(from: backup.createdAt)
        let importFolderName = "Chet Backup Import (\(timestamp))"

        let importFolder = Folder(name: importFolderName, parentFolder: nil)
        modelContext.insert(importFolder)

        // Save the import folder first to establish it in the context
        try modelContext.save()

        print("📦 Created import container: '\(importFolderName)'")

        // Track total shabads restored across all folders
        var totalImported = 0

        // Recursively restore folders and shabads inside the import folder
        for backupFolder in backup.rootFolders {
            await restoreFolderRecursively(
                backupFolder: backupFolder,
                parentFolder: importFolder,  // Set import folder as parent
                modelContext: modelContext,
                totalCount: &totalImported,
                onProgress: onProgress
            )
        }

        // Final save
        try modelContext.save()

        print("✅ Restore completed: \(totalImported) shabads restored in '\(importFolderName)'")
    }

    /// Recursively restores a folder, its shabads, and subfolders
    private func restoreFolderRecursively(
        backupFolder: BackupFolder,
        parentFolder: Folder?,
        modelContext: ModelContext,
        totalCount: inout Int,
        onProgress: @MainActor @escaping (Int) -> Void
    ) async {
        // Create the folder
        let folder = Folder(
            name: backupFolder.name,
            parentFolder: parentFolder,
            isSystemFolder: backupFolder.isSystemFolder,
            sortIndex: backupFolder.sortIndex
        )

        // Don't preserve original IDs - let SwiftData generate new ones to avoid conflicts
        modelContext.insert(folder)

        // Save immediately to establish the folder in the context
        try? modelContext.save()

        print("📁 Created folder: \(folder.name) (parent: \(parentFolder?.name ?? "root"))")

        // Restore shabads in this folder
        for backupShabad in backupFolder.shabads {
            do {
                // Fetch shabad data from API
                let shabadResponse = try await fetchShabadResponse(from: backupShabad.shabadId)

                // Create saved shabad
                let savedShabad = SavedShabad(
                    folder: folder,
                    sbdRes: shabadResponse,
                    indexOfSelectedLine: backupShabad.indexOfSelectedLine,
                    addedAt: backupShabad.addedAt,
                    sortIndex: backupShabad.sortIndex
                )

                modelContext.insert(savedShabad)

                // Save after each shabad to ensure it's associated with the folder
                try? modelContext.save()

                totalCount += 1
                onProgress(totalCount)

                print("  ✅ Restored shabad \(backupShabad.shabadId) to folder '\(folder.name)'")
            } catch {
                print("⚠️ Failed to restore shabad \(backupShabad.shabadId): \(error.localizedDescription)")
            }
        }

        // Recursively restore subfolders
        for subfolderBackup in backupFolder.subfolders {
            await restoreFolderRecursively(
                backupFolder: subfolderBackup,
                parentFolder: folder,
                modelContext: modelContext,
                totalCount: &totalCount,
                onProgress: onProgress
            )
        }
    }

    // MARK: - Helper Methods

    /// Removes old backups, keeping only the most recent ones
    private func cleanupOldBackups(in directory: URL) async throws {
        let fileManager = FileManager.default
        let files = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        )

        // Filter .chet files only
        let backupFiles = files.filter { $0.pathExtension == "chet" }

        // Sort by creation date (newest first)
        let sortedFiles = try backupFiles.sorted { url1, url2 in
            let date1 = try url1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
            let date2 = try url2.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
            return date1 > date2
        }

        // Delete files beyond the max count
        if sortedFiles.count > maxBackupCount {
            for file in sortedFiles.dropFirst(maxBackupCount) {
                try fileManager.removeItem(at: file)
                print("🗑️ Deleted old backup: \(file.lastPathComponent)")
            }
        }
    }

    /// Gets the list of available backups from iCloud Drive or local storage
    func getAvailableBackups() async throws -> [URL] {
        let backupURL: URL

        if let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents")
            .appendingPathComponent("Chet Backups")
        {
            backupURL = iCloudURL
        } else {
            // Fallback to local Documents directory
            guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                throw BackupError.iCloudNotAvailable
            }
            backupURL = documentsURL.appendingPathComponent("Chet Backups")
        }

        let fileManager = FileManager.default

        // Check if directory exists
        guard fileManager.fileExists(atPath: backupURL.path) else {
            return [] // No backups yet
        }

        let files = try fileManager.contentsOfDirectory(
            at: backupURL,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        )

        // Filter and sort .chet files by creation date (newest first)
        let backupFiles = files.filter { $0.pathExtension == "chet" }
        return try backupFiles.sorted { url1, url2 in
            let date1 = try url1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
            let date2 = try url2.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
            return date1 > date2
        }
    }
}

// MARK: - Settings Storage Helper

enum SettingsStorage {
    static func exportAll() -> ChetBackup.BackupSettings {
        let defaults = UserDefaults.standard
        let appGroupDefaults = UserDefaults.appGroup

        return ChetBackup.BackupSettings(
            // Display & UI
            colorScheme: defaults.string(forKey: "colorScheme") ?? "system",
            fontType: defaults.string(forKey: "fontType") ?? "Unicode",
            compactRowView: defaults.bool(forKey: "CompactRowViewSetting"),

            // Shabad Display
            larivaarOn: defaults.bool(forKey: "settings.larivaarOn"),
            textScale: defaults.double(forKey: "settings.textScale") != 0 ? defaults.double(forKey: "settings.textScale") : 1.0,
            swipeToGoToNextShabad: defaults.bool(forKey: "swipeToGoToNextShabadSetting"),
            qwertyKeyboard: defaults.bool(forKey: "settings.qwertyKeyboard"),

            // Text Scales
            englishTranslationTextScale: defaults.double(forKey: "settings.englishTranslationTextScale") != 0 ? defaults.double(forKey: "settings.englishTranslationTextScale") : 1.0,
            punjabiTranslationTextScale: defaults.double(forKey: "settings.punjabiTranslationTextScale") != 0 ? defaults.double(forKey: "settings.punjabiTranslationTextScale") : 1.0,
            hindiTranslationTextScale: defaults.double(forKey: "settings.hindiTranslationTextScale") != 0 ? defaults.double(forKey: "settings.hindiTranslationTextScale") : 1.0,
            spanishTranslationTextScale: defaults.double(forKey: "settings.spanishTranslationTextScale") != 0 ? defaults.double(forKey: "settings.spanishTranslationTextScale") : 1.0,
            transliterationTextScale: defaults.double(forKey: "settings.transliterationTextScale") != 0 ? defaults.double(forKey: "settings.transliterationTextScale") : 1.0,

            // Translation Sources
            visraamSource: defaults.string(forKey: "settings.visraamSource") ?? "igurbani",
            englishSource: defaults.string(forKey: "settings.englishSource") ?? "bdb",
            punjabiSource: defaults.string(forKey: "settings.punjabiSource") ?? "none",
            hindiSource: defaults.string(forKey: "settings.hindiSource") ?? "none",
            spanishSource: defaults.string(forKey: "settings.spanishSource") ?? "none",
            transliterationSource: defaults.string(forKey: "settings.transliterationSource") ?? "none",

            // Widget Settings
            randSbdRefreshInterval: appGroupDefaults.integer(forKey: "randSbdRefreshInterval") != 0 ? appGroupDefaults.integer(forKey: "randSbdRefreshInterval") : 3,
            favSbdRefreshInterval: appGroupDefaults.integer(forKey: "favSbdRefreshInterval") != 0 ? appGroupDefaults.integer(forKey: "favSbdRefreshInterval") : 3
        )
    }

    static func importAll(from settings: ChetBackup.BackupSettings) {
        let defaults = UserDefaults.standard
        let appGroupDefaults = UserDefaults.appGroup

        // Display & UI
        defaults.set(settings.colorScheme, forKey: "colorScheme")
        defaults.set(settings.fontType, forKey: "fontType")
        defaults.set(settings.compactRowView, forKey: "CompactRowViewSetting")

        // Shabad Display
        defaults.set(settings.larivaarOn, forKey: "settings.larivaarOn")
        defaults.set(settings.textScale, forKey: "settings.textScale")
        defaults.set(settings.swipeToGoToNextShabad, forKey: "swipeToGoToNextShabadSetting")
        defaults.set(settings.qwertyKeyboard, forKey: "settings.qwertyKeyboard")

        // Text Scales
        defaults.set(settings.englishTranslationTextScale, forKey: "settings.englishTranslationTextScale")
        defaults.set(settings.punjabiTranslationTextScale, forKey: "settings.punjabiTranslationTextScale")
        defaults.set(settings.hindiTranslationTextScale, forKey: "settings.hindiTranslationTextScale")
        defaults.set(settings.spanishTranslationTextScale, forKey: "settings.spanishTranslationTextScale")
        defaults.set(settings.transliterationTextScale, forKey: "settings.transliterationTextScale")

        // Translation Sources
        defaults.set(settings.visraamSource, forKey: "settings.visraamSource")
        defaults.set(settings.englishSource, forKey: "settings.englishSource")
        defaults.set(settings.punjabiSource, forKey: "settings.punjabiSource")
        defaults.set(settings.hindiSource, forKey: "settings.hindiSource")
        defaults.set(settings.spanishSource, forKey: "settings.spanishSource")
        defaults.set(settings.transliterationSource, forKey: "settings.transliterationSource")

        // Widget Settings
        appGroupDefaults.set(settings.randSbdRefreshInterval, forKey: "randSbdRefreshInterval")
        appGroupDefaults.set(settings.favSbdRefreshInterval, forKey: "favSbdRefreshInterval")

        defaults.synchronize()
        appGroupDefaults.synchronize()
    }
}

// MARK: - Errors

enum BackupError: LocalizedError {
    case iCloudNotAvailable
    case exportFailed(String)
    case restoreFailed(String)

    var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return "iCloud Drive is not available. Please sign in to iCloud in Settings."
        case let .exportFailed(reason):
            return "Failed to export backup: \(reason)"
        case let .restoreFailed(reason):
            return "Failed to restore backup: \(reason)"
        }
    }
}
