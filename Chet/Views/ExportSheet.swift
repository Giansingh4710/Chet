//
//  ExportSheet.swift
//  Chet
//
//  Sheet for exporting/backing up app data
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var isExporting = false
    @State private var exportCompleted = false
    @State private var exportError: String?
    @State private var exportedFileURL: URL?
    @State private var showShareSheet = false

    // Stats
    @State private var folderCount = 0
    @State private var shabadCount = 0
    @State private var estimatedFileSize = "Calculating..."

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isExporting {
                    // Exporting state
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()

                    Text("Exporting your data...")
                        .font(.headline)

                    Text("This may take a moment")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                } else if exportCompleted {
                    // Success state
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)

                    Text("Export Successful!")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Your backup has been saved to iCloud Drive")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    if let url = exportedFileURL {
                        Button(action: {
                            showShareSheet = true
                        }) {
                            Label("Share Backup", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)
                        .padding(.top)
                    }

                } else if let error = exportError {
                    // Error state
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)

                    Text("Export Failed")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button("Try Again") {
                        exportError = nil
                    }
                    .buttonStyle(.bordered)
                    .padding(.top)

                } else {
                    // Initial state - show stats
                    VStack(spacing: 16) {
                        Image(systemName: "externaldrive.badge.icloud")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("Export Your Data")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Create a backup of all your saved shabads and settings")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Stats
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                            Text("\(folderCount) folders")
                                .font(.body)
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                        HStack {
                            Image(systemName: "bookmark.fill")
                                .foregroundColor(.blue)
                            Text("\(shabadCount) saved shabads")
                                .font(.body)
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(.blue)
                            Text("All app settings")
                                .font(.body)
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Export button
                    Button(action: {
                        Task { await performExport() }
                    }) {
                        Label("Export to iCloud Drive", systemImage: "icloud.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .navigationTitle("Backup Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(items: [url])
                }
            }
            .task {
                await loadStats()
            }
        }
    }

    // MARK: - Methods

    private func loadStats() async {
        do {
            // Count folders
            let folderDescriptor = FetchDescriptor<Folder>()
            let folders = try modelContext.fetch(folderDescriptor)
            folderCount = folders.count

            // Count shabads
            let shabadDescriptor = FetchDescriptor<SavedShabad>()
            let shabads = try modelContext.fetch(shabadDescriptor)
            shabadCount = shabads.count

        } catch {
            print("Failed to load stats: \(error)")
        }
    }

    private func performExport() async {
        isExporting = true

        do {
            // Export data
            let data = try await BackupManager.shared.exportToJSON(modelContext: modelContext)

            // Save to iCloud
            let url = try await BackupManager.shared.saveToiCloud(data: data)

            await MainActor.run {
                exportedFileURL = url
                exportCompleted = true
                isExporting = false
            }

        } catch {
            await MainActor.run {
                exportError = error.localizedDescription
                isExporting = false
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
