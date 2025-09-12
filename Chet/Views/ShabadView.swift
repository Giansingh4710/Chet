import SwiftData
import SwiftUI

struct ShabadViewDisplayWrapper: View {
    let sbdRes: ShabadAPIResponse
    let indexOfLine: Int?
    @State var sbdRes2: ShabadAPIResponse?

    // @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var isLoadingShabad = false
    @State private var errorMessage: String?

    var body: some View {
        if isLoadingShabad {
            ProgressView("Loading Shabad…")
        } else if let errorMessage = errorMessage {
            Text(errorMessage).foregroundColor(.red)
        } else if let sbdRes2 = sbdRes2 {
            ShabadViewDisplay(sbdRes: sbdRes2, fetchNewShabad: fetchNewShabad, indexOfLine: indexOfLine)
        } else {
            ShabadViewDisplay(sbdRes: sbdRes, fetchNewShabad: fetchNewShabad, indexOfLine: indexOfLine)
        }
    }

    private func fetchNewShabad(_ sbdID: String) async {
        isLoadingShabad = true
        let urlString = "https://data.gurbaninow.com/v2/shabad/\(sbdID)"
        var aindexOfLine = 0
        guard let url = URL(string: urlString) else {
            await MainActor.run {
                errorMessage = "Invalid shabad URL"
                isLoadingShabad = false
            }
            return
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200 ... 299).contains(httpResponse.statusCode)
            else {
                throw URLError(.badServerResponse)
            }
            let decoded = try JSONDecoder().decode(ShabadAPIResponse.self, from: data)
            await MainActor.run {
                isLoadingShabad = false
                sbdRes2 = decoded
            }
        } catch {
            await MainActor.run {
                isLoadingShabad = false
                errorMessage = "Failed to fetch shabad: \(error.localizedDescription)"
            }
        }
    }
}

struct ShabadViewDisplay: View {
    let sbdRes: ShabadAPIResponse
    let fetchNewShabad: (String) async -> Void
    let indexOfLine: Int?
    @Environment(\.modelContext) private var modelContext

    @AppStorage("shabadTextScale") private var textScale: Double = 1.0
    @AppStorage("showTranslations") private var showTranslations: Bool = true
    @AppStorage("larivaar") private var larivaarOn: Bool = true
    @State private var gestureScale: CGFloat = 1.0

    @State private var showingSaveSheet = false

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // --- Meta Info Card ---
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label {
                                    Text("Ang \(sbdRes.shabadinfo.pageno)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                } icon: {
                                    Image(systemName: "book.closed")
                                }

                                Spacer()

                                Label {
                                    Text(sbdRes.shabadinfo.writer.english)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                } icon: {
                                    Image(systemName: "pencil")
                                }
                            }

                            Divider()

                            HStack(spacing: 20) {
                                Text("\(sbdRes.shabad.count) lines")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Shabad ID")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(sbdRes.shabadinfo.shabadid)
                                        .font(.callout)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                        .monospaced() // keeps IDs aligned
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                        )
                        .padding(.horizontal)

