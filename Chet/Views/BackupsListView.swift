//
//  BackupsListView.swift
//  Chet
//
//  Created by gian singh on 11/13/25.
//

import SwiftUI

struct BackupFile: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let createdAt: Date
    let size: Int64

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var isAutoBackup: Bool {
        name.hasPrefix("Chet_Backup_")
    }
}

struct BackupsListView: View {
    @State private var backups: [BackupFile] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var backupToDelete: BackupFile?
    @State private var showDeleteConfirmation = false
    @State private var showPathInfo = false
    @State private var backupFolderPath: String = ""

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading backups...")
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    Text("Error Loading Backups")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Retry") {
                        loadBackups()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if backups.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No Backups Found")
                        .font(.headline)
                    Text("Backups will appear here after you create them")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                List {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Backups accessible in Files app")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Open Files app → On My iPhone → Chet → Chet Backups")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    Section {
                        ForEach(backups) { backup in
                            BackupRow(backup: backup, onDelete: {
                                backupToDelete = backup
                                showDeleteConfirmation = true
                            })
                        }
                    } header: {
                        HStack {
                            Text("Backups")
                            Spacer()
                            Text("\(backups.count)")
                                .foregroundColor(.secondary)
                        }
                    } footer: {
                        VStack(alignment: .leading, spacing: 8) {
                            if !backupFolderPath.isEmpty {
                                Text("Location: \(backupFolderPath)")
                                    .font(.caption)
                                    .textSelection(.enabled)
                            }
                            Button(action: {
                                showPathInfo = true
                            }) {
                                Text("Show Storage Location")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Saved Backups")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Open backup folder in Files app
                    if let url = getBackupFolderURL() {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Image(systemName: "folder")
                }
            }
        }
        .onAppear {
            loadBackups()
        }
        .alert("Delete Backup?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                backupToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let backup = backupToDelete {
                    deleteBackup(backup)
                }
            }
        } message: {
            if let backup = backupToDelete {
                Text("Are you sure you want to delete '\(backup.name)'? This action cannot be undone.")
            }
        }
        .alert("Backup Storage Location", isPresented: $showPathInfo) {
            Button("Copy Path", action: {
                UIPasteboard.general.string = backupFolderPath
            })
            Button("OK", role: .cancel) { }
        } message: {
            Text(backupFolderPath.isEmpty ? "No backups found" : "Backups are stored at:\n\n\(backupFolderPath)\n\nThese backups are accessible in the Files app under:\nOn My iPhone → Chet → Chet Backups\n\n✅ Survives app deletion (as long as you don't delete app data)\n✅ Can be shared or exported anytime")
        }
    }

    private func loadBackups() {
        isLoading = true
        errorMessage = nil

        guard let backupFolderURL = getBackupFolderURL() else {
            errorMessage = "Could not access backup folder"
            isLoading = false
            return
        }

        // Store the path for display
        backupFolderPath = backupFolderURL.path
        print("📁 Backup folder path: \(backupFolderPath)")

        do {
            // Check if directory exists
            var isDirectory: ObjCBool = false
            if !FileManager.default.fileExists(atPath: backupFolderURL.path, isDirectory: &isDirectory) || !isDirectory.boolValue {
                // Directory doesn't exist yet
                backups = []
                isLoading = false
                print("📁 Backup folder doesn't exist yet at: \(backupFolderPath)")
                return
            }

            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: backupFolderURL,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            )

            let chetBackups = fileURLs.filter { $0.pathExtension == "chet" }

            backups = chetBackups.compactMap { url in
                guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                      let createdAt = attributes[.creationDate] as? Date,
                      let size = attributes[.size] as? Int64 else {
                    return nil
                }

                return BackupFile(
                    url: url,
                    name: url.lastPathComponent,
                    createdAt: createdAt,
                    size: size
                )
            }
            .sorted { $0.createdAt > $1.createdAt } // Most recent first

            isLoading = false
        } catch {
            errorMessage = "Failed to load backups: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func getBackupFolderURL() -> URL? {
        // Use Documents folder (accessible via Files app with UIFileSharingEnabled)
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsURL.appendingPathComponent("Chet Backups")
    }

    private func deleteBackup(_ backup: BackupFile) {
        do {
            try FileManager.default.removeItem(at: backup.url)
            backups.removeAll { $0.id == backup.id }
            backupToDelete = nil
        } catch {
            errorMessage = "Failed to delete backup: \(error.localizedDescription)"
        }
    }
}

struct BackupRow: View {
    let backup: BackupFile
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: backup.isAutoBackup ? "clock.arrow.circlepath" : "doc.fill")
                .font(.system(size: 28))
                .foregroundColor(backup.isAutoBackup ? .blue : .green)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(backup.name)
                    .font(.subheadline)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    Text(backup.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(backup.formattedSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Menu {
                Button(action: {
                    shareBackup(backup)
                }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func shareBackup(_ backup: BackupFile) {
        let activityVC = UIActivityViewController(
            activityItems: [backup.url],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            // For iPad: set popover presentation
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    NavigationStack {
        BackupsListView()
    }
}
