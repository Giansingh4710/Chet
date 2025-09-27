import SwiftData
import SwiftUI

struct SavedShabadsView: View {
    @Query(
        filter: #Predicate<Folder> { $0.parentFolder == nil }, // only top-level
        sort: \.sortIndex
    ) private var rootFolders: [Folder]

    @Environment(\.editMode) var editMode // Access the environment's edit mode
    // @State private var editMode: EditMode = .inactive

    // UI state for new-folder sheet
    @State private var showingNewFolderAlert = false
    @State private var newFolderName: String = ""

    @State private var showingImporter = false
    @State private var showingImportInfoAlert = false
    @State private var numberOfImportedShabads = -1

    @State private var isMovingItems = false // New state to enter move selection mode
    @State private var selectedFolders: Set<Folder> = []

    @Environment(\.modelContext) private var modelContext
    @State private var showingDestinationPickerSheet = false

    var body: some View {
        ZStack {
            VStack {
                if rootFolders.isEmpty {
                    Text("No folders yet")
                } else {
                    List {
                        FoldersDisplay(
                            parentFolder: nil, // This is the crucial change
                            selectedFolders: $selectedFolders
                        )
                    }
                    // .environment(\.editMode, $editMode) // 👈 must wrap the List
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
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showingImportInfoAlert = true }) {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    EditButton()
                    if editMode?.wrappedValue.isEditing == true {
                        Button("Move") {
                            showingDestinationPickerSheet = true
                        }
                        .disabled(selectedFolders.isEmpty)
                    } else {}

                    Button(action: { showingNewFolderAlert = true }) {
                        Label("Add Folder", systemImage: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingDestinationPickerSheet) {
            DestinationFolderSelectionView(
                onSelect: { selectedF in
                    performBulkMoveOfFolders(to: selectedF)
                    showingDestinationPickerSheet = false

                },
                // Prevent selecting the current folder itself as a destination
                disabledFolderIDs: selectedFolders.map(\.id) // Pass IDs of folders being moved
                // rootFolders: rootFolders
            )
        }
        .onChange(of: editMode?.wrappedValue) { newValue in
            // When exiting edit mode, clear selections
            if newValue == .inactive {
                selectedFolders.removeAll()
            }
        }
        .alert("New Folder", isPresented: $showingNewFolderAlert) {
            TextField("Folder name", text: $newFolderName)
            Button("Cancel", role: .cancel) {
                newFolderName = ""
            }
            Button("Create") {
                createFolder(newFolderName, modelContext: modelContext)
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

    private func performBulkMoveOfFolders(to destination: Folder?) {
        for selectedFolder in selectedFolders {
            selectedFolder.parentFolder = destination
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to save bulk move: \(error.localizedDescription)")
        }

        selectedFolders.removeAll()
        editMode?.wrappedValue = .inactive
    }
}

struct FoldersContentView: View {
    let folder: Folder

    @State private var showingNewFolderAlert = false
    @State private var newFolderName: String = ""
    @FocusState private var nameFieldFocused: Bool

    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) var editMode // Access the environment's edit mode

    // MARK: - State for Bulk Move

    @State private var selectedFolders: Set<Folder> = []
    @State private var selectedShabads: Set<SavedShabad> = []
    @State private var showingDestinationPickerSheet = false

    var body: some View {
        List {
            FoldersDisplay(
                parentFolder: folder,
                selectedFolders: $selectedFolders
            )
            ShabadsDisplay(
                folder: folder,
                // Pass bindings for selection when in edit mode
                selectedShabads: $selectedShabads
            )
        }
        .navigationTitle(folder.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    EditButton() // This manages the environment's editMode
                    // "Move" button only appears when in edit mode AND items are selected
                    if editMode?.wrappedValue.isEditing == true {
                        Button("Move") {
                            showingDestinationPickerSheet = true
                        }
                        .disabled(selectedFolders.isEmpty && selectedShabads.isEmpty)
                    }

                    // Always show "Add Folder" button
                    Button(action: { showingNewFolderAlert = true }) {
                        Label("Add Folder", systemImage: "plus")
                    }
                }
            }
        }
        .alert("New Folder", isPresented: $showingNewFolderAlert) {
            TextField("Folder name", text: $newFolderName)
            Button("Cancel", role: .cancel) {
                newFolderName = ""
            }
            Button("Create") {
                createFolder(newFolderName, parentFolder: folder, modelContext: modelContext)
                newFolderName = ""
            }
        } message: {
            Text("Enter a name for the new folder")
        }
        .sheet(isPresented: $showingDestinationPickerSheet) {
            DestinationFolderSelectionView(
                onSelect: { selectedF in
                    performBulkMove(to: selectedF)
                    showingDestinationPickerSheet = false

                },
                // Prevent selecting the current folder itself as a destination
                disabledFolderIDs: selectedFolders.map(\.id) // Pass IDs of folders being moved
                // rootFolders: rootFolders
            )
        }
        .onChange(of: editMode?.wrappedValue) { newValue in
            // When exiting edit mode, clear selections
            if newValue == .inactive {
                selectedFolders.removeAll()
                selectedShabads.removeAll()
            }
        }
        .onAppear {
            print("Folder name: \(folder.name)")
            for (i, f) in folder.subfolders.enumerated() {
                print("        Folder #\(i): \(f.name)")
            }
        }
    }

    private func performBulkMove(to destination: Folder?) {
        for selectedFolder in selectedFolders {
            selectedFolder.parentFolder = destination
        }

        for selectedShabad in selectedShabads {
            if let destination = destination {
                selectedShabad.folder = destination
            }
        }

        do {
            try modelContext.save()
            print("Bulk move successful.")
        } catch {
            print("Failed to save bulk move: \(error.localizedDescription)")
        }

        selectedFolders.removeAll()
        selectedShabads.removeAll()
        editMode?.wrappedValue = .inactive
    }
}

struct FoldersDisplay: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) var editMode

    let parentFolder: Folder? // Make parentFolder optional for root view
    @Binding var selectedFolders: Set<Folder>

    @Query var subfolders: [Folder] // Now `subfolders` will hold either root or children

    init(parentFolder: Folder?, selectedFolders: Binding<Set<Folder>>) {
        self.parentFolder = parentFolder
        _selectedFolders = selectedFolders

        // Construct the Predicate using the ID of the parent folder
        let predicate: Predicate<Folder>
        if let parentFolderID = parentFolder?.id { // Get the ID, which is a non-optional UUID
            // Query for folders whose parentFolder's ID matches parentFolderID
            predicate = #Predicate<Folder> { folder in
                folder.parentFolder?.id == parentFolderID
            }
        } else {
            // Query for top-level folders (parentFolder is nil)
            predicate = #Predicate<Folder> { folder in
                folder.parentFolder == nil
            }
        }