                        HStack(spacing: 8) {
                            Button(action: {
                                showingSaveSheet = true
                            }) {
                                Label("Save", systemImage: "bookmark")
                                    .labelStyle(.titleAndIcon)
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .tint(.accentColor)

                            Toggle(isOn: $showTranslations) {
                                Label("Translation", systemImage: "text.alignleft").font(.caption2)
                            }
                            .toggleStyle(.button)
                            .tint(.accentColor)

                            Toggle(isOn: $larivaarOn) {
                                Label("Larivaar", systemImage: "textformat").font(.caption)
                            }
                            .toggleStyle(.button)
                            .tint(.accentColor)
                        }
                        .padding(.horizontal)

                        // --- Shabad Lines ---
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(sbdRes.shabad, id: \.line.id) { shabadLine in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(getGurbaniLine(shabadLine))
                                        .font(.system(size: 20 * textScale * gestureScale))
                                        .fontWeight(.medium)
                                        .multilineTextAlignment(.leading)

                                    if showTranslations {
                                        Text(shabadLine.line.translation.english.default)
                                            .font(.system(size: 15 * textScale * gestureScale))
                                            .foregroundColor(.secondary)
                                            .lineSpacing(2)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    gestureScale = value
                                }
                                .onEnded { value in
                                    textScale *= value
                                    gestureScale = 1.0
                                }
                        )

                        // --- Next / Previous Navigation ---
                        HStack {
                            if let prevID = sbdRes.shabadinfo.navigation.previous?.id {
                                Button("◀︎ Previous") {
                                    Task {
                                        await fetchNewShabad(prevID)
                                    }
                                }
                            }
                            Spacer()
                            if let nextID = sbdRes.shabadinfo.navigation.next?.id {
                                Button("Next ▶︎") {
                                    Task {
                                        await fetchNewShabad(nextID)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingSaveSheet) {
            SaveToFolderSheet(sbdRes: sbdRes, indexOfLine: indexOfLine)
                .presentationDetents([.medium, .large])
        }
    }

    private func getGurbaniLine(_ shabadLine: ShabadLineWrapper) -> String {
        larivaarOn ? shabadLine.line.larivaar.unicode : shabadLine.line.gurmukhi.unicode
    }
}

struct SaveToFolderSheet: View {
    let sbdRes: ShabadAPIResponse
    let indexOfLine: Int?
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Folder> { $0.parentFolder == nil }, // only top-level
        sort: \.sortIndex
    ) private var rootFolders: [Folder]

    @State private var expanded: Set<Folder> = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(rootFolders) { folder in
                    FolderRow(
                        folder: folder,
                        sbdRes: sbdRes,
                        indexOfLine: indexOfLine,
                        expanded: $expanded
                    )
                }
            }
            .navigationTitle("Save to Folders")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {}
                }
            }
        }
    }
}

struct FolderRow: View {
    let folder: Folder
    let sbdRes: ShabadAPIResponse
    let indexOfLine: Int?
    @Binding var expanded: Set<Folder>

    @Environment(\.modelContext) private var modelContext
    @State private var isExpanded = false


    var body: some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { expanded.contains(folder) },
                set: { newValue in
                    if newValue {
                        expanded.insert(folder)
                    } else {
                        expanded.remove(folder)
                    }
                }
            )
        ) {
            if !folder.subfolders.isEmpty {
                ForEach(folder.subfolders) { sub in
                    FolderRow(
                        folder: folder,
                        sbdRes: sbdRes,
                        indexOfLine: indexOfLine,
                        expanded: $expanded
                    )
                    .padding(.leading, 16)
                }
            }
        } label: {
            HStack {
                Toggle(isOn: Binding(
                    get: { isShabadSaved(in: folder) },
                    set: { newValue in
                        if newValue {
                            save(to: folder)
                        } else {
                            remove(from: folder)
                        }
                    }
                )) {
                    Text(folder.name)
                }
                .toggleStyle(.switch)
            }
        }
    }

    private func isShabadSaved(in folder: Folder) -> Bool {
        folder.savedShabads.contains { $0.sbdRes.shabadinfo.shabadid == sbdRes.shabadinfo.shabadid }
    }

    private func save(to folder: Folder) {
        guard !isShabadSaved(in: folder) else { return }
        let saved = SavedShabad(
            folder: folder,
            sbdRes: sbdRes,
            indexOfSelectedLine: indexOfLine ?? 0,
            sortIndex: folder.savedShabads.count
        )
        modelContext.insert(saved) // <-- Important
        folder.savedShabads.append(saved)
        try? modelContext.save()
    }

    private func remove(from folder: Folder) {
        if let existing = folder.savedShabads.first(where: { $0.sbdRes.shabadinfo.shabadid == sbdRes.shabadinfo.shabadid }) {
            folder.savedShabads.removeAll(where: { $0.sbdRes.shabadinfo.shabadid == sbdRes.shabadinfo.shabadid })
            modelContext.delete(existing)
        }
        try? modelContext.save()
    }
}

//#Preview {
    // ShabadViewDisplayWrapper(sbdRes: SampleData.sbdHist)
//}
