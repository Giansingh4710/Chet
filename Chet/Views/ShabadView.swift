import SwiftData
import SwiftUI
import WidgetKit

struct ShabadViewDisplayWrapper: View {
    let sbdRes: ShabadAPIResponse
    var indexOfLine: Int
    var onIndexChange: ((Int) -> Void)? = nil // optional callback

    @State private var localIndexOfLine = 0
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
            ShabadViewDisplay(sbdRes: sbdRes2, fetchNewShabad: fetchNewShabad, indexOfLine: localIndexOfLine, onIndexChange: localIndexOfLine == -1 ? nil : onIndexChange)
        } else {
            ShabadViewDisplay(sbdRes: sbdRes, fetchNewShabad: fetchNewShabad, indexOfLine: localIndexOfLine, onIndexChange: localIndexOfLine == -1 ? nil : onIndexChange)
                .onAppear {
                    localIndexOfLine = indexOfLine
                }
        }
    }

    private func fetchNewShabad(_ sbdID: Int) async {
        do {
            isLoadingShabad = true
            let decoded = try await fetchShabadResponse(from: sbdID)
            await MainActor.run {
                isLoadingShabad = false
                sbdRes2 = decoded
                // onIndexChange = nil
                localIndexOfLine = -1
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
    let fetchNewShabad: (Int) async -> Void
    // var indexOfLine: Int
    @State var indexOfLine: Int
    var onIndexChange: ((Int) -> Void)? = nil // optional callback

    @AppStorage("shabadTextScale") private var textScale: Double = 1.0
    @AppStorage("translationShabadTextScale") private var translationTextScale: Double = 1.0
    @AppStorage("punjabiTranslationTextScale") private var punjabiTranslationTextScale: Double = 1.0
    @AppStorage("showTranslations") private var showTranslations: Bool = true
    @AppStorage("showPunjabiTranslations") private var showPunjabiTranslations: Bool = false
    @AppStorage("larivaar") private var larivaarOn: Bool = true
    @AppStorage("fontType") private var fontType: String = "Unicode"
    @AppStorage("swipeToGoToNextShabadSetting") private var swipeToGoToNextShabadSetting = true

    @State private var gestureScale: CGFloat = 1.0
    @State private var showingSettings = false
    @State private var showingSaved = false
    @State private var showCopySheet = false
    @State private var preselectedLineID: Int = 0 // id of line

    @State private var showLinePicker = false
    @State private var selectedLineIndex = 0

    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        // --- Meta Info Card ---
                        PreviewContextView {
                            HStack(spacing: 32) {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "book.closed")
                                        Text("Ang \(String(sbdRes.shabadInfo.pageNo))")
                                            .font(.caption).fontWeight(.semibold)
                                    }
                                    HStack(spacing: 6) {
                                        Image(systemName: "text.quote")
                                        Text("\(sbdRes.verses.count) lines")
                                            .font(.caption).fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "pencil")
                                        Text(sbdRes.shabadInfo.writer.english)
                                            .font(.caption).fontWeight(.semibold)
                                    }
                                    HStack(spacing: 6) {
                                        Image(systemName: "music.note")
                                        Text(sbdRes.shabadInfo.raag.english)
                                            .font(.caption).fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .blue.opacity(0.5), radius: 4, x: 0, y: 2)
                            )
                            .padding(.horizontal)
                        } preview: {
                            ShabadMetaInfoSheet(info: sbdRes.shabadInfo)
                        }

                        // --- Gurbani Lines ---
                        // ForEach(Array(sbdRes.verses.enumerated()), id: \.1.verseId) { index, verse in
                        ForEach(sbdRes.verses.indices, id: \.self) { index in
                            let verse = sbdRes.verses[index]
                            VStack(alignment: .leading, spacing: 0) {
                                GurbaniLineView(
                                    shabadLine: verse,
                                    larivaarOn: $larivaarOn,
                                    textScale: textScale,
                                    gestureScale: gestureScale,
                                    isSearchedLine: indexOfLine == index
                                )
                                .padding(.horizontal)
                                .id(index)
                                .onLongPressGesture {
                                    preselectedLineID = verse.verseId // 👈 track the preselected line IDs
                                    showCopySheet = true
                                }

                                if showTranslations {
                                    Text(verse.translation.en.bdb)
                                        .font(.system(size: 20 * translationTextScale * gestureScale))
                                        .foregroundColor(.secondary)
                                        .lineSpacing(2)
                                        .padding(.horizontal)
                                        .padding(.top, 2) // small top space just for translation
                                }

                                if showPunjabiTranslations,
                                   let pu_trans = verse.translation.pu.bdb.unicode
                                {
                                    Text(pu_trans)
                                        .font(.system(size: 20 * punjabiTranslationTextScale * gestureScale))
                                        .foregroundColor(.secondary)
                                        .lineSpacing(2)
                                        .padding(.horizontal)
                                        .padding(.top, 2) // small top space just for translation
                                }
                            }
                            // Use smaller or no vertical padding
                            .padding(.vertical, 2)
                        }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation {
                                    proxy.scrollTo(indexOfLine, anchor: .center)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 60) // leave space for docked bar
                }
            }

            VStack {
                Spacer()
                HStack {
                    // Prev Button
                    if let prevID = sbdRes.navigation.previous {
                        Button {
                            Task { await fetchNewShabad(prevID) }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .frame(width: 44, height: 44)
                        }
                    } else {
                        Spacer().frame(width: 44)
                    }

                    Spacer()

                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title2)
                            .frame(width: 44, height: 44)
                    }

                    Spacer()
                    Button {
                        showingSaved = true
                    } label: {
                        Image(systemName: "bookmark")
                            .font(.title2)
                            .frame(width: 44, height: 44)
                    }
                    Spacer()

                    // Next Button
                    if let nextID = sbdRes.navigation.next {
                        Button {
                            Task { await fetchNewShabad(nextID) }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                .frame(width: 44, height: 44)
                        }
                    } else {
                        Spacer().frame(width: 44)
                    }
                }
                .background(.ultraThinMaterial) // iOS-style frosted bar
                .cornerRadius(20)
                .padding(.horizontal)
                .padding(.bottom, 20) // 👈 controls the "hover" distance
            }
            .id(sbdRes.shabadInfo.shabadId) // ← Key part
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if !swipeToGoToNextShabadSetting {
                        return
                    }
                    let horizontalAmount = value.translation.width

                    if horizontalAmount < -50, let nextID = sbdRes.navigation.next {
                        Task { await fetchNewShabad(nextID) }
                    } else if horizontalAmount > 50, let prevID = sbdRes.navigation.previous {
                        Task { await fetchNewShabad(prevID) }
                    }
                }
        )
        .animation(.easeInOut, value: sbdRes.shabadInfo.shabadId)
        .gesture(
            MagnificationGesture()
                .onChanged { gestureScale = $0 }
                .onEnded {
                    textScale *= $0
                    translationTextScale *= $0
                    punjabiTranslationTextScale *= $0
                    gestureScale = 1.0
                }
        )
        .navigationBarTitle("Shabad \(sbdRes.shabadInfo.shabadId)", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    selectedLineIndex = indexOfLine
                    showLinePicker = true
                } label: {
                    Image(systemName: "arrow.left.arrow.right.circle")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showCopySheet = true
                } label: {
                    Image(systemName: "clipboard")
                }
            }
        }
        .sheet(isPresented: $showLinePicker) {
            LinePickerSheet(
                verses: sbdRes.verses,
                selectedIndex: $selectedLineIndex,
                onConfirm: {
                    indexOfLine = selectedLineIndex
                    onIndexChange?(selectedLineIndex)
                }
            )
            .presentationDetents([.medium])
        }

        .sheet(isPresented: $showCopySheet) {
            CopySheetView(
                verses: sbdRes.verses,
                showTranslations: showTranslations,
                larivaarOn: larivaarOn,
                preselectedLine: $preselectedLineID // 👈 pass selected IDs
            )
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet(
                textScale: $textScale,
                translationTextScale: $translationTextScale,
                punjabiTranslationTextScale: $punjabiTranslationTextScale,
                showTranslations: $showTranslations,
                showPunjabiTranslations: $showPunjabiTranslations,
                larivaarOn: $larivaarOn,
                fontType: $fontType
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingSaved) {
            SaveToFolderSheet(sbdRes: sbdRes, indexOfLine: indexOfLine)
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true // Don’t let the iPhone/iPad go to sleep while this app is active
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }
}