        _subfolders = Query(filter: predicate, sort: [SortDescriptor(\.sortIndex)])
    }

    var body: some View {
        Section("Subfolders (\(subfolders.count))") {
            ForEach(subfolders) { sub in
                HStack {
                    if editMode?.wrappedValue.isEditing == true {
                        Image(systemName: selectedFolders.contains(sub) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(.accentColor)
                            .onTapGesture {
                                if selectedFolders.contains(sub) {
                                    selectedFolders.remove(sub)
                                } else {
                                    selectedFolders.insert(sub)
                                }
                            }
                    }
                    NavigationLink(destination: FoldersContentView(folder: sub)) {
                        Label(sub.name, systemImage: "folder")
                    }
                }
            }
            .onMove(perform: moveItems)
            .onDelete(perform: handleDelete)
        }
    }

    private func handleDelete(at offsets: IndexSet) {
        for index in offsets {
            let folder = subfolders[index]
            modelContext.delete(folder)
        }
    }

    private func moveItems(_ indices: IndexSet, _ newOffset: Int) {
        var reordered = subfolders
        reordered.move(fromOffsets: indices, toOffset: newOffset)

        for (i, f) in reordered.enumerated() {
            f.sortIndex = i
        }
    }
}

struct ShabadsDisplay: View {
    let folder: Folder
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) var editMode // Access the environment's edit mode

    @Binding var selectedShabads: Set<SavedShabad> // Binding for selection

    var body: some View {
        Section("Shabads (\(folder.savedShabads.count))") {
            ForEach(folder.savedShabads.sorted(by: { $0.sortIndex < $1.sortIndex })) { svdSbd in // Sort by sortIndex
                HStack {
                    if editMode?.wrappedValue.isEditing == true {
                        // Checkbox for selection in edit mode
                        Image(systemName: selectedShabads.contains(svdSbd) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(.accentColor)
                            .onTapGesture {
                                if selectedShabads.contains(svdSbd) {
                                    selectedShabads.remove(svdSbd)
                                } else {
                                    selectedShabads.insert(svdSbd)
                                }
                            }
                    }
                    NavigationLink(destination: ShabadViewDisplayWrapper(sbdRes: svdSbd.sbdRes, indexOfLine: svdSbd.indexOfSelectedLine)) {
                        RowView(sbdRes: svdSbd.sbdRes, indexOfLine: svdSbd.indexOfSelectedLine, the_date: svdSbd.addedAt)
                    }
                }
                .contentShape(Rectangle()) // Make HStack tappable for selection
            }
            .onMove(perform: moveItems)
            .onDelete(perform: handleDelete)
        }
    }

    private func handleDelete(at offsets: IndexSet) {
        let sortedShabads = folder.savedShabads.sorted(by: { $0.sortIndex < $1.sortIndex }) // Sort by sortIndex
        for index in offsets {
            let savedShabad = sortedShabads[index]
            modelContext.delete(savedShabad)
        }
    }

    private func moveItems(_ indices: IndexSet, _ newOffset: Int) {
        var reorderedShabads = folder.savedShabads.sorted(by: { $0.sortIndex < $1.sortIndex })
        reorderedShabads.move(fromOffsets: indices, toOffset: newOffset)

        for (i, s) in reorderedShabads.enumerated() {
            s.sortIndex = i // Update the sortIndex property
        }
    }
}

