import SwiftData
import SwiftUI
import WidgetKit

struct SavedShabadsView: View {
    @Query(
        filter: #Predicate<Folder> { $0.parentFolder == nil }, // only top-level
        sort: \.sortIndex
    ) private var rootFolders: [Folder]

    @Environment(\.editMode) var editMode // Access the environment's edit mode
    // @State private var editMode: EditMode = .inactive

    // UI state for new-folder sheet
    @State private var showingErrorAlert = false
    @State private var errorMessage: String = ""

    @State private var showingNewFolderAlert = false
    @State private var newFolderName: String = ""

    @State private var showingImporter = false
    @State private var showingImportInfoAlert = false
    @State private var numberOfImportedShabads = -1

    @State private var showingExporter = false

    @State private var isMovingItems = false // New state to enter move selection mode
    @State private var selectedFolders: Set<Folder> = []
    @State private var isCopyOperation = false // Track if we're copying vs moving

    @Environment(\.modelContext) private var modelContext
    @AppStorage("backupChangeCounter") private var backupChangeCounter = 0
    @State private var showingDestinationPickerSheet = false

    var body: some View {
        ZStack {
            VStack {
                if rootFolders.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "folder")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text("No Folders")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Tap + to create a folder")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: .infinity)
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
        .navigationTitle(editMode?.wrappedValue.isEditing == true && !selectedFolders.isEmpty
            ? "Selected (\(selectedFolders.count))"
            : "Saved Shabads")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    Button(action: { showingImportInfoAlert = true }) {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                    Button(action: { showingExporter = true }) {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    if editMode?.wrappedValue.isEditing == true {
                        Button(action: selectAllFolders) {
                            Image(systemName: selectedFolders.count == rootFolders.count ? "checklist.unchecked" : "checklist")
                                .font(.system(size: 18))
                        }

                        Menu {
                            Button {
                                isCopyOperation = false
                                showingDestinationPickerSheet = true
                            } label: {
                                Label("Move", systemImage: "arrow.right")
                            }
                            Button {
                                isCopyOperation = true
                                showingDestinationPickerSheet = true
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 18))
                        }
                        .disabled(selectedFolders.isEmpty)
                    }

                    Button(action: { showingNewFolderAlert = true }) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 18))
                    }

