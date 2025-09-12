import SwiftData
import SwiftUI

struct SavedShabadsView: View {
    @Query(
        filter: #Predicate<Folder> { $0.parentFolder == nil }, // only top-level
        sort: \.sortIndex
    ) private var rootFolders: [Folder]

    // UI state for new-folder sheet
    @State private var showingNewFolderAlert = false
    @State private var newFolderName: String = ""

    @State private var showingImporter = false
    @State private var showingImportInfoAlert = false
    @State private var numberOfImportedShabads = -1

    @Environment(\.modelContext) private var modelContext
    var body: some View {
        ZStack {
            VStack {
                if rootFolders.isEmpty {
                    Text("No folders yet")
                } else {
                    List {
                        FoldersDisplay(foldersList: rootFolders)
                    }
                }
            }
            // ✅ Popup overlay
            if numberOfImportedShabads >= 0 {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)

                    Text("Importing Shabads…")
                        .font(.headline)

                    Text("\(numberOfImportedShabads)")
                        .font(.title)
                        .bold()
                }
                .padding()
                .frame(maxWidth: 250)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .shadow(radius: 10)
                .transition(.scale.combined(with: .opacity))
                .zIndex(1)
            }
        }
        .animation(.easeInOut, value: numberOfImportedShabads)
        .navigationTitle("Saved Shabads")
        .toolbar {
            Button(action: { showingImportInfoAlert = true }) {
                Label("Import", systemImage: "square.and.arrow.down")
            }
            Button(action: { showingNewFolderAlert = true }) {
                Label("Add Folder", systemImage: "plus")
            }
        }
        .alert("New Folder", isPresented: $showingNewFolderAlert) {
            TextField("Folder name", text: $newFolderName)
            Button("Cancel", role: .cancel) {
                newFolderName = ""
            }
            Button("Create") {
                createFolder(named: newFolderName)
                newFolderName = ""
            }
        } message: {
            Text("Enter a name for the new folder")
        }
        .alert("Import Shabads", isPresented: $showingImportInfoAlert) {
            Button("Continue") {
                showingImporter = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("ਗੁਰਬਾਣੀ ਖੋਜ (Gurbani Khoj) and iGurbani allow you to export your favorite Shabads. When you export them, it will be saved to a file. You can import that file here and get all your saved data here.")
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.igb, .gkhoj], // ✅ allow both custom extensions
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let selectedFile = try result.get().first else { return }
                // ✅ Start security-scoped access
                guard selectedFile.startAccessingSecurityScopedResource() else {
                    print("Couldn't access file")
                    return
                }
                defer { selectedFile.stopAccessingSecurityScopedResource() }
                let data = try Data(contentsOf: selectedFile)
                // if let text = String(data: data, encoding: .utf8) { print("Imported content:\n\(text)") }
                let fileExtension = selectedFile.pathExtension.lowercased()

                if fileExtension == "igb" {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        Task {
                            numberOfImportedShabads = 0
                            let iGurbaniFolder = await parseArrayForiGurbani(json, modelContext: modelContext) {
                                await MainActor.run { // This closure runs every time a shabad is imported
                                    numberOfImportedShabads += 1
                                }
                            }
                            numberOfImportedShabads = -1
                            modelContext.insert(iGurbaniFolder)
                            try? modelContext.save()
                        }
                    }
                } else if fileExtension == "gkhoj" {
                    let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
                    if let rootArray = plist as? [Any] {
                        Task {
                            numberOfImportedShabads = 0
                            let gkFolder = await parseArrayForGKImports(rootArray, modelContext: modelContext) {
                                await MainActor.run { // This closure runs every time a shabad is imported
                                    numberOfImportedShabads += 1
                                }
                            }
                            numberOfImportedShabads = -1
                            modelContext.insert(gkFolder)
                            try? modelContext.save()
                        }
                    }
                } else {
                    print("Unknown file type: \(fileExtension)")
                }

            } catch {
                print("Failed to import file: \(error.localizedDescription)")
            }
        }
    }

    private func createFolder(named rawName: String) {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        // compute next sortIndex
        let maxIndex = rootFolders.map(\.sortIndex).max() ?? -1
        let newFolder = Folder(name: name, sortIndex: maxIndex + 1)
        modelContext.insert(newFolder)
    }
}