private func createFolder(_ rawName: String, parentFolder: Folder? = nil, modelContext: ModelContext) {
    let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty else { return }

    // compute next sortIndex
    let newFolder = Folder(name: name, parentFolder: parentFolder)
    if let parentFolder = parentFolder {
        parentFolder.subfolders.append(newFolder)
    }
    modelContext.insert(newFolder)
    try? modelContext.save()
}

struct DestinationFolderSelectionView: View {
    @Environment(\.dismiss) var dismiss

    @State private var selectedFolderID: UUID? = nil
    @State private var selectedFolder: Folder? = nil
    @State private var isRootSelected = false // 👈 new flag

    let onSelect: (Folder?) -> Void
    let disabledFolderIDs: [UUID]

    @Query(filter: #Predicate<Folder> { $0.parentFolder == nil },
           sort: [SortDescriptor(\.sortIndex)])
    private var rootFolders: [Folder]

    var body: some View {
        NavigationStack {
            List {
                Button {
                    isRootSelected = true
                    selectedFolder = nil
                    selectedFolderID = nil
                } label: {
                    HStack {
                        Label("Move to Root", systemImage: "rectangle.3.offgrid")
                        Spacer()
                        if isRootSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                }

                // Existing folders
                OutlineGroup(rootFolders, id: \.id, children: \.subfoldersOrNil) { folder in
                    Button(action: {
                        guard !disabledFolderIDs.contains(folder.id) else { return }
                        isRootSelected = false
                        selectedFolderID = folder.id
                        selectedFolder = folder
                    }) {
                        HStack {
                            // Folder open/closed
                            Image(systemName: "folder.fill")
                                .foregroundColor(.accentColor)

                            // Name
                            Text(folder.name)
                                .strikethrough(isDisabled(folder))
                                .foregroundColor(isDisabled(folder) ? .gray : .primary)

                            Spacer()

                            // Radio-style checkmark
                            if selectedFolderID == folder.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .disabled(isDisabled(folder))
                }
            }

            .listStyle(.sidebar)
            .navigationTitle("Select Destination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Move") {
                        onSelect(selectedFolder)
                        dismiss()
                    }
                    .disabled(!isRootSelected && selectedFolder == nil) // 👈 works now
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        // showingDestinationPickerSheet = false
                        dismiss()
                    }
                }
            }
        }
    }

    private func isDisabled(_ folder: Folder) -> Bool {
        if disabledFolderIDs.contains(folder.id) {
            return true
        }
        // Walk up the tree: if any ancestor is disabled, disable this too
        var current = folder.parentFolder
        while let parent = current {
            if disabledFolderIDs.contains(parent.id) {
                return true
            }
            current = parent.parentFolder
        }
        return false
    }

    private func findFolder(in folders: [Folder], id: UUID) -> Folder? {
        for folder in folders {
            if folder.id == id {
                return folder
            }
            if let sub = folder.subfoldersOrNil,
               let found = findFolder(in: sub, id: id)
            {
                return found
            }
        }
        return nil
    }
}