                    EditButton()
                }
            }
        }
        .sheet(isPresented: $showingDestinationPickerSheet) {
            DestinationFolderSelectionView(
                onSelect: { selectedF in
                    if isCopyOperation {
                        performBulkCopyOfFolders(to: selectedF)
                    } else {
                        performBulkMoveOfFolders(to: selectedF)
                    }
                    showingDestinationPickerSheet = false
                },
                // Prevent selecting the current folder itself as a destination (only for move)
                disabledFolderIDs: isCopyOperation ? [] : selectedFolders.map(\.id),
                operationType: isCopyOperation ? "Copy" : "Move"
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
                if newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    errorMessage = "Folder name cannot be empty."
                    showingErrorAlert = true
                    return
                }
                if rootFolders.contains(where: { $0.name == "Favorites" }) && newFolderName == "Favorites" {
                    errorMessage = "Cannot create a folder named 'Favorites'."
                    showingErrorAlert = true
                    return
                }

                createFolder(newFolderName, modelContext: modelContext)
                newFolderName = ""
            }
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Import Shabads", isPresented: $showingImportInfoAlert) {
            Button("Continue") {
                showingImporter = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("ਗੁਰਬਾਣੀ ਖੋਜ (Gurbani Khoj) and iGurbani allow you to export your favorite Shabads. When you export them, it will be saved to a file. You can import that file here and get all your saved data here.")
        }
        .sheet(isPresented: $showingExporter) {
            ExportSheet()
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.igb, .gkhoj, .chetBackup], // ✅ allow all three import formats
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
                } else if fileExtension == "chet" {
                    // Restore from Chet backup
                    Task {
                        do {
                            numberOfImportedShabads = 0
                            try await BackupManager.shared.restoreFromJSON(
                                data: data,
                                modelContext: modelContext
                            ) { count in
                                numberOfImportedShabads = count
                            }
                            numberOfImportedShabads = -1
                        } catch {
                            print("Failed to restore backup: \(error.localizedDescription)")
                            errorMessage = "Failed to restore backup: \(error.localizedDescription)"
                            showingErrorAlert = true
                            numberOfImportedShabads = -1
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

    private func selectAllFolders() {
        if selectedFolders.count == rootFolders.count {
            // Deselect all
            selectedFolders.removeAll()
        } else {
            // Select all
            selectedFolders = Set(rootFolders)
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

        // Reload widget if moving folders to Favorites (might contain shabads)
        if let destination = destination, destination.name == "Favorites" && destination.isSystemFolder {
            WidgetCenter.shared.reloadTimelines(ofKind: "xyz.gians.Chet.FavShabadsWidget")
        }

        selectedFolders.removeAll()
        editMode?.wrappedValue = .inactive
    }

    private func performBulkCopyOfFolders(to destination: Folder?) {
        for selectedFolder in selectedFolders {
            copyFolderRecursively(selectedFolder, to: destination)
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to save bulk copy: \(error.localizedDescription)")
        }

        // Reload widget if copying folders to Favorites (might contain shabads)
        if let destination = destination, destination.name == "Favorites" && destination.isSystemFolder {
            WidgetCenter.shared.reloadTimelines(ofKind: "xyz.gians.Chet.FavShabadsWidget")
        }

        selectedFolders.removeAll()
        editMode?.wrappedValue = .inactive
    }

    private func copyFolderRecursively(_ folder: Folder, to destination: Folder?) {
        // Create a copy of the folder
        let copiedFolder = Folder(
            name: folder.name + " Copy",
            parentFolder: destination,
            subfolders: [],
            isSystemFolder: false,
            sortIndex: 0
        )
        modelContext.insert(copiedFolder)

        // Copy all shabads
        for shabad in folder.savedShabads {
            let copiedShabad = SavedShabad(
                folder: copiedFolder,
                sbdRes: shabad.sbdRes,
                indexOfSelectedLine: shabad.indexOfSelectedLine,
                addedAt: Date(),
                sortIndex: shabad.sortIndex
            )
            modelContext.insert(copiedShabad)
        }

        // Recursively copy subfolders
        for subfolder in folder.subfolders {
            copyFolderRecursively(subfolder, to: copiedFolder)
        }
    }
}

struct FoldersContentView: View {
    @Bindable var folder: Folder

    @State private var errorMessage = ""
    @State private var showingErrorAlert = false

    @State private var showingNewFolderAlert = false
    @State private var newFolderName: String = ""
    @FocusState private var nameFieldFocused: Bool

    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) var editMode // Access the environment's edit mode

    // MARK: - State for Bulk Move

    @State private var selectedFolders: Set<Folder> = []
    @State private var selectedShabads: Set<SavedShabad> = []
    @State private var showingDestinationPickerSheet = false
    @State private var isCopyOperation = false

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
        .navigationTitle({
            if editMode?.wrappedValue.isEditing == true {
                let totalSelected = selectedFolders.count + selectedShabads.count
                return totalSelected > 0 ? "Selected (\(totalSelected))" : folder.name
            }
            return folder.name
        }())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    if editMode?.wrappedValue.isEditing == true {
                        Button(action: selectAll) {
                            let totalItems = folder.subfolders.count + folder.savedShabads.count
                            let totalSelected = selectedFolders.count + selectedShabads.count
                            Image(systemName: totalSelected == totalItems ? "checklist.unchecked" : "checklist")
                                .font(.system(size: 18))
                        }

                        Menu {
                            Button {
                                isCopyOperation = false
                                showingDestinationPickerSheet = true
                            } label: {
                                Label("Move", systemImage: "arrow.right")
                            }
                            Button {
                                isCopyOperation = true
                                showingDestinationPickerSheet = true
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 18))
                        }
                        .disabled(selectedFolders.isEmpty && selectedShabads.isEmpty)
                    }

                    Button(action: { showingNewFolderAlert = true }) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 18))
                    }

                    EditButton()
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
                    if isCopyOperation {
                        performBulkCopy(to: selectedF)
                    } else {
                        performBulkMove(to: selectedF)
                    }
                    showingDestinationPickerSheet = false
                },
                // Prevent selecting the current folder itself as a destination (only for move)
                disabledFolderIDs: isCopyOperation ? [] : selectedFolders.map(\.id),
                operationType: isCopyOperation ? "Copy" : "Move"
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

    private func selectAll() {
        let totalItems = folder.subfolders.count + folder.savedShabads.count
        let totalSelected = selectedFolders.count + selectedShabads.count

        if totalSelected == totalItems {
            // Deselect all
            selectedFolders.removeAll()
            selectedShabads.removeAll()
        } else {
            // Select all
            selectedFolders = Set(folder.subfolders)
            selectedShabads = Set(folder.savedShabads)
        }
    }

    private func performBulkMove(to destination: Folder?) {
        for selectedFolder in selectedFolders {
            selectedFolder.parentFolder = destination
        }

        // Track if any shabads are being moved to/from Favorites
        var shouldReloadWidget = false

        for selectedShabad in selectedShabads {
            // Check if moving FROM Favorites
            if selectedShabad.folder?.name == "Favorites" && selectedShabad.folder?.isSystemFolder == true {
                shouldReloadWidget = true
            }

            if let destination = destination {
                selectedShabad.folder = destination
                // Check if moving TO Favorites
                if destination.name == "Favorites" && destination.isSystemFolder {
                    shouldReloadWidget = true
                }
            }
        }

        do {
            try modelContext.save()
            print("Bulk move successful.")
        } catch {
            print("Failed to save bulk move: \(error.localizedDescription)")
        }

        // Reload widget if any shabads moved to/from Favorites folder
        if shouldReloadWidget {
            WidgetCenter.shared.reloadTimelines(ofKind: "xyz.gians.Chet.FavShabadsWidget")
        }

        selectedFolders.removeAll()
        selectedShabads.removeAll()
        editMode?.wrappedValue = .inactive
    }

    private func performBulkCopy(to destination: Folder?) {
        // Copy folders
        for selectedFolder in selectedFolders {
            copyFolderRecursively(selectedFolder, to: destination)
        }

        // Copy shabads
        for selectedShabad in selectedShabads {
            if let destination = destination {
                let copiedShabad = SavedShabad(
                    folder: destination,
                    sbdRes: selectedShabad.sbdRes,
                    indexOfSelectedLine: selectedShabad.indexOfSelectedLine,
                    addedAt: Date(),
                    sortIndex: selectedShabad.sortIndex
                )
                modelContext.insert(copiedShabad)
            }
        }

        do {
            try modelContext.save()
            print("Bulk copy successful.")
        } catch {
            print("Failed to save bulk copy: \(error.localizedDescription)")
        }

        // Reload widget if copying to Favorites folder
        if let destination = destination, destination.name == "Favorites" && destination.isSystemFolder {
            WidgetCenter.shared.reloadTimelines(ofKind: "xyz.gians.Chet.FavShabadsWidget")
        }

        selectedFolders.removeAll()
        selectedShabads.removeAll()
        editMode?.wrappedValue = .inactive
    }

    private func copyFolderRecursively(_ folder: Folder, to destination: Folder?) {
        // Create a copy of the folder
        let copiedFolder = Folder(
            name: folder.name + " Copy",
            parentFolder: destination,
            subfolders: [],
            isSystemFolder: false,
            sortIndex: 0
        )
        modelContext.insert(copiedFolder)

        // Copy all shabads
        for shabad in folder.savedShabads {
            let copiedShabad = SavedShabad(
                folder: copiedFolder,
                sbdRes: shabad.sbdRes,
                indexOfSelectedLine: shabad.indexOfSelectedLine,
                addedAt: Date(),
                sortIndex: shabad.sortIndex
            )
            modelContext.insert(copiedShabad)
        }

        // Recursively copy subfolders
        for subfolder in folder.subfolders {
            copyFolderRecursively(subfolder, to: copiedFolder)
        }
    }
}

