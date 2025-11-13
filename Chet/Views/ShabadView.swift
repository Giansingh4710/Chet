import SwiftData
import SwiftUI
import WidgetKit

struct ShabadViewDisplayWrapper: View {
    let sbdRes: ShabadAPIResponse
    @State var indexOfLine: Int
    var onIndexChange: ((Int) -> Void)? = nil // optional callback

    @State var sbdRes2: ShabadAPIResponse?
    @State var onBaseSbd = true // if on the shabad that was loaded at first
    private let baseIndexOfLine: Int

    init(sbdRes: ShabadAPIResponse, indexOfLine: Int, onIndexChange: ((Int) -> Void)? = nil) {
        self.sbdRes = sbdRes
        self.indexOfLine = indexOfLine
        self.onIndexChange = onIndexChange
        baseIndexOfLine = indexOfLine
    }

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
            ShabadViewDisplay(sbdRes: sbdRes2, fetchNewShabad: fetchNewShabad, indexOfLine: indexOfLine, onIndexChange: onBaseSbd ? onIndexChange : nil)
        } else {
            ShabadViewDisplay(sbdRes: sbdRes, fetchNewShabad: fetchNewShabad, indexOfLine: indexOfLine, onIndexChange: onBaseSbd ? onIndexChange : nil)
        }
    }

    private func fetchNewShabad(_ sbdID: Int) async {
        do {
            isLoadingShabad = true
            let decoded = try await fetchShabadResponse(from: sbdID)
            await MainActor.run {
                isLoadingShabad = false
                sbdRes2 = decoded
                if sbdRes.shabadInfo.shabadId == decoded.shabadInfo.shabadId {
                    onBaseSbd = true
                    indexOfLine = baseIndexOfLine
                } else {
                    onBaseSbd = false
                    // indexOfLine = -1
                    indexOfLine = 0
                }
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
    @State var indexOfLine: Int
    var onIndexChange: ((Int) -> Void)? = nil // optional callback

    @AppStorage("settings.textScale") private var textScale: Double = 1.0
    @AppStorage("settings.englishTranslationTextScale") private var enTransTextScale: Double = 1.0 // English / common
    @AppStorage("settings.punjabiTranslationTextScale") private var punjabiTranslationTextScale: Double = 1.0
    @AppStorage("settings.hindiTranslationTextScale") private var hindiTranslationTextScale: Double = 1.0
    @AppStorage("settings.spanishTranslationTextScale") private var spanishTranslationTextScale: Double = 1.0
    @AppStorage("settings.transliterationTextScale") private var transliterationTextScale: Double = 1.0

    @AppStorage("swipeToGoToNextShabadSetting") private var swipeToGoToNextShabadSetting = true

    @State private var gestureScale: CGFloat = 1.0
    @State private var showingSettings = false
    @State private var showingSaved = false
    @State private var showWordDefinitions = false
    @State private var preSelectedLineIdForCopy: IdentifiableInt?
    @State private var selectedVerse: Verse?

    @State private var showLinePicker = false
    @State private var selectedLineIndex = 0

    @State private var hasAppeared = false

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
                                        Image(systemName: "text.quote")
                                        Text("\(sbdRes.verses.count) lines")
                                            .font(.caption).fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "book.closed")
                                        if let pageNo = sbdRes.shabadInfo.pageNo {
                                            Text("Ang \(String(pageNo))")
                                                .font(.caption).fontWeight(.semibold)
                                        }
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

                        ForEach(Array(sbdRes.verses.enumerated()), id: \.offset) { index, verse in
                            VStack(alignment: .leading, spacing: 0) {
                                GurbaniLineView(
                                    verse: verse,
                                    gestureScale: gestureScale,
                                    isSearchedLine: indexOfLine == index
                                )
                                .padding(.horizontal)
                                .id(index)
                                .onLongPressGesture {
                                    selectedVerse = verse
                                    // Small delay to ensure state is set before sheet shows
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                        showWordDefinitions = true
                                    }
                                }
                            }
                            // Use smaller or no vertical padding
                            .padding(.vertical, 2)
                        }
                        .onAppear {
                            guard !hasAppeared else { return }
                            hasAppeared = true

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
                    enTransTextScale *= $0
                    punjabiTranslationTextScale *= $0
                    hindiTranslationTextScale *= $0
                    spanishTranslationTextScale *= $0
                    transliterationTextScale *= $0
                    gestureScale = 1.0
                }
        )
        .navigationBarTitle("\(sbdRes.shabadInfo.writer.english ?? "Unknown")", displayMode: .inline)
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
                    preSelectedLineIdForCopy = IdentifiableInt(id: 0)
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

        .sheet(item: $preSelectedLineIdForCopy) { item in
            CopySheetView(
                verses: sbdRes.verses,
                preselectedLine: item.id
            )
            .presentationDetents([.medium])
        }
        .sheet(item: $selectedVerse) { thisVerse in
            WordDefinitionsSheet(
                verse: thisVerse,
                preSelectedLineIdForCopy: $preSelectedLineIdForCopy
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet()
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingSaved) {
            SaveToFolderSheet(sbdRes: sbdRes, indexOfLine: indexOfLine)
                .presentationDetents([.medium])
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true // Don’t let the iPhone/iPad go to sleep while this app is active
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }
}

