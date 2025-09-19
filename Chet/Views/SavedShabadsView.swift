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
                createFolder(newFolderName, folders: rootFolders, modelContext: modelContext)
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
                createFolder(newFolderName, parentFolder: folder, folders: folder.subfolders, modelContext: modelContext)
                newFolderName = ""
            }
        } message: {
            Text("Enter a name for the new folder")
        }
        .onAppear {
            print("Folder name: \(folder.name)")
            for (i, f) in folder.subfolders.enumerated() {
                print("        Folder #\(i): \(f.name)")
            }
        }
    }
}

struct FoldersDisplay: View {
    let foldersList: [Folder] // ✅ plain array, not Binding
    @Environment(\.modelContext) private var modelContext

    @State private var folderNotEmpty: Folder?
    @State private var showNotEmptyAlert = false

    var body: some View {
        Section("Subfolders (\(foldersList.count))") {
            ForEach(foldersList.sorted(by: { $0.sortIndex < $1.sortIndex })) { sub in
                NavigationLink(destination: FoldersContentView(folder: sub)) {
                    Label(sub.name, systemImage: "folder")
                }
            }
            .onMove { indices, newOffset in
                moveItems(indices, newOffset)
            }
            .onDelete { indices in
                handleDelete(at: indices)
            }
        }
        .alert("Folder Not Empty", isPresented: $showNotEmptyAlert, presenting: folderNotEmpty) { _ in
            Button("OK", role: .cancel) {}
        } message: { folder in
            Text("Folder \(folder.name) is not empty and cannot be deleted.")
        }
    }

    private func handleDelete(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        let folder = foldersList[index]

        if folder.savedShabads.isEmpty && folder.subfolders.isEmpty {
            // Folder is empty, safe to delete
            modelContext.delete(folder)
        } else {
            // folderNotEmpty = folder
            // showNotEmptyAlert = true
            modelContext.delete(folder)
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
}

struct ShabadsDisplay: View {
    let folder: Folder
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Section("Shabads (\(folder.savedShabads.count))") {
            ForEach(folder.savedShabads.sorted(by: { $0.addedAt < $1.addedAt })) { svdSbd in
                NavigationLink(destination: ShabadViewDisplayWrapper(sbdRes: svdSbd.sbdRes, indexOfLine: svdSbd.indexOfSelectedLine)) {
                    RowView(sbdRes: svdSbd.sbdRes, indexOfLine: svdSbd.indexOfSelectedLine, the_date: svdSbd.addedAt)
                }
            }
            .onMove { indices, newOffset in
                moveItems(&folder.savedShabads, indices, newOffset)
            }
            .onDelete { indices in
                handleDelete(at: indices)
            }
        }
    }

    private func handleDelete(at offsets: IndexSet) {
        for index in offsets {
            let savedShabad = folder.savedShabads[index]
            modelContext.delete(savedShabad)
        }
        try? modelContext.save()
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

private func createFolder(_ rawName: String, parentFolder: Folder? = nil, folders: [Folder], modelContext: ModelContext) {
    let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty else { return }

    // compute next sortIndex
    let maxIndex = folders.map(\.sortIndex).max() ?? -1
    let newFolder = Folder(name: name, parentFolder: parentFolder, sortIndex: maxIndex + 1)
    if let parentFolder = parentFolder {
        parentFolder.subfolders.append(newFolder)
    }
    modelContext.insert(newFolder)
    try? modelContext.save()
}