struct FoldersDisplay: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) var editMode

    let parentFolder: Folder?
    @Binding var selectedFolders: Set<Folder>

    @Query var subfolders: [Folder]

    @State private var editingFolder: Folder? // folder being renamed
    @State private var newName: String = "" // temporary name during rename

    @State private var showingErrorAlert = false
    @State private var errorMessage: String = ""

    // Widget folder selection
    @AppStorage("favShabadsWidgetFolderID", store: UserDefaults.appGroup) private var widgetFolderID: String = ""
    @AppStorage("favShabadsWidgetFolderName", store: UserDefaults.appGroup) private var widgetFolderName: String = ""
    @State private var showingWidgetInfoAlert = false
    init(parentFolder: Folder?, selectedFolders: Binding<Set<Folder>>) {
        self.parentFolder = parentFolder
        _selectedFolders = selectedFolders

        let predicate: Predicate<Folder>
        if let parentFolderID = parentFolder?.id {
            predicate = #Predicate<Folder> { folder in
                folder.parentFolder?.id == parentFolderID
            }
        } else {
            predicate = #Predicate<Folder> { folder in
                folder.parentFolder == nil
            }
        }

        _subfolders = Query(filter: predicate, sort: [SortDescriptor(\.sortIndex)])
    }

    var body: some View {
        Section(parentFolder == nil ? "Folders (\(subfolders.count))" : "Subfolders (\(subfolders.count))") {
            ForEach(subfolders) { sub in
                if editMode?.wrappedValue.isEditing == true {
                    // In edit mode: make entire row tappable for selection
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            toggleSelection(for: sub)
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: selectedFolders.contains(sub) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedFolders.contains(sub) ? .accentColor : .secondary)
                                .font(.system(size: 22))

                            Label(sub.name, systemImage: "folder")
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                        .padding(.vertical, 4)
                        .background(
                            selectedFolders.contains(sub)
                                ? Color.accentColor.opacity(0.08)
                                : Color.clear
                        )
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    // Not in edit mode: normal navigation link
                    NavigationLink(destination: FoldersContentView(folder: sub)) {
                        HStack(spacing: 8) {
                            Label(sub.name, systemImage: "folder")

                            Spacer()

                            // Widget indicator - tappable info button (before the chevron)
                            if widgetFolderID == sub.id.uuidString {
                                Button(action: {
                                    showingWidgetInfoAlert = true
                                }) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.accentColor)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .contextMenu {
                        if widgetFolderID == sub.id.uuidString {
                            Button(role: .destructive) {
                                // Remove widget folder selection
                                widgetFolderID = ""
                                widgetFolderName = ""
                                WidgetCenter.shared.reloadTimelines(ofKind: "FavShabadsWidget")
                            } label: {
                                Label("Remove from Widget", systemImage: "rectangle.on.rectangle.slash")
                            }
                        } else {
                            Button {
                                // Set this folder as the widget folder
                                widgetFolderID = sub.id.uuidString
                                widgetFolderName = sub.name
                                WidgetCenter.shared.reloadTimelines(ofKind: "FavShabadsWidget")
                            } label: {
                                Label("Use for Widget", systemImage: "rectangle.on.rectangle")
                            }
                        }
                    }
                }

                if editMode?.wrappedValue.isEditing != true {
                    EmptyView()
                        .swipeActions(edge: .leading) {
                            Button("Rename") {
                                editingFolder = sub
                                newName = sub.name
                            }
                            .tint(.blue)
                        }
                }
            }
            .onMove(perform: moveItems)
            .onDelete(perform: handleDelete)
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Rename Folder", isPresented: Binding(
            get: { editingFolder != nil },
            set: { if !$0 { editingFolder = nil } }
        )) {
            TextField("Folder Name", text: $newName)
            Button("Cancel", role: .cancel) {
                editingFolder = nil
            }
            Button("Save") {
                if let folder = editingFolder {
                    folder.name = newName
                }
                editingFolder = nil
            }
        }
        .alert("Widget Folder", isPresented: $showingWidgetInfoAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This folder is currently used by the Favorites Shabad Widget.\n\nThe widget will rotate through shabads in this folder.\n\nTo change the widget folder:\n• Long-press on this folder and select \"Remove from Widget\"\n• Then long-press on another folder and select \"Use for Widget\"")
        }
    }

    private func toggleSelection(for folder: Folder) {
        if selectedFolders.contains(folder) {
            selectedFolders.remove(folder)
        } else {
            selectedFolders.insert(folder)
        }
    }

    private func handleDelete(at offsets: IndexSet) {
        for index in offsets {
            let folder = subfolders[index]
            if folder.isSystemFolder {
                errorMessage = "This Folder cannot be deleted."
                showingErrorAlert = true
                return
            }
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
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) var editMode // Access the environment's edit mode

    let folder: Folder
    @Binding var selectedShabads: Set<SavedShabad> // Binding for selection

    @Query var the_shabads: [SavedShabad]

    init(folder: Folder, selectedShabads: Binding<Set<SavedShabad>>) {
        self.folder = folder
        _selectedShabads = selectedShabads

        let folderID = folder.id // capture the value first

        _the_shabads = Query(
            filter: #Predicate<SavedShabad> { sbd in
                sbd.folder?.id == folderID
            },
            sort: [SortDescriptor(\.sortIndex, order: .reverse)]
        )
    }

    var body: some View {
        Section("Shabads (\(folder.savedShabads.count))") {
            ForEach(the_shabads) { svdSbd in
                if editMode?.wrappedValue.isEditing == true {
                    // In edit mode: make entire row tappable for selection
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if selectedShabads.contains(svdSbd) {
                                selectedShabads.remove(svdSbd)
                            } else {
                                selectedShabads.insert(svdSbd)
                            }
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: selectedShabads.contains(svdSbd) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedShabads.contains(svdSbd) ? .accentColor : .secondary)
                                .font(.system(size: 22))

                            RowView(
                                verse: svdSbd.sbdRes.verses[svdSbd.indexOfSelectedLine < 0 ? 0 : svdSbd.indexOfSelectedLine],
                                source: svdSbd.sbdRes.shabadInfo.source,
                                writer: svdSbd.sbdRes.shabadInfo.writer,
                                raag: svdSbd.sbdRes.shabadInfo.raag,
                                pageNo: svdSbd.sbdRes.shabadInfo.pageNo,
                                the_date: svdSbd.addedAt,
                                searchQuery: "",
                                allVerses: svdSbd.sbdRes.verses
                            )

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                        .padding(.vertical, 4)
                        .background(
                            selectedShabads.contains(svdSbd)
                                ? Color.accentColor.opacity(0.08)
                                : Color.clear
                        )
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    // Not in edit mode: normal navigation link
                    NavigationLink(destination: ShabadViewDisplayWrapper(sbdRes: svdSbd.sbdRes, indexOfLine: svdSbd.indexOfSelectedLine, onIndexChange: { newIndex in
                        svdSbd.indexOfSelectedLine = newIndex
                        WidgetCenter.shared.reloadAllTimelines()
                    })) {
                        RowView(
                            verse: svdSbd.sbdRes.verses[svdSbd.indexOfSelectedLine < 0 ? 0 : svdSbd.indexOfSelectedLine],
                            source: svdSbd.sbdRes.shabadInfo.source,
                            writer: svdSbd.sbdRes.shabadInfo.writer,
                            raag: svdSbd.sbdRes.shabadInfo.raag,
                            pageNo: svdSbd.sbdRes.shabadInfo.pageNo,
                            the_date: svdSbd.addedAt,
                            searchQuery: "",
                            allVerses: svdSbd.sbdRes.verses
                        )
                    }
                }
            }
            .onMove(perform: moveItems)
            .onDelete(perform: handleDelete)
        }
    }

    private func getSortedShabads() -> [SavedShabad] {
        return folder.savedShabads.sorted(by: { $0.sortIndex > $1.sortIndex }) // Sort by sortIndex
    }

    private func handleDelete(at offsets: IndexSet) {
        var current = the_shabads.sorted(by: { $0.sortIndex > $1.sortIndex })
        for index in offsets {
            let shabadToDelete = current[index]
            modelContext.delete(shabadToDelete)
        }
        current.remove(atOffsets: offsets)
        for (i, s) in current.enumerated() {
            s.sortIndex = current.count - i
        }

        // Reload FavShabadsWidget if deleting from Favorites folder
        if folder.name == "Favorites" && folder.isSystemFolder {
            WidgetCenter.shared.reloadTimelines(ofKind: "xyz.gians.Chet.FavShabadsWidget")
        }
    }

    private func moveItems(_ indices: IndexSet, _ newOffset: Int) {
        var reordered = the_shabads
        reordered.move(fromOffsets: indices, toOffset: newOffset)

        for (i, s) in reordered.reversed().enumerated() {
            s.sortIndex = i
        }

        // Reload FavShabadsWidget if reordering in Favorites folder (order matters for rotation!)
        if folder.name == "Favorites" && folder.isSystemFolder {
            WidgetCenter.shared.reloadTimelines(ofKind: "xyz.gians.Chet.FavShabadsWidget")
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
    let operationType: String

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
            .navigationTitle("\(operationType) to...")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(operationType) {
                        onSelect(selectedFolder)
                        dismiss()
                    }
                    .disabled(!isRootSelected && selectedFolder == nil)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
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