struct SettingsSheet: View {
    @AppStorage("settings.textScale") private var textScale: Double = 1.0

    // Selected source for each language
    @AppStorage("settings.visraamSource") private var selectedVisraamSource: String = "igurbani"
    @AppStorage("settings.englishSource") private var selectedEnglishSource: String = "bdb"
    @AppStorage("settings.punjabiSource") private var selectedPunjabiSource: String = "none"
    @AppStorage("settings.hindiSource") private var selectedHindiSource: String = "none"
    @AppStorage("settings.spanishSource") private var selectedSpanishSource: String = "none"

    @AppStorage("settings.englishTranslationTextScale") private var enTransTextScale: Double = 1.0 // English / common
    @AppStorage("settings.punjabiTranslationTextScale") private var punjabiTranslationTextScale: Double = 1.0
    @AppStorage("settings.hindiTranslationTextScale") private var hindiTranslationTextScale: Double = 1.0
    @AppStorage("settings.spanishTranslationTextScale") private var spanishTranslationTextScale: Double = 1.0

    @AppStorage("settings.transliterationSource") private var selectedTransliterationSource: String = "none"
    @AppStorage("settings.transliterationTextScale") private var transliterationTextScale: Double = 1.0

    // Available sources (tweak as needed)
    private let visraamSources = ["none", "sttm", "igurbani", "sttm2"]

    private let englishSources: [(name: String, value: String)] = [
        ("None", "none"),
        ("Bani DB", "bdb"),
        ("Bhai Manmohan Singh", "ms"),
        ("Sant Singh Khalsa", "ssk"),
    ]

    private let punjabiSources: [(name: String, value: String)] = [
        ("None", "none"),
        ("SGGS Darpan", "ss"),
        ("Faridkot Teeka", "ft"),
        ("Bani DB", "bdb"),
        ("Bhai Manmohan Singh", "ms"),
    ]

    private let hindiSources: [(name: String, value: String)] = [
        ("None", "none"),
        ("SGGS Darpan", "ss"),
        ("STS", "sts"),
    ]

    private let spanishSources: [(name: String, value: String)] = [
        ("None", "none"),
        ("Spanish", "sn"),
    ]

    private let transliterationSources: [(name: String, value: String)] = [
        ("None", "none"),
        ("English", "en"),
        ("Hindi", "hi"),
        ("IPA", "ipa"),
        ("Urdu", "ur"),
    ]