// --- Settings Sheet ---
struct SettingsSheet: View {
    @Binding var textScale: Double
    @Binding var translationTextScale: Double
    @Binding var punjabiTranslationTextScale: Double
    @Binding var showTranslations: Bool
    @Binding var showPunjabiTranslations: Bool
    @Binding var larivaarOn: Bool
    @Binding var fontType: String

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Gurmukhi")) {
                    Toggle("Larivaar", isOn: $larivaarOn)
                    Picker("Font", selection: $fontType) {
                        Text("Unicode").tag("Unicode")
                        Text("Anmol Lipi SG").tag("AnmolLipiSG")
                        Text("Anmol Lipi Bold").tag("AnmolLipiBoldTrue")
                        Text("Gurbani Akhar").tag("GurbaniAkharTrue")
                        Text("Gurbani Akhar Heavy").tag("GurbaniAkharHeavyTrue")
                        Text("Gurbani Akhar Thick").tag("GurbaniAkharThickTrue")
                        Text("Noto Sans Gurmukhi Bold").tag("NotoSansGurmukhiBoldTrue")
                        Text("Noto Sans Gurmukhi").tag("NotoSansGurmukhiTrue")
                        Text("Prabhki").tag("PrabhkiTrue")
                        Text("The Actual Characters").tag("The Actual Characters")
                    }
                    HStack {
                        Text("Font Size")
                        Slider(value: $textScale, in: 0.5 ... 2.5, step: 0.1)
                    }
                }
                Section(header: Text("Translations")) {
                    Toggle("Show Translations", isOn: $showTranslations)
                    if showTranslations {
                        HStack {
                            Text("Font Size")
                            Slider(value: $translationTextScale, in: 0.5 ... 2.5, step: 0.1)
                        }
                    }
                    Toggle("Show Punjabi Translations", isOn: $showPunjabiTranslations)
                    if showPunjabiTranslations {
                        HStack {
                            Text("Font Size")
                            Slider(value: $punjabiTranslationTextScale, in: 0.5 ... 2.5, step: 0.1)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CopySheetView: View {
    let verses: [Verse]
    let showTranslations: Bool
    let larivaarOn: Bool
    // let preselectedLine: String
    @Binding var preselectedLine: Int // 👈 binding

    @Environment(\.dismiss) var dismiss
    @State private var selectedLines: Set<Int> = []

    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                VStack {
                    // Select All / Deselect All
                    HStack {
                        Button(action: {
                            if selectedLines.count == verses.count {
                                selectedLines.removeAll()
                            } else {
                                selectedLines = Set(verses.map { $0.verseId })
                            }
                        }) {
                            Text(selectedLines.count == verses.count ? "Deselect All" : "Select All")
                                .font(.callout)
                                .padding(8)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // List of Lines
                    List {
                        ForEach(verses, id: \.verseId) { verse in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: selectedLines.contains(verse.verseId) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedLines.contains(verse.verseId) ? .blue : .secondary)
                                    Text(larivaarOn ? verse.larivaar.unicode : verse.verse.unicode)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    Spacer()
                                }
                                if showTranslations {
                                    Text(verse.translation.en.bdb)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 28)
                                }
                            }
                            .contentShape(Rectangle())
                            .id(verse.verseId) // 👈 Important for scrollTo
                            .onTapGesture {
                                if selectedLines.contains(verse.verseId) {
                                    selectedLines.remove(verse.verseId)
                                } else {
                                    selectedLines.insert(verse.verseId)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Copy Lines")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Copy") {
                            copyToClipboard()
                            dismiss()
                        }
                        .disabled(selectedLines.isEmpty)
                    }
                }
                .onAppear {
                    selectedLines.insert(preselectedLine)

                    // scroll to the first preselected line
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            proxy.scrollTo(preselectedLine, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    private func copyToClipboard() {
        let selected = verses.filter { selectedLines.contains($0.verseId) }
        let spacing = showTranslations ? "\n\n" : "\n"
        let text = selected.map { verse in
            var line = larivaarOn ? verse.larivaar.unicode : verse.verse.unicode
            if showTranslations {
                line += "\n\(verse.translation.en.bdb)"
            }
            return line
        }.joined(separator: spacing)

        UIPasteboard.general.string = text
    }
}

struct LinePickerSheet: View {
    let verses: [Verse] // the actual list of lines
    @Binding var selectedIndex: Int
    var onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                Picker("Select Line", selection: $selectedIndex) {
                    ForEach(Array(verses.enumerated()), id: \.1.verseId) { index, verse in
                        Text(verse.verse.unicode)
                            .font(.system(size: 18))
                            .lineLimit(2)
                            .tag(index)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()

                Spacer()
            }
            .navigationTitle("Select Main Line")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onConfirm()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ShabadMetaInfoSheet: View {
    let info: ShabadInfo

    let columns = [
        GridItem(.flexible(), alignment: .leading),
        GridItem(.flexible(), alignment: .leading),
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    Group {
                        Text("Shabad ID:").fontWeight(.semibold)
                        Text("\(info.shabadId)")

                        Text("Ang:").fontWeight(.semibold)
                        Text("\(info.pageNo)")

                        Text("Source:").fontWeight(.semibold)
                        Text(info.source.english)

                        Text("Writer (Eng):").fontWeight(.semibold)
                        Text(info.writer.english)

                        Text("Writer (Gurmukhi):").fontWeight(.semibold)
                        Text(info.writer.unicode)

                        Text("Raag:").fontWeight(.semibold)
                        Text(info.raag.english)

                        Text("Raag with Ang:").fontWeight(.semibold)
                        Text(info.raag.raagWithPage)

                        // if let prev = info.navigation.previous?.id {
                        //     Text("Previous ID:").fontWeight(.semibold)
                        //     Text("\(prev)")
                        // }
                        //
                        // if let next = info.navigation.next?.id {
                        //     Text("Next ID:").fontWeight(.semibold)
                        //     Text("\(next)")
                        // }
                    }
                }
                .padding()
            }
            .navigationTitle("Shabad Info")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct GurbaniLineView: View {
    let shabadLine: Verse
    @Binding var larivaarOn: Bool
    let textScale: Double
    let gestureScale: Double
    let isSearchedLine: Bool

    @AppStorage("fontType") private var fontType: String = "Unicode"
    @State private var lineLarivaar = false

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Text(getGurbaniLine(shabadLine))
            .font(resolveFont())
            .fontWeight(.medium)
            .multilineTextAlignment(.leading)
            .contentShape(Rectangle())
            .onTapGesture {
                lineLarivaar.toggle()
            }
            .onAppear {
                lineLarivaar = larivaarOn
            }
            .onChange(of: larivaarOn) {
                lineLarivaar = larivaarOn
            }
            .background(
                // only show if line is searched
                Group {
                    if isSearchedLine {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                (colorScheme == .dark ? Color.white : Color.black)
                                    .opacity(0.15)
                            )
                            .overlay( // optional subtle border/glow
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.blue.opacity(0.4), lineWidth: 0.7)
                            )
                    }
                }
            )
        // .shadow(color: isSearchedLine ? .blue.opacity(0.9) : .clear, radius: isSearchedLine ? 6 : 0) // glow highlight
    }

    private func getGurbaniLine(_ shabadLine: Verse) -> String {
        if fontType == "Unicode" {
            return lineLarivaar ? shabadLine.larivaar.unicode : shabadLine.verse.unicode
        }
        return lineLarivaar ? shabadLine.larivaar.gurmukhi : shabadLine.verse.gurmukhi
    }

    private func resolveFont() -> Font {
        let size = 20 * textScale * gestureScale

        if fontType == "Unicode" {
            return .system(size: size)
        } else {
            return .custom(fontType, size: size) // ⚠️ Important: the tag must match the *PostScript name* of the font, not necessarily the filename (use Font Book to check)
        }
    }
}

struct SaveToFolderSheet: View {
    let sbdRes: ShabadAPIResponse
    let indexOfLine: Int

    @Query(
        filter: #Predicate<Folder> { $0.parentFolder == nil },
        sort: \.sortIndex
    ) private var rootFolders: [Folder]

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            List(rootFolders, id: \.id, children: \.subfoldersOrNil) { folder in
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
            .navigationTitle("Save to Folders")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {}
                }
            }
        }
    }

    private func isShabadSaved(in folder: Folder) -> Bool {
        folder.savedShabads.contains { $0.sbdRes.shabadInfo.shabadId == sbdRes.shabadInfo.shabadId }
    }

    private func save(to folder: Folder) {
        let maxSortIndex = folder.savedShabads.map(\.sortIndex).max() ?? 0
        let saved = SavedShabad(
            folder: folder,
            sbdRes: sbdRes,
            indexOfSelectedLine: indexOfLine,
            sortIndex: maxSortIndex + 1
        )
        folder.savedShabads.append(saved)
        modelContext.insert(saved)
        try? modelContext.save()
        WidgetCenter.shared.reloadTimelines(ofKind: "xyz.gians.Chet.FavShabadsWidget")
    }

    private func remove(from folder: Folder) {
        if let existing = folder.savedShabads.first(where: { $0.sbdRes.shabadInfo.shabadId == sbdRes.shabadInfo.shabadId }) {
            modelContext.delete(existing)
        }
        try? modelContext.save()
    }
}

struct PreviewContextView<Content: View, Preview: View>: UIViewRepresentable {
    let content: Content
    let preview: Preview

    init(@ViewBuilder content: () -> Content,
         @ViewBuilder preview: () -> Preview)
    {
        self.content = content()
        self.preview = preview()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIHostingController(rootView: content).view!
        let interaction = UIContextMenuInteraction(delegate: context.coordinator)
        view.addInteraction(interaction)
        return view
    }

    func updateUIView(_: UIView, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(preview: UIHostingController(rootView: preview))
    }

    class Coordinator: NSObject, UIContextMenuInteractionDelegate {
        let previewController: UIViewController

        init(preview: UIViewController) {
            previewController = preview
        }

        func contextMenuInteraction(_: UIContextMenuInteraction,
                                    configurationForMenuAtLocation _: CGPoint) -> UIContextMenuConfiguration?
        {
            return UIContextMenuConfiguration(identifier: nil,
                                              previewProvider: { self.previewController },
                                              actionProvider: nil)
        }
    }
}