struct FoldersContentView: View {
    let folder: Folder

    // UI state for new-folder sheet
    @State private var showingNewFolderAlert = false
    @State private var newFolderName: String = ""
    @FocusState private var nameFieldFocused: Bool

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            FoldersDisplay(foldersList: folder.subfolders)
            ShabadsDisplay(folder: folder)
        }
        .navigationTitle(folder.name)
        .toolbar {
            EditButton()
            Button(action: { showingNewFolderAlert = true }) {
                Label("Add Folder", systemImage: "plus")
            }
        }
        .alert("New Folder", isPresented: $showingNewFolderAlert) {
            TextField("Folder name", text: $newFolderName)
            Button("Cancel", role: .cancel) {
                newFolderName = ""
            }
            Button("Create") {
                createFolder(named: newFolderName)
                newFolderName = ""
            }
        } message: {
            Text("Enter a name for the new folder")
        }
    }

    private func createFolder(named rawName: String) {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        let maxIndex = folder.subfolders.map(\.sortIndex).max() ?? -1
        let newFolder = Folder(name: name, parentFolder: folder, sortIndex: maxIndex + 1)
        folder.subfolders.append(newFolder)
        try? modelContext.save()
    }
}

struct FoldersDisplay: View {
    let foldersList: [Folder] // ✅ plain array, not Binding
    @Environment(\.modelContext) private var modelContext


    var body: some View {
        Section("Subfolders") {
            ForEach(foldersList.sorted(by: { $0.sortIndex < $1.sortIndex })) { sub in
                NavigationLink(destination: FoldersContentView(folder: sub)) {
                    Label(sub.name, systemImage: "folder")
                }
            }
            .onMove { indices, newOffset in
                moveItems(indices, newOffset)
            }
            .onDelete { indices in
                deleteFolders(at: indices)
            }
        }
    }

    private func moveItems(_ indices: IndexSet, _ newOffset: Int) {
        let moved = foldersList.sorted(by: { $0.sortIndex < $1.sortIndex })
        var reordered = moved
        reordered.move(fromOffsets: indices, toOffset: newOffset)

        for (i, f) in reordered.enumerated() {
            f.sortIndex = i // ✅ direct mutation, persists in SwiftData
        }
    }

    private func deleteFolders(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(foldersList[index])
        }
    }
}

struct ShabadsDisplay: View {
    let folder: Folder

    var body: some View {
        Section("Shabads") {
            ForEach(folder.savedShabads.sorted(by: { $0.addedAt < $1.addedAt })) { svdSbd in
                NavigationLink(destination: ShabadViewDisplayWrapper(sbdRes: svdSbd.sbdRes, indexOfLine: svdSbd.indexOfSelectedLine)) {
                    FavoriteShabadRowView(sbdRes: svdSbd.sbdRes, indexOfLine: svdSbd.indexOfSelectedLine, addedAt: svdSbd.addedAt)
                }
            }
            .onMove { indices, newOffset in
                moveItems(&folder.savedShabads, indices, newOffset)
            }
        }
    }

    private func moveItems<T>(_ items: inout [T], _ indices: IndexSet, _ newOffset: Int) {
        items.move(fromOffsets: indices, toOffset: newOffset)
        if let shabadItems = items as? [SavedShabad] {
            for (i, s) in shabadItems.enumerated() {
                s.indexOfSelectedLine = i
            }
        }
    }
}

struct FavoriteShabadRowView: View {
    let sbdRes: ShabadAPIResponse
    let indexOfLine: Int
    let addedAt: Date

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if sbdRes.shabad.indices.contains(indexOfLine) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sbdRes.shabad[indexOfLine].line.gurmukhi.unicode)
                        .font(.headline)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(sbdRes.shabad[indexOfLine].line.translation.english.default)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Text(addedAt, format: .dateTime.month(.abbreviated).day().year())
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.trailing, 12) // controls spacing from right edge
                    .offset(y: -12) // optional: lift it above
            }
            .frame(maxWidth: .infinity, alignment: .leading) // <-- key line
            .padding(.vertical, 6)
        } else {
            Text("⚠️ Shabad line not found")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