    @AppStorage("fontType") private var fontType: String = "Unicode"
    private let fonts: [(name: String, value: String)] = [
        ("Unicode", "Unicode"),
        ("Anmol Lipi SG", "AnmolLipiSG"),
        ("Anmol Lipi Bold", "AnmolLipiBoldTrue"),
        ("Gurbani Akhar", "GurbaniAkharTrue"),
        ("Gurbani Akhar Heavy", "GurbaniAkharHeavyTrue"),
        ("Gurbani Akhar Thick", "GurbaniAkharThickTrue"),
        ("Noto Sans Gurmukhi Bold", "NotoSansGurmukhiBoldTrue"),
        ("Noto Sans Gurmukhi", "NotoSansGurmukhiTrue"),
        ("Prabhki", "Prabhki"),
        ("The Actual Characters", "The Actual Characters"),
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Gurbani Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("GURBANI")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        VStack(spacing: 0) {
                            // Visraam
                            HStack {
                                Text("Visraam")
                                    .font(.subheadline)
                                Spacer()
                                Picker("Visraam", selection: $selectedVisraamSource) {
                                    ForEach(visraamSources, id: \.self) { Text($0) }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .background(Color(.systemBackground))

                            Divider().padding(.leading)

                            SettingsOptionPickerSlider(title: "Gurbani Font", selectedItem: $fontType, options: fonts, textScale: $textScale)

                            Divider().padding(.leading)

                            SettingsOptionPickerSlider(title: "Transliteration", selectedItem: $selectedTransliterationSource, options: transliterationSources, textScale: $transliterationTextScale)
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }

                    // Translations Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TRANSLATIONS")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        VStack(spacing: 0) {
                            SettingsOptionPickerSlider(title: "English", selectedItem: $selectedEnglishSource, options: englishSources, textScale: $enTransTextScale)

                            Divider().padding(.leading)

                            SettingsOptionPickerSlider(title: "Punjabi", selectedItem: $selectedPunjabiSource, options: punjabiSources, textScale: $punjabiTranslationTextScale)

                            Divider().padding(.leading)

                            SettingsOptionPickerSlider(title: "Hindi", selectedItem: $selectedHindiSource, options: hindiSources, textScale: $hindiTranslationTextScale)

                            Divider().padding(.leading)

                            SettingsOptionPickerSlider(title: "Spanish", selectedItem: $selectedSpanishSource, options: spanishSources, textScale: $spanishTranslationTextScale)
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: selectedVisraamSource) { reloadAllWidgets() }
        .onChange(of: fontType) { reloadAllWidgets() }
        .onChange(of: selectedEnglishSource) { reloadAllWidgets() }
        .onChange(of: selectedPunjabiSource) { reloadAllWidgets() }
        .onChange(of: selectedHindiSource) { reloadAllWidgets() }
        .onChange(of: selectedSpanishSource) { reloadAllWidgets() }
        .onChange(of: selectedTransliterationSource) { reloadAllWidgets() }
    }

    private func reloadAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct SettingsOptionPickerSlider: View {
    let title: String
    @Binding var selectedItem: String
    let options: [(name: String, value: String)]
    @Binding var textScale: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                Picker(title, selection: $selectedItem) {
                    ForEach(options, id: \.value) { option in
                        Text(option.name).tag(option.value)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            if selectedItem != "none" {
                HStack(spacing: 6) {
                    Image(systemName: "textformat.size.smaller")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 14)
                    Slider(value: $textScale, in: 0.5 ... 2.5, step: 0.1)
                        .tint(.accentColor)
                    Image(systemName: "textformat.size.larger")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 14)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }
}

struct CopySheetView: View {
    let verses: [Verse]
    let preselectedLine: Int // 👈 binding

    @AppStorage("settings.larivaarOn") private var larivaarOn: Bool = false
    @AppStorage("settings.englishSource") private var selectedEnglishSource: String = "bdb"
    @AppStorage("settings.punjabiSource") private var selectedPunjabiSource: String = "none"
    @AppStorage("settings.hindiSource") private var selectedHindiSource: String = "none"
    @AppStorage("settings.spanishSource") private var selectedSpanishSource: String = "none"
    @AppStorage("settings.transliterationSource") private var selectedTransliterationSource: String = "none"

    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
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

                                if let a = verse.transliteration.value(for: selectedTransliterationSource) {
                                    Text(a)
                                        .foregroundColor(AppColors.transliterationColor(for: colorScheme))
                                        .lineSpacing(2)
                                        .opacity(0.9)
                                }
                                if let a = verse.translation.getTranslation(for: "english", source: selectedEnglishSource) {
                                    Text(a)
                                        .foregroundColor(AppColors.englishTranslationColor(for: colorScheme))
                                        .lineSpacing(2)
                                }

                                if let a = verse.translation.getTranslation(for: "punjabi", source: selectedPunjabiSource) {
                                    Text(a)
                                        .foregroundColor(AppColors.punjabiTranslationColor(for: colorScheme))
                                        .lineSpacing(2)
                                }

                                if let a = verse.translation.getTranslation(for: "hindi", source: selectedHindiSource) {
                                    Text(a)
                                        .foregroundColor(AppColors.hindiTranslationColor(for: colorScheme))
                                        .lineSpacing(2)
                                }

                                if let a = verse.translation.getTranslation(for: "spanish", source: selectedSpanishSource) {
                                    Text(a)
                                        .foregroundColor(AppColors.spanishTranslationColor(for: colorScheme))
                                        .lineSpacing(2)
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
        .onAppear {
            print("preselectedLine", preselectedLine)
        }
    }

    private func copyToClipboard() {
        let selected = verses.filter { selectedLines.contains($0.verseId) }
        var onlyGurmukhi = true
        let text = selected.map { verse in
            var line = larivaarOn ? verse.larivaar.unicode : verse.verse.unicode
            if let a = verse.transliteration.value(for: selectedTransliterationSource) {
                line += "\n" + a
                onlyGurmukhi = false
            }
            if let a = verse.translation.getTranslation(for: "english", source: selectedEnglishSource) {
                line += "\n" + a
                onlyGurmukhi = false
            }

            if let a = verse.translation.getTranslation(for: "punjabi", source: selectedPunjabiSource) {
                line += "\n" + a
                onlyGurmukhi = false
            }

            if let a = verse.translation.getTranslation(for: "hindi", source: selectedHindiSource) {
                line += "\n" + a
                onlyGurmukhi = false
            }

            if let a = verse.translation.getTranslation(for: "spanish", source: selectedSpanishSource) {
                line += "\n" + a
                onlyGurmukhi = false
            }

            return line
        }.joined(separator: onlyGurmukhi ? "\n" : "\n\n")

        UIPasteboard.general.string = text
    }
}

struct WordDefinitionsSheet: View {
    let verse: Verse
    @Binding var preSelectedLineIdForCopy: IdentifiableInt?

    @AppStorage("fontType") private var fontType: String = "Unicode"
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var wordDefinitions: [String: [WordDefinition]] = [:]
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    lineHeader

                    Divider()

                    Group {
                        if isLoading {
                            loadingView
                        } else if let errorMessage = errorMessage {
                            errorView(message: errorMessage)
                        } else {
                            definitionsScroll
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Word Definitions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                        preSelectedLineIdForCopy = IdentifiableInt(id: verse.verseId)
                    } label: {
                        Label("Copy", systemImage: "doc.on.clipboard")
                    }
                }
            }
            .onAppear {
                fetchDefinitions()
            }
        }
    }

    // MARK: - Subviews

    private var lineHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Line")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            Text(verse.verse.gurmukhi)
                .font(resolveFont(size: 20, fontType: fontType))
                .fontWeight(.medium)
                .padding(.top, 2)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.3)
            Text("Loading definitions…")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxHeight: .infinity)
    }

    private var definitionsScroll: some View {
        // let text = verse.verse.unicode.components(separatedBy: " ").filter { !$0.isEmpty }
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(Array(verse.verse.unicode.components(separatedBy: " ").filter { !$0.isEmpty }.enumerated()), id: \.offset) { _, word in
                    if let definitions = wordDefinitions[word], !definitions.isEmpty {
                        wordSection(word, definitions: definitions)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }

    private func wordSection(_ word: String, definitions: [WordDefinition]) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(word)
                .font(.title3)
                .fontWeight(.semibold)
            // .padding(.bottom, 4)
            // .padding(.horizontal, 4)

            VStack(spacing: 10) {
                ForEach(definitions) { definition in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(definition.definition)
                            .font(resolveFont(size: 15, fontType: fontType))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
                }
            }
        }
    }

    private func fetchDefinitions() {
        isLoading = true
        errorMessage = nil

        let text = verse.verse.unicode
        let words = text.components(separatedBy: " ").filter { !$0.isEmpty }

        guard !words.isEmpty else {
            isLoading = false
            errorMessage = "No words found in this line."
            return
        }

        Task {
            var definitions: [String: [WordDefinition]] = [:]
            var hasNetworkError = false

            for word in words {
                do {
                    let result = try await fetchWordDefinition(word: word)
                    if !result.isEmpty {
                        definitions[word] = result
                    }
                } catch {
                    if error is URLError {
                        hasNetworkError = true
                    }
                }
            }

            await MainActor.run {
                if hasNetworkError && definitions.isEmpty {
                    errorMessage = "Unable to load definitions. Please check your internet connection."
                } else if definitions.isEmpty {
                    errorMessage = "No definitions found for this line."
                } else {
                    wordDefinitions = definitions
                }
                isLoading = false
            }
        }
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

    // Small compact typography
    private let labelFont = Font.caption2.weight(.semibold)
    private let valueFont = Font.caption2

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 8) {
                    // Title
                    Text("Shabad Info — Full Metadata")
                        .font(.subheadline).bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 2)

                    // Render rows where each row contains up to two pairs
                    ForEach(chunkedPairs, id: \.0) { _, pairTuple in
                        HStack(alignment: .top, spacing: 12) {
                            // First pair (always exists)
                            PairView(label: pairTuple.0.label, value: pairTuple.0.value,
                                     labelFont: labelFont, valueFont: valueFont)

                            // Second pair (may be the sentinel empty pair if odd count)
                            if let second = pairTuple.1 {
                                PairView(label: second.label, value: second.value,
                                         labelFont: labelFont, valueFont: valueFont)
                            } else {
                                Spacer(minLength: 0)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .navigationTitle("Shabad Info")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Pair rendering

    private struct PairView: View {
        let label: String
        let value: String
        let labelFont: Font
        let valueFont: Font

        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(label + ":")
                    .font(labelFont)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(value)
                    .font(valueFont)
                    .foregroundColor(value == "None" ? .gray : .primary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            // let each pair take up roughly half the width
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Flattened fields (all shown; nil/empty -> "None")

    private var allPairs: [(label: String, value: String)] {
        let items: [(String, String?)] = [
            // Shabad
            ("shabadId", "\(info.shabadId)"),
            ("shabadName", "\(info.shabadName)"),
            ("pageNo", "\(info.pageNo)"),

            // Source
            ("source.sourceId", info.source.sourceId),
            ("source.gurmukhi", info.source.gurmukhi),
            ("source.unicode", info.source.unicode),
            ("source.english", info.source.english),
            ("source.pageNo", info.source.pageNo.map { "\($0)" }),

            // Raag
            ("raag.raagId", info.raag.raagId.map { "\($0)" }),
            ("raag.gurmukhi", info.raag.gurmukhi),
            ("raag.unicode", info.raag.unicode),
            ("raag.english", info.raag.english),
            ("raag.raagWithPage", info.raag.raagWithPage),

            // Writer
            ("writer.writerId", info.writer.writerId.map { "\($0)" }),
            ("writer.gurmukhi", info.writer.gurmukhi),
            ("writer.unicode", info.writer.unicode),
            ("writer.english", info.writer.english),
        ]

        return items.map { label, raw in
            let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return (label: label, value: trimmed.isEmpty ? "None" : trimmed)
        }
    }

    // MARK: - Chunk into rows of two pairs each

    // Returns array of (index, (firstPair, optionalSecondPair))
    private var chunkedPairs: [(Int, ((label: String, value: String), (label: String, value: String)?))] {
        var result: [(Int, ((label: String, value: String), (label: String, value: String)?))] = []
        let pairs = allPairs
        var i = 0
        while i < pairs.count {
            let first = pairs[i]
            let second: (label: String, value: String)? = (i + 1 < pairs.count) ? pairs[i + 1] : nil
            result.append((i / 2, (first, second)))
            i += 2
        }
        return result
    }
}

struct GurbaniLineView: View {
    let verse: Verse
    let gestureScale: Double
    let isSearchedLine: Bool

    @AppStorage("settings.larivaarOn") private var larivaarOn: Bool = true
    @AppStorage("settings.larivaarAssist") private var larivaarAssist: Bool = false
    @AppStorage("settings.textScale") private var textScale: Double = 1.0
    @AppStorage("settings.visraamSource") private var selectedVisraamSource: String = "igurbani"
    @AppStorage("settings.englishSource") private var selectedEnglishSource: String = "bdb"
    @AppStorage("settings.punjabiSource") private var selectedPunjabiSource: String = "none"
    @AppStorage("settings.hindiSource") private var selectedHindiSource: String = "none"
    @AppStorage("settings.spanishSource") private var selectedSpanishSource: String = "none"
    @AppStorage("settings.englishTranslationTextScale") private var enTransTextScale: Double = 1.0 // English / common
    @AppStorage("settings.punjabiTranslationTextScale") private var punjabiTranslationTextScale: Double = 1.0
    @AppStorage("settings.hindiTranslationTextScale") private var hindiTranslationTextScale: Double = 1.0
    @AppStorage("settings.spanishTranslationTextScale") private var spanishTranslationTextScale: Double = 1.0
    @AppStorage("settings.transliterationSource") private var selectedTransliterationSource: String = "none"
    @AppStorage("settings.transliterationTextScale") private var transliterationTextScale: Double = 1.0

    @AppStorage("fontType") private var fontType: String = "Unicode"
    @State private var lineLarivaar = false

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            renderGurbaniLine(verse)
                .font(resolveFont(size: 20 * textScale * gestureScale, fontType: fontType))
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
                    Group {
                        if isSearchedLine {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    (colorScheme == .dark ? Color.white : Color.black)
                                        .opacity(0.15)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.blue.opacity(0.4), lineWidth: 0.7)
                                )
                        }
                    }
                )

            if let a = verse.transliteration.value(for: selectedTransliterationSource) {
                Text(a)
                    .font(.system(size: 16 * transliterationTextScale * gestureScale, design: .monospaced))
                    .foregroundColor(AppColors.transliterationColor(for: colorScheme))
                    .lineSpacing(2)
                    .opacity(0.9)
            }
            if let a = verse.translation.getTranslation(for: "english", source: selectedEnglishSource) {
                Text(a)
                    .font(.system(size: 17 * enTransTextScale * gestureScale, design: .rounded))
                    .foregroundColor(AppColors.englishTranslationColor(for: colorScheme))
                    .lineSpacing(2)
            }

            if let a = verse.translation.getTranslation(for: "punjabi", source: selectedPunjabiSource) {
                Text(a)
                    .font(.system(size: 16 * punjabiTranslationTextScale * gestureScale))
                    .foregroundColor(AppColors.punjabiTranslationColor(for: colorScheme))
                    .lineSpacing(2)
            }

            if let a = verse.translation.getTranslation(for: "hindi", source: selectedHindiSource) {
                Text(a)
                    .font(.system(size: 16 * hindiTranslationTextScale * gestureScale))
                    .foregroundColor(AppColors.hindiTranslationColor(for: colorScheme))
                    .lineSpacing(2)
            }

            if let a = verse.translation.getTranslation(for: "spanish", source: selectedSpanishSource) {
                Text(a)
                    .font(.system(size: 16 * spanishTranslationTextScale * gestureScale))
                    .foregroundColor(AppColors.spanishTranslationColor(for: colorScheme))
                    .lineSpacing(2)
            }
        }
    }

    func renderGurbaniLine(_ verse: Verse) -> Text {
        let isLarivaarMode = lineLarivaar
        let text = fontType == "Unicode" ? verse.verse.unicode : verse.verse.gurmukhi
        let words = text.components(separatedBy: " ")

        // Get visraam points based on selected source
        var visraamPoints: [Int: String] = [:] // [position: type]
        if let visraam = verse.visraam {
            let selectedVisraamData: [Visraam.VisraamPoint]
            switch selectedVisraamSource {
            case "sttm":
                selectedVisraamData = visraam.sttm ?? []
            case "sttm2":
                selectedVisraamData = visraam.sttm2 ?? []
            case "igurbani":
                selectedVisraamData = visraam.igurbani ?? []
            default:
                selectedVisraamData = []
            }

            for point in selectedVisraamData {
                visraamPoints[point.p] = point.t
            }
        }

        var result = Text("")
        for (index, word) in words.enumerated() {
            let wordText: Text
            let color: Color

            if let visraamType = visraamPoints[index] {
                color = AppColors.visraamColor(type: visraamType, for: colorScheme)
            } else if larivaarAssist && lineLarivaar {
                color = AppColors.larivaarAssistColor(index: index, for: colorScheme)
            } else {
                color = .primary // Normal mode - just primary color
            }

            wordText = Text(word).foregroundColor(color)
            result = result + wordText

            // Add space between words only if not in larivaar or larivaar assist mode
            if index < words.count - 1 && !isLarivaarMode {
                result = result + Text(" ")
            }
        }

        return result
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
    @AppStorage("backupChangeCounter") private var backupChangeCounter = 0
    @State private var showBackupToast = false
    @State private var backupMessage = ""

    var body: some View {
        ZStack {
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

            // Backup toast notification
            if showBackupToast {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Backup Created")
                                .font(.headline)
                            Text(backupMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    .padding()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(999)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showBackupToast)
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

        // Only reload FavShabadsWidget if saving to the Favorites folder
        if folder.name == "Favorites" && folder.isSystemFolder {
            WidgetCenter.shared.reloadTimelines(ofKind: "xyz.gians.Chet.FavShabadsWidget")
        }

        // Increment backup counter and trigger backup if threshold reached
        backupChangeCounter += 1
        if backupChangeCounter >= 5 {
            Task {
                do {
                    let data = try await BackupManager.shared.exportToJSON(modelContext: modelContext)
                    let url = try await BackupManager.shared.saveToiCloud(data: data)
                    UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastBackupTime")
                    print("✅ Auto-backup completed after 5 changes")

                    // Show toast notification
                    await MainActor.run {
                        let location = url.path.contains("iCloud") ? "iCloud Drive" : "Documents"
                        backupMessage = "Saved to \(location)/Chet Backups/"
                        showBackupToast = true

                        // Hide toast after 4 seconds
                        Task {
                            try? await Task.sleep(nanoseconds: 4_000_000_000)
                            showBackupToast = false
                        }
                    }
                } catch {
                    print("❌ Auto-backup failed: \(error.localizedDescription)")

                    // Show error toast
                    await MainActor.run {
                        backupMessage = "Backup failed"
                        showBackupToast = true

                        Task {
                            try? await Task.sleep(nanoseconds: 3_000_000_000)
                            showBackupToast = false
                        }
                    }
                }
            }
            backupChangeCounter = 0
        }
    }

    private func remove(from folder: Folder) {
        if let existing = folder.savedShabads.first(where: { $0.sbdRes.shabadInfo.shabadId == sbdRes.shabadInfo.shabadId }) {
            modelContext.delete(existing)
        }
        try? modelContext.save()

        // Reload FavShabadsWidget if removing from the Favorites folder
        if folder.name == "Favorites" && folder.isSystemFolder {
            WidgetCenter.shared.reloadTimelines(ofKind: "xyz.gians.Chet.FavShabadsWidget")
        }
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
