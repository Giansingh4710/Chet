//
//  BaniView.swift
//  Chet
//
//  Created by gian singh on 11/10/25.
//

import SwiftUI

struct BaniView: View {
    let baniTitle: String
    let baniFilename: String
    let partitionIndexes: [Int]

    init(baniTitle: String) {
        self.baniTitle = baniTitle
        baniFilename = bani_title_to_filename[baniTitle] ?? ""
        partitionIndexes = bani_partitions[baniFilename] ?? []
    }

    @AppStorage("settings.larivaarOn") private var globalLarivaarOn: Bool = true
    @AppStorage("settings.larivaarAssist") private var larivaarAssist: Bool = false
    @AppStorage("fontType") private var fontType: String = "Unicode"

    @State private var baniData: BaniResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var gestureScale: CGFloat = 1.0
    @State private var showingSettings = false
    @State private var showCopySheet = false
    @State private var showWordDefinitions = false
    @State private var preSelectedLineIdForCopy: Int = 0
    @State private var selectedVerse: Verse?
    @State private var currentSectionIndex: Int = 0
    @State private var showBaniInfo = false

    // Bani-specific settings (separate from ShabadView)
    @AppStorage("bani.textScale") private var textScale: Double = 1.0
    @AppStorage("bani.visraamSource") private var selectedVisraamSource = "igurbani"
    @AppStorage("bani.englishSource") private var selectedEnglishSource: String = "none"
    @AppStorage("bani.punjabiSource") private var selectedPunjabiSource = "none"
    @AppStorage("bani.hindiSource") private var selectedHindiSource = "none"
    @AppStorage("bani.transliterationSource") private var selectedTransliterationSource = "none"
    @AppStorage("bani.englishTranslationTextScale") private var enTransTextScale: Double = 1.0
    @AppStorage("bani.punjabiTranslationTextScale") private var punjabiTransTextScale: Double = 1.0
    @AppStorage("bani.hindiTranslationTextScale") private var hindiTransTextScale: Double = 1.0
    @AppStorage("bani.transliterationTextScale") private var transliterationTextScale: Double = 1.0
    @AppStorage("bani.paragraphMode") private var isParagraphMode: Bool = false
    @AppStorage("bani.recension") private var selectedRecension: String = "SGPC"
    @AppStorage("bani.mangalPosition") private var selectedMangalPosition: String = "current"
    @AppStorage("bani.enableSections") private var enableSections: Bool = true

    // Autoscroll state
    @State private var isAutoscrolling = false
    @State private var showControlsModal = false
    @State private var autoscrollSpeed: Double = 30.0
    @State private var scrollController: AutoScrollViewController<AnyView>?
    @AppStorage("swipeToGoToNextShabadSetting") private var swipeToGoToNextShabadSetting = true

    @Environment(\.colorScheme) var colorScheme

    // Cache for paragraph grouping to avoid recomputing on every render
    @State private var cachedParagraphs: [[BaniVerse]] = []
    @State private var lastCachedVerses: [BaniVerse] = []

    /// Check if bani has recension variation (at least one field differs from 1)
    private var hasRecensionVariation: Bool {
        guard let baniData = baniData else { return false }

        // Check if any verse has any field != 1
        return baniData.verses.contains { verse in
            verse.existsSGPC != 1 ||
                verse.existsMedium != 1 ||
                verse.existsTaksal != 1 ||
                verse.existsBuddhaDal != 1
        }
    }

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Loading Bani...")
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else if let baniData = baniData {
                AutoScrollView(controller: $scrollController) {
                    AnyView(
                        LazyVStack(spacing: 4, pinnedViews: []) {
                            if isParagraphMode {
                                paragraphView(verses: getCurrentSectionVerses())
                            } else {
                                individualLinesView(verses: getCurrentSectionVerses())
                            }
                        }
                        .id(isParagraphMode) // 👈 Forces rebuild when AppStorage toggles
                        .padding(10)
                        .background(colorScheme == .dark ? Color.black : Color.white)
                    )
                }
                .onChange(of: currentSectionIndex) { _, _ in
                    scrollController?.scrollToTop()
                }
                .onChange(of: scrollController) { _, newController in
                    // Set callback to update UI when scrolling ends
                    newController?.onScrollEnd = {
                        DispatchQueue.main.async {
                            isAutoscrolling = false
                        }
                    }
                }
            }

            // Floating Autoscroll Controls Modal
            if showControlsModal {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showControlsModal = false
                        }
                    }

                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Text("Auto Scroll")
                            .font(.headline)
                        Spacer()
                        Button(action: {
                            withAnimation {
                                showControlsModal = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    // Speed Control
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Scroll Speed")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        HStack(spacing: 12) {
                            Image(systemName: "tortoise.fill")
                                .font(.title3)
                                .foregroundColor(.secondary)

                            VStack(spacing: 4) {
                                Slider(value: Binding(
                                    get: { autoscrollSpeed },
                                    set: { newValue in
                                        autoscrollSpeed = newValue
                                        scrollController?.setScrollSpeed(newValue)
                                    }
                                ), in: 10 ... 100, step: 5)

                                Text("\(Int(autoscrollSpeed)) pts/sec")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Image(systemName: "hare.fill")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Pause/Resume Button
                    Button(action: {
                        if isAutoscrolling {
                            // Pause
                            isAutoscrolling = false
                            scrollController?.stopScrolling()
                        } else {
                            // Resume
                            isAutoscrolling = true
                            scrollController?.startScrolling(speed: autoscrollSpeed)
                        }
                    }) {
                        HStack {
                            Image(systemName: isAutoscrolling ? "pause.fill" : "play.fill")
                            Text(isAutoscrolling ? "Pause" : "Resume")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                    }
                }
                .padding(24)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(20)
                .shadow(radius: 20)
                .padding(.horizontal, 40)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button(action: {
                    showBaniInfo = true
                }) {
                    Text(baniTitle)
                        .font(resolveFont(size: 20, fontType: fontType))
                        .foregroundColor(.primary)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: toggleAutoscroll) {
                    Image(systemName: isAutoscrolling ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title3)
                }
            }

            ToolbarItemGroup(placement: .bottomBar) {
                if enableSections && !partitionIndexes.isEmpty {
                    Button(action: goToPreviousSection) {
                        Label("Previous", systemImage: "chevron.left")
                    }
                    .disabled(!canGoPrevious)

                    Spacer()

                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                    }

                    Spacer()

                    Button(action: goToNextSection) {
                        Label("Next", systemImage: "chevron.right")
                    }
                    .disabled(!canGoNext)
                } else {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                if enableSections && !partitionIndexes.isEmpty {
                    Menu {
                        ForEach(0 ..< partitionIndexes.count, id: \.self) { index in
                            Button(action: {
                                currentSectionIndex = index
                            }) {
                                HStack {
                                    if index == currentSectionIndex {
                                        Image(systemName: "checkmark")
                                    }
                                    Text(getSectionTitle(for: index))
                                }
                            }
                        }
                    } label: {
                        // Label("Sections", systemImage: "list.bullet")
                        Text("\(currentSectionIndex + 1)/\(partitionIndexes.count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .sheet(isPresented: $showBaniInfo) {
            if let baniData = baniData {
                BaniMetaInfoSheet(info: baniData.baniInfo)
            }
        }
        .sheet(isPresented: $showingSettings) {
            BaniSettingsSheet(hasRecensionVariation: hasRecensionVariation)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showCopySheet) {
            if let baniData = baniData {
                CopySheetView(
                    verses: baniData.verses.map { $0.verse },
                    preselectedLine: preSelectedLineIdForCopy
                )
                .presentationDetents([.medium])
            }
        }
        .sheet(item: $selectedVerse) { thisVerse in
            WordDefinitionsSheet(
                verse: thisVerse,
                preSelectedLineIdForCopy: Binding(
                    get: { nil },
                    set: { newValue in
                        if let id = newValue?.id {
                            preSelectedLineIdForCopy = id
                            showCopySheet = true
                        }
                    }
                )
            )
            .presentationDetents([.medium])
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if !swipeToGoToNextShabadSetting {
                        return
                    }
                    if !enableSections || partitionIndexes.isEmpty {
                        return
                    }
                    let horizontalAmount = value.translation.width

                    if horizontalAmount < -50 {
                        // Swipe left - go to next section
                        goToNextSection()
                    } else if horizontalAmount > 50 {
                        // Swipe right - go to previous section
                        goToPreviousSection()
                    }
                }
        )
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    gestureScale = value
                }
                .onEnded { _ in
                    textScale *= gestureScale
                    gestureScale = 1.0
                }
        )
        .animation(.easeInOut, value: currentSectionIndex)
        .onAppear {
            loadBani()
        }
        .onDisappear {
            // Stop autoscrolling when leaving the view
            if isAutoscrolling {
                isAutoscrolling = false
                showControlsModal = false
                scrollController?.stopScrolling()
            }
        }
    }

    private func loadBani() {
        guard let url = Bundle.main.url(forResource: baniFilename, withExtension: "json") else {
            errorMessage = "Bani file '\(baniFilename)' not found"
            isLoading = false
            return
        }

        // Load and decode JSON on background thread to avoid blocking UI
        Task.detached(priority: .userInitiated) {
            do {
                let data = try Data(contentsOf: url)
                let decoded = try JSONDecoder().decode(BaniResponse.self, from: data)

                // Update UI on main thread
                await MainActor.run {
                    self.baniData = decoded
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load bani: \(error.localizedDescription)"
                    print("❌ JSON Decode Error: \(error)")
                    self.isLoading = false
                }
            }
        }
    }

    private func getCurrentSectionVerses() -> [BaniVerse] {
        guard let baniData = baniData else { return [] }

        // 1 — Extract the verses for the current section
        let sectionVerses: [BaniVerse] = {
            guard enableSections, !partitionIndexes.isEmpty else {
                return baniData.verses
            }

            let start = partitionIndexes[currentSectionIndex]
            let end = (currentSectionIndex < partitionIndexes.count - 1)
                ? partitionIndexes[currentSectionIndex + 1]
                : baniData.verses.count

            return Array(baniData.verses[start ..< end])
        }()

        // 2 — Apply recension filter
        let filteredByRecension: [BaniVerse] = sectionVerses.filter { verse in
            switch selectedRecension {
            case "sgpc": return verse.existsSGPC == 1
            case "medium": return verse.existsMedium == 1
            case "buddhaDal": return verse.existsBuddhaDal == 1
            default: return verse.existsTaksal == 1 // "taksal"
            }
        }

        // 3 — Apply mangalPosition filtering
        return filteredByRecension.filter { verse in
            guard verse.header > 0 else { return true } // Only filter headers

            guard let mangalPos = verse.mangalPosition else {
                return true // No mangal position = always show
            }

            return mangalPos == selectedMangalPosition // Match filter
        }
    }

    // Get section title for display
    private func getSectionTitle(for sectionIndex: Int) -> String {
        guard let baniData = baniData, !partitionIndexes.isEmpty else { return "" }
        guard sectionIndex < partitionIndexes.count else { return "" }

        var verseIndex = partitionIndexes[sectionIndex]
        guard verseIndex < baniData.verses.count else { return "Section \(sectionIndex + 1)" }

        while baniData.verses[verseIndex].header != 0 {
            verseIndex += 1
        }
        let verse = baniData.verses[verseIndex]
        let title = verse.verse.verse.unicode
        if title.count > 15 {
            return "\(sectionIndex + 1). " + String(title.prefix(15)) + "..."
        } else {
            return "\(sectionIndex + 1). " + title
        }

        // If verse has header > 0, try to get meaningful title from the verse text
        if verse.header > 0 {
            let title = verse.verse.verse.unicode
            if title.count > 30 {
                return String(title.prefix(30)) + "..."
            }
            return title
        }

        return "Section \(sectionIndex + 1)"
    }

    /// Check if can go to previous section
    private var canGoPrevious: Bool {
        currentSectionIndex > 0
    }

    /// Check if can go to next section
    private var canGoNext: Bool {
        !partitionIndexes.isEmpty && currentSectionIndex < partitionIndexes.count - 1
    }

    /// Navigate to previous section
    private func goToPreviousSection() {
        if canGoPrevious {
            currentSectionIndex -= 1
        }
    }

    // Navigate to next section
    private func goToNextSection() {
        if canGoNext {
            currentSectionIndex += 1
        }
    }

    private func toggleAutoscroll() {
        if isAutoscrolling {
            // Pause autoscrolling
            withAnimation {
                isAutoscrolling = false
            }
            scrollController?.stopScrolling()
        } else {
            // Start autoscrolling and show controls modal on first use
            withAnimation {
                isAutoscrolling = true
                showControlsModal = true
            }
            scrollController?.startScrolling(speed: autoscrollSpeed)
        }
    }

    private func getCachedParagraphs(for verses: [BaniVerse]) -> [[BaniVerse]] {
        // Check if we need to recompute (verses changed)
        if verses.count != lastCachedVerses.count ||
            zip(verses, lastCachedVerses).contains(where: { $0.id != $1.id })
        {
            // Verses changed, recompute and cache
            let newParagraphs = groupVersesByParagraph(verses)
            DispatchQueue.main.async {
                self.cachedParagraphs = newParagraphs
                self.lastCachedVerses = verses
            }
            return newParagraphs
        }
        // Return cached paragraphs
        return cachedParagraphs.isEmpty ? groupVersesByParagraph(verses) : cachedParagraphs
    }

    private func individualLinesView(verses: [BaniVerse]) -> some View {
        let paragraphs = groupVersesByParagraph(verses)

        return ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
            VStack(alignment: .leading) {
                ForEach(Array(paragraph.enumerated()), id: \.offset) { _, verse in
                    BaniVerseView(
                        verse: verse,
                        preSelectedLineIdForCopy: $preSelectedLineIdForCopy,
                        showCopySheet: $showCopySheet,
                        globalLarivaarOn: $globalLarivaarOn,
                        larivaarAssist: $larivaarAssist,
                        fontType: $fontType,
                        textScale: $textScale,
                        selectedVisraamSource: $selectedVisraamSource,
                        selectedTransliterationSource: $selectedTransliterationSource,
                        selectedEnglishSource: $selectedEnglishSource,
                        selectedPunjabiSource: $selectedPunjabiSource,
                        selectedHindiSource: $selectedHindiSource,
                        transliterationTextScale: $transliterationTextScale,
                        enTransTextScale: $enTransTextScale,
                        punjabiTransTextScale: $punjabiTransTextScale,
                        hindiTransTextScale: $hindiTransTextScale
                    )
                }
            }
            .padding(.bottom, 24)
        }
    }

    private func paragraphView(verses: [BaniVerse]) -> some View {
        let paragraphs = getCachedParagraphs(for: verses)

        return ForEach(Array(paragraphs.enumerated()), id: \.offset) { paragraphIndex, paragraph in
            VStack(alignment: .leading) {
                // Continuous flowing text for the paragraph (including headers)
                BaniParagraphView(
                    verses: paragraph,
                    paragraphId: paragraphIndex,
                    globalLarivaarOn: $globalLarivaarOn,
                    larivaarAssist: $larivaarAssist,
                    fontType: $fontType,
                    textScale: $textScale,
                    selectedVisraamSource: $selectedVisraamSource,
                    selectedTransliterationSource: $selectedTransliterationSource,
                    selectedEnglishSource: $selectedEnglishSource,
                    selectedPunjabiSource: $selectedPunjabiSource,
                    selectedHindiSource: $selectedHindiSource,
                    transliterationTextScale: $transliterationTextScale,
                    enTransTextScale: $enTransTextScale,
                    punjabiTransTextScale: $punjabiTransTextScale,
                    hindiTransTextScale: $hindiTransTextScale
                )
            }
            .padding(.bottom, 24)
        }
    }

    private func groupVersesByParagraph(_ verses: [BaniVerse]) -> [[BaniVerse]] {
        var paragraphs: [[BaniVerse]] = []
        var currentParagraph: [BaniVerse] = []
        var currentParagraphNumber: Int?

        for verse in verses {
            // Start a new paragraph when the paragraph number changes
            if let currentNum = currentParagraphNumber, currentNum != verse.paragraph {
                if !currentParagraph.isEmpty {
                    paragraphs.append(currentParagraph)
                }
                currentParagraph = [verse]
                currentParagraphNumber = verse.paragraph
            } else {
                currentParagraph.append(verse)
                currentParagraphNumber = verse.paragraph
            }
        }

        // Add any remaining verses
        if !currentParagraph.isEmpty {
            paragraphs.append(currentParagraph)
        }

        return paragraphs
    }
}

struct BaniParagraphView: View {
    let verses: [BaniVerse]
    let paragraphId: Int

    // Settings passed as bindings to avoid duplicate @AppStorage subscriptions
    @Binding var globalLarivaarOn: Bool
    @Binding var larivaarAssist: Bool
    @Binding var fontType: String
    @Binding var textScale: Double
    @Binding var selectedVisraamSource: String
    @Binding var selectedTransliterationSource: String
    @Binding var selectedEnglishSource: String
    @Binding var selectedPunjabiSource: String
    @Binding var selectedHindiSource: String
    @Binding var transliterationTextScale: Double
    @Binding var enTransTextScale: Double
    @Binding var punjabiTransTextScale: Double
    @Binding var hindiTransTextScale: Double

    @State private var localLarivaar: Bool = false

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(AttributedString(formattedParagraphAttributedString))
                .font(resolveFont(size: 20 * textScale, fontType: fontType))
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        localLarivaar.toggle()
                    }
                }
                .onAppear {
                    localLarivaar = globalLarivaarOn
                }
                .onChange(of: globalLarivaarOn) { _, newValue in
                    localLarivaar = newValue
                }

            // Transliteration paragraph
            if selectedTransliterationSource != "none", let transliteration = getParagraphTransliteration() {
                Text(transliteration)
                    .font(.system(size: 14 * transliterationTextScale))
                    .foregroundColor(AppColors.transliterationColor(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // English translation paragraph
            if let englishTrans = getParagraphTranslation(language: "english", source: selectedEnglishSource) {
                Text(englishTrans)
                    .font(.system(size: 14 * enTransTextScale))
                    .foregroundColor(AppColors.englishTranslationColor(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Punjabi translation paragraph
            if let punjabiTrans = getParagraphTranslation(language: "punjabi", source: selectedPunjabiSource) {
                Text(punjabiTrans)
                    .font(.system(size: 14 * punjabiTransTextScale))
                    .foregroundColor(AppColors.punjabiTranslationColor(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Hindi translation paragraph
            if let hindiTrans = getParagraphTranslation(language: "hindi", source: selectedHindiSource) {
                Text(hindiTrans)
                    .font(.system(size: 14 * hindiTransTextScale))
                    .foregroundColor(AppColors.hindiTranslationColor(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var formattedParagraphAttributedString: NSAttributedString {
        let result = NSMutableAttributedString()

        for (verseIndex, baniVerse) in verses.enumerated() {
            let text = fontType == "Unicode" ? baniVerse.verse.verse.unicode : baniVerse.verse.verse.gurmukhi
            let words = text.components(separatedBy: " ")

            // Get visraam points for this verse
            var visraamPoints: [Int: String] = [:]
            if selectedVisraamSource != "none", let visraam = baniVerse.verse.visraam {
                let selectedVisraamData: [Visraam.VisraamPoint]
                switch selectedVisraamSource {
                case "sttm": selectedVisraamData = visraam.sttm ?? []
                case "sttm2": selectedVisraamData = visraam.sttm2 ?? []
                case "igurbani": selectedVisraamData = visraam.igurbani ?? []
                default: selectedVisraamData = []
                }
                for point in selectedVisraamData {
                    visraamPoints[point.p] = point.t
                }
            }

            for (index, word) in words.enumerated() {
                let color: UIColor

                // Visraam coloring takes priority
                if let visraamType = visraamPoints[index] {
                    color = UIColor(AppColors.visraamColor(type: visraamType, for: colorScheme))
                } else if larivaarAssist && localLarivaar {
                    // Larivaar assist ONLY when in larivaar mode
                    color = UIColor(AppColors.larivaarAssistColor(index: index, for: colorScheme))
                } else {
                    color = colorScheme == .dark ? .white : .black
                }

                let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: color]
                result.append(NSAttributedString(string: word, attributes: attributes))

                // Add space between words unless in larivaar mode
                if index < words.count - 1 && !localLarivaar {
                    result.append(NSAttributedString(string: " "))
                }
            }

            // Add space between verses in paragraph (only if not in larivaar mode)
            if verseIndex < verses.count - 1 && !localLarivaar {
                result.append(NSAttributedString(string: " "))
            }
        }

        return result
    }

    private func getParagraphTransliteration() -> String? {
        var transliterations: [String] = []

        for baniVerse in verses {
            let transliteration: String?
            switch selectedTransliterationSource {
            case "en": transliteration = baniVerse.verse.transliteration.en
            case "hi": transliteration = baniVerse.verse.transliteration.hi
            case "ipa": transliteration = baniVerse.verse.transliteration.ipa
            case "ur": transliteration = baniVerse.verse.transliteration.ur
            default: transliteration = nil
            }

            if let trans = transliteration, !trans.isEmpty {
                transliterations.append(trans)
            }
        }

        return transliterations.isEmpty ? nil : transliterations.joined(separator: " ")
    }

    private func getParagraphTranslation(language: String, source: String) -> String? {
        guard source != "none" else { return nil }

        var translations: [String] = []

        for baniVerse in verses {
            if let translation = baniVerse.verse.translation.getTranslation(for: language, source: source), !translation.isEmpty {
                translations.append(translation)
            }
        }

        return translations.isEmpty ? nil : translations.joined(separator: " ")
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 0

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

let bani_title_to_filename: [String: String] = [
    "gur mMqR": "gurmantar",
    "jpujI swihb": "japji",
    "rhrwis swihb": "rehras",
    "soihlw swihb": "sohila",
    "vxjwrw": "vanjaara",
    "isrIrwg kI vwr mhlw 4": "siriraagkivaar",
    "rwgu isrIrwgu (kbIr jIau kw)": "sriraag",
    "bwrh mwhw mWJ": "baarehmaha",
    "vwr mwJ kI": "maajhkivaar",
    "krhly": "karhalai",
    "bwvn AKrI": "bavanakhree",
    "suKmnI swihb": "sukhmani",
    "iQqI mhlw 5": "thitteem5",
    "gauVI kI vwr mhlw 4": "gaurikivaarm4",
    "gauVI kI vwr mhlw 5": "gaurikivaarm5",
    "rwgu gauVI": "gauri",
    "bwvn AKrI kbIr jIau kI": "baavanakhrikabirjee",
    "iQqMØI kbIr jI kMØI": "thitteekabirjee",
    "gauVI vwr kbIr jIau ky": "vaarkabirjee",
    "ibrhVy": "birharre",
    "ptI ilKI": "patteelikhee",
    "ptI mhlw 3": "patteem3",
    "Awsw dI vwr": "asadivar",
    "rwgu Awsw": "aasa",
    "gUjrI kI vwr mhlw 3": "gujrikivaarm3",
    "rwgu gUjrI vwr mhlw 5": "gujrikivaarm5",
    "rwgu gUjrI": "gujri",
    "ibhwgVy kI vwr mhlw 4": "bihagrakivaarm4",
    "GoVIAw": "ghorrian",
    "vfhMs kI vwr mhlw 4": "vadhanskeevaarm4",
    "rwgu soriT vwr mhly 4 kI": "soratkivaarm4",
    "rwgu soriT": "sorat",
    "rwgu DnwsrI": "dhanasari",
    "jYqsrI kI vwr": "jaitsrikivar",
    "rwgu jYqsrI": "jaitsree",
    "rwgu tofI (bwxI BgqW kI)": "toddee",
    "rwgu iqlMg (bwxI Bgqw kI kbIr jI)": "tilang",
    "kucjI": "kuchji",
    "sucjI": "suchji",
    "guxvMqI": "gunvanti",
    "lwvW": "lavaa",
    "vwr sUhI kI": "soohikivaar",
    "rwgu sUhI": "soohee",
    "suKmnw swihb": "sukhmana",
    "iQqI mhlw 1": "thitteem1",
    "iblwvlu mhlw 3 vwr sq": "vaarsat",
    "iblwvlu kI vwr mhlw 4": "bilaavalkivaar",
    "rwgu iblwvlu": "bilaaval",
    "rwgu goNf": "gond",
    "Anµdu swihb": "anand",
    "rwgu rwmklI (sdu)": "ramkali",
    "rwmklI sdu": "sadd",
    "mhlw 5 ruqI": "ruteem5",
    "dKxI EAMkwru": "dhakhnioankar",
    "isD gosit": "sidhgosht",
    "rwmklI kI vwr mhlw 3": "ramkalikivaarm3",
    "rwmklI kI vwr mhlw 5": "ramkalikivaarm5",
    "rwmklI kI vwr (rwie blvMif qQw sqY)": "ramkalikivar",
    "rwgu mwlI gauVw": "maaligauri",
    "mwrU vwr mhlw 3": "maarookivaarm3",
    "mwrU vwr mhlw 5 fKxy": "vaarmaroodakhnem5",
    "rwgu mwrU": "maaru",
    "rwgu kydwrw": "kedaara",
    "rwgu BYrau": "bhairo",
    "rwgu bsMqu": "basant",
    "bsMq kI vwr": "basantkivar",
    "swrMg kI vwr mhlw 4": "sarangkivaarm4",
    "rwgu swrMg": "saarang",
    "vwr mlwr kI mhlw 1": "malaarkivaarm1",
    "rwgu mlwr": "malaar",
    "kwnVy kI vwr mhlw 4": "kaanrekivaarm4",
    "rwgu kwnVw": "kaanra",
    "rwgu pRBwqI": "prabhaati",
    "Punhy mhlw 5": "funhem5",
    "cauboly": "chaubole",
    "slok Bgq kbIr jIau ky": "salokkabir",
    "slok syK PrId ky": "salokfareed",
    "svXy sRI muKbwk´ mhlw 5 - 1": "sirimukhbaakm1a",
    "svXy sRI muKbwk´ mhlw 5 - 2": "sirimukhbaakm1b",
    "sveIey mhly pihly ky": "svaiyem1",
    "sveIey mhly dUjy ky": "svaiyem2",
    "sveIey mhly qIjy ky": "svaiyem3",
    "sveIey mhly cauQy ky": "svaiyem4",
    "sveIey mhly pMjvy ky": "svaiyem5",
    "slok mhlw 9": "salokm9",
    "rwg mwlw": "raagmala",
    "AwrqI": "aarti",
    "Sbd hzwry": "shabadhazare",
    "duK BMjnI swihb": "dukhbhanjani",
    "Ardws": "ardas",
    "jwpu swihb": "jaap",
    "Akwl ausqq cOpeI": "akaalustatchaupai",
    "Akwl ausqq": "akalustat",
    "qÍ pRswid sv`Xy (sRwvg su`D)": "svaiye",
    "qÍ pRswid sv`Xy (dInn kI)": "svaiyedeenan",
    "AQ cMfIcirqR": "athchandichariter",
    "cMfI dI vwr": "chandidivar",
    "SsqR nwm mwlw": "shastarnaammala",
    "bynqI cOpeI swihb": "chaupai",
    "sRI BgauqI AsqoqR (pMQ pRkwS)": "bhagautiastotr",
    "sRI BgauqI AsqoqR (sRI hzUr swihb)": "bhagautiastotrhazoor",
    "augRdMqI": "ogardanti",
    "bwrh mwhw svYXw": "baarehmahasvaye",
    "Sbd hzwry pwiqSwhI 10": "shabadhazare10",
]

// start of frame index
let bani_partitions: [String: [Int]] = [
    "aarti": [0],
    "aasa": [0, 14, 26, 44, 55, 66, 77, 88, 99, 110, 124, 133, 144, 155, 170, 183, 196, 208, 221, 234, 247, 260, 273, 284, 293, 302, 311, 320, 329, 338, 347, 356, 363, 370, 381, 392, 403, 414, 426, 437, 448, 457, 464, 477, 486, 495, 504, 521, 534, 553, 566],
    "akaalustatchaupai": [0],
    "akalustat": [0, 49, 90, 131, 212, 293, 374, 495, 576, 657, 738, 819, 840, 921, 970, 1011, 1068],
    "anand": [0],
    "ardas": [0],
    "asadivar": [0, 26, 66, 104, 140, 184, 215, 253, 281, 323, 357, 391, 420, 452, 483, 523, 562, 584, 612, 642, 668, 688, 720, 737],
    "athchandichariter": [0, 22],
    "baarehmaha": [0],
    "baarehmahasvaye": [0],
    "baavanakhrikabirjee": [0],
    "basant": [0, 90, 101, 118, 147, 168],
    "basantkivar": [0, 8],
    "bavanakhree": [0, 26, 38, 50, 61, 73, 84, 96, 108, 120, 132, 144, 156, 168, 178, 190, 202, 214, 226, 238, 250, 262, 273, 285, 297, 309, 321, 333, 344, 356, 368, 380, 392, 404, 415, 427, 437, 449, 461, 473, 485, 497, 508, 511, 525, 536, 545, 548, 556, 559, 567, 570, 578, 581, 590, 593, 602, 613, 625, 637, 649],
    "bhagautiastotr": [0],
    "bhagautiastotrhazoor": [0],
    "bhairo": [0, 139, 244, 314, 373, 483, 522, 543],
    "bihagrakivaarm4": [0, 12, 33, 48, 70, 82, 98, 114, 130, 148, 165, 179, 200, 214, 226, 244, 263, 278, 297, 315, 329],
    "bilaaval": [0, 14, 27, 38, 49, 56, 63, 70, 77, 84, 92, 101, 108, 117, 128, 137],
    "bilaavalkivaar": [0, 16, 35, 53, 72, 91, 106, 130, 151, 166, 183, 196, 217],
    "birharre": [0],
    "chandidivar": [0],
    "chaubole": [0],
    // "chaupai": [0, 5, 42, 154, 159, 165, 170],
    "chaupai": [0], // has diff in taksali/ BD mode
    "dhakhnioankar": [0, 12, 16, 20, 24, 28, 32, 40, 48, 56, 64, 68, 72, 80, 88, 96, 104, 112, 120, 128, 136, 145, 153, 161, 169, 177, 185, 194, 202, 210, 218, 226, 234, 242, 250, 254, 262, 270, 278, 287, 295, 303, 311, 319, 327, 335, 343, 351, 359, 367, 375, 383, 391, 395],
    "dhanasari": [0, 42, 99, 124, 142, 152, 159],
    "dukhbhanjani": [0, 12, 23, 34, 45, 56, 67, 74, 85, 96, 111, 118, 125, 132, 139, 146, 157, 164, 173, 180, 187, 194, 201, 208, 219, 226, 233, 240, 247, 254, 261, 268, 275, 282],
    "funhem5": [ 0, 6, 10, 14, 18, 22, 26, 30, 34, 38, 42, 46, 50, 54, 58, 62, 66, 70, 74, 78, 82, 86, 90],
    "gauri": [0, 14, 25, 36, 47, 58, 69, 80, 91, 102, 113, 124, 135, 146, 157, 170, 185, 200, 219, 228, 237, 246, 255, 264, 273, 281, 288, 297, 306, 315, 324, 332, 341, 350, 357, 364, 388, 395, 442, 451, 458, 475, 488, 499, 508, 517, 526, 539, 550, 563, 574, 585, 596, 607, 618, 629, 640, 651, 661, 671, 682, 691, 698, 705, 713, 720, 727, 734, 755, 764, 775, 943, 950, 1017, 1052, 1062, 1087, 1098, 1108],
    "gaurikivaarm4": [0, 15, 29, 41, 53, 69, 88, 111, 136, 160, 183, 204, 226, 254, 283, 318, 338, 358, 378, 397, 427, 449, 468, 484, 500, 516, 538, 640],
    "gaurikivaarm5": [0, 15, 27, 39, 51, 63, 75, 87, 99, 113, 125, 137, 149, 161, 173, 185, 206, 218, 230, 242, 256],
    "ghorrian": [0],
    "gond": [0, 13, 22, 52, 71, 90, 109, 131, 150, 169, 188, 206, 217, 224, 237, 258, 271, 283, 304],
    "gujri": [0, 14, 25, 40, 48, 63, 76, 88],
    "gujrikivaarm3": [0, 14, 31, 44, 60, 80, 94, 112, 130, 145, 165, 183, 204, 221, 238, 256, 273, 293, 314, 335, 348, 362],
    "gujrikivaarm5": [0, 18, 35, 50, 65, 80, 95, 110, 125, 140, 155, 170, 185, 200, 215, 230, 244, 259, 274, 289, 314],
    "gunvanti": [0],
    "jaap": [0, 120, 181, 248, 288, 342, 371, 410, 531, 602, 647, 688],
    "jaitsree": [0],
    "jaitsrikivar": [0, 9, 20, 31, 42, 53, 64, 75, 86, 97, 108, 119, 131, 142, 153, 164, 175, 186, 197, 208],
    "japji": [0, 16, 48, 60, 84, 108, 132, 171, 199, 241, 267, 299, 316, 335, 371, 378],
    "kaanra": [0],
    "kaanrekivaarm4": [0, 14, 30, 48, 69, 88, 105, 117, 131, 148, 163, 178, 190, 202, 217],
    "karhalai": [0],
    "kedaara": [0, 55],
    "kuchji": [0],
    "lavaa": [0, 8, 14, 20],
    "maajhkivaar": [0, 3, 38, 62, 81, 104, 125, 145, 171, 189, 215, 239, 259, 292, 331, 355, 378, 398, 424, 453, 475, 495, 512, 535, 553, 570, 585, 624],
    "maaligauri": [0],
    "maarookivaarm3": [0, 14, 34, 49, 63, 75, 87, 100, 112, 132, 148, 162, 176, 191, 208, 225, 242, 267, 280, 299, 311, 323],
    "maaru": [0, 62, 87, 92, 105, 116, 134, 143],
    "malaar": [0, 30, 39, 50, 59],
    "malaarkivaarm1": [0, 19, 34, 51, 66, 83, 100, 122, 145, 163, 183, 203, 222, 241, 256, 275, 293, 308, 329, 364, 390, 420, 445, 464, 494, 539, 554],
    "ogardanti": [0, 52, 100, 148, 196, 244, 294],
    "patteelikhee": [0],
    "patteem3": [0],
    "prabhaati": [0, 13, 28, 39, 50, 59, 72, 81, 92],
    "raagmala": [0],
    "ramkali": [0, 39, 129, 247, 280, 322, 333],
    "ramkalikivaarm3": [0, 24, 38, 56, 75, 93, 109, 129, 160, 181, 199, 247, 309, 331, 361, 375, 394, 410, 429, 456, 468],
    "ramkalikivaarm5": [0, 14, 33, 51, 75, 107, 136, 176, 205, 220, 241, 266, 291, 306, 321, 336, 351, 368, 386, 401, 416, 431],
    "ramkalikivar": [0, 10, 23, 35, 44, 53, 72, 81],
    // "rehras": [0, 11, 19, 44, 63, 82, 93, 104, 132, 151, 158, 169, 174, 214, 326, 331, 337, 340, 369, 372, 375, 378, 381, 390, 393, 396, 399, 404, 407, 410, 413, 416, 421, 426, 431, 436, 439, 448, 453, 458, 461, 496, 502, 507, 516, 522],
    "rehras": [0],
    "ruteem5": [0, 7, 14, 19, 26, 31, 38, 43, 50, 55, 62, 67, 74, 79, 86, 91],
    "saarang": [0, 24, 57],
    "sadd": [0],
    "salokfareed": [0, 33, 116, 166, 181, 184, 236, 239, 246, 249, 252, 255],
    "salokkabir": [0, 418, 421, 424, 431, 444, 447],
    "salokm9": [0, 106],
    "sarangkivaarm4": [0, 26, 46, 66, 84, 104, 127, 149, 167, 191, 208, 230, 247, 263, 279, 305, 326, 341, 355, 369, 387, 404, 426, 445, 463, 480, 492, 509, 524, 537, 552, 568, 593, 610, 633],
    "shabadhazare": [0, 18, 36, 50, 71, 82, 94],
    "shabadhazare10": [0, 12, 21, 30, 39, 48, 53, 62, 71, 80],
    "shastarnaammala": [0],
    "sidhgosht": [0, 8, 16, 24, 32, 40, 48, 56, 64, 72, 82, 94, 106, 118, 130, 142, 154, 172, 190, 202, 220, 232, 250, 268, 279, 291, 303, 321, 333, 345, 357, 369, 381, 393],
    "sirimukhbaakm1a": [0],
    "sirimukhbaakm1b": [0],
    "siriraagkivaar": [0, 14, 26, 40, 58, 73, 86, 103, 122, 146, 162, 184, 212, 229, 260, 272, 292, 308, 327, 342, 356],
    "sohila": [0], // has diff in taksali/ BD mode
    "soohee": [0, 63, 105],
    "soohikivaar": [0, 15, 31, 49, 67, 85, 102, 120, 133, 152, 168, 180, 194, 214, 230, 251, 265, 284, 296, 311],
    "sorat": [0, 33, 109, 149, 194, 265],
    "soratkivaarm4": [0, 19, 36, 57, 78, 92, 115, 130, 147, 164, 181, 197, 217, 237, 251, 263, 276, 292, 310, 326, 341, 359, 374, 392, 407, 425, 442, 462, 474],
    "sriraag": [0, 14, 28, 39, 65],
    "suchji": [0],
    "sukhmana": [0, 21, 40, 59, 78, 97, 116, 137, 156, 175, 194, 213, 232, 253, 272, 291, 310, 329, 348, 369, 388, 407, 426, 445],
    "sukhmani": [0, 91, 175, 259, 342, 425, 509, 594, 679, 765, 849, 933, 1017, 1101, 1185, 1267, 1350, 1434, 1516, 1600, 1684, 1768, 1852, 1936],
    "svaiye": [0],
    "svaiyedeenan": [0],
    "svaiyem1": [0],
    "svaiyem2": [0],
    "svaiyem3": [0],
    "svaiyem4": [0],
    "svaiyem5": [0, 53],
    "thitteekabirjee": [0, 7],
    "thitteem1": [0],
    "thitteem5": [0, 6, 17, 20, 29, 32, 41, 44, 53, 56, 65, 68, 77, 80, 89, 92, 101, 104, 113, 116, 125, 128, 137, 140, 149, 152, 163, 166, 175, 178, 186, 189, 198, 201],
    "tilang": [0],
    "toddee": [0],
    "vaarkabirjee": [0, 4, 8, 12, 16, 20, 24, 28],
    "vaarmaroodakhnem5": [0, 12, 30, 48, 66, 84, 102, 120, 138, 156, 174, 192, 210, 228, 246, 264, 282, 300, 318, 336, 354, 373, 392],
    "vaarsat": [0, 3, 11, 17, 23, 35, 41, 46],
    "vadhanskeevaarm4": [0, 15, 31, 53, 77, 99, 118, 134, 151, 170, 184, 201, 214, 228, 244, 264, 281, 297, 317, 333, 345],
    "vanjaara": [0],
]

/// Call this once to generate partitions for all banis, then copy output to bani_partitions
func generateBaniPartitions(from baniResponse: BaniResponse) -> [Int] {
    var partitions = [0] // Always start with 0

    for (index, baniVerse) in baniResponse.verses.enumerated() {
        // header > 0 indicates a section header (like Salok, Ashtpadi, Pauri, etc)
        if baniVerse.header > 0, index > 0 {
            partitions.append(index)
        }
    }

    return partitions
}

/// Helper to generate all partitions and print them for copying
func printAllBaniPartitions() {
    let baniFiles = [
        "japji", "jaap", "svaiye", "chaupai", "anand", "sukhmani", "rehras", "sohila",
        "asadivar", "bavanakhree", "sidhgosht", "dhakhnioankar", "ogardanti", "akalustat",
        // Add all other bani filenames from BaniData folder...
    ]

    print("// Auto-generated Bani Partitions:")
    print("let bani_partitions: [String: [Int]] = [")

    for filename in baniFiles {
        if let baniData: BaniResponse = loadJSON(from: filename, as: BaniResponse.self) {
            let partitions = generateBaniPartitions(from: baniData)
            print("    \"\(filename)\": \(partitions),")
        }
    }

    print("]")
}

struct BaniSettingsSheet: View {
    let hasRecensionVariation: Bool

    @AppStorage("fontType") private var fontType: String = "Unicode"

    @AppStorage("bani.textScale") private var textScale: Double = 1.0
    @AppStorage("bani.visraamSource") private var selectedVisraamSource: String = "igurbani"
    @AppStorage("bani.englishSource") private var selectedEnglishSource: String = "none"
    @AppStorage("bani.punjabiSource") private var selectedPunjabiSource: String = "none"
    @AppStorage("bani.hindiSource") private var selectedHindiSource: String = "none"
    @AppStorage("bani.englishTranslationTextScale") private var enTransTextScale: Double = 1.0
    @AppStorage("bani.punjabiTranslationTextScale") private var punjabiTransTextScale: Double = 1.0
    @AppStorage("bani.hindiTranslationTextScale") private var hindiTransTextScale: Double = 1.0
    @AppStorage("bani.transliterationSource") private var selectedTransliterationSource: String = "none"
    @AppStorage("bani.transliterationTextScale") private var transliterationTextScale: Double = 1.0
    @AppStorage("bani.paragraphMode") private var isParagraphMode: Bool = false
    @AppStorage("bani.enableSections") private var enableSections: Bool = true
    @AppStorage("bani.recension") private var selectedRecension: String = "SGPC"
    @AppStorage("bani.mangalPosition") private var selectedMangalPosition: String = "current"

    private let visraamSources = ["none", "sttm", "igurbani", "sttm2"]
    private let mangalPositionOptions = ["above", "current"]
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
    private let transliterationSources: [(name: String, value: String)] = [
        ("None", "none"),
        ("English", "en"),
        ("Hindi", "hi"),
        ("IPA", "ipa"),
        ("Urdu", "ur"),
    ]
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
                            HStack {
                                Text("Paragraph Mode")
                                    .font(.subheadline)
                                Spacer()
                                Toggle("", isOn: $isParagraphMode)
                                    .labelsHidden()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .background(Color(.systemBackground))

                            Divider().padding(.leading)
                            HStack {
                                Text("Enable Sections")
                                    .font(.subheadline)
                                Spacer()
                                Toggle("", isOn: $enableSections)
                                    .labelsHidden()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .background(Color(.systemBackground))

                            // Recension Filter (only show if there's variation)
                            if hasRecensionVariation {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Bani Version")
                                        .font(.subheadline)
                                        .padding(.horizontal)
                                        .padding(.top, 10)

                                    Picker("Recension", selection: $selectedRecension) {
                                        Text("SGPC").tag("sgpc")
                                        Text("Medium").tag("medium")
                                        Text("Taksal").tag("taksal")
                                        Text("Buddha Dal").tag("buddhaDal")
                                    }
                                    .pickerStyle(.segmented)
                                    .padding(.horizontal)
                                    .padding(.bottom, 10)
                                }
                                .background(Color(.systemBackground))
                            }

                            Divider().padding(.leading)

                            // Mangal Position Filter
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Mangal Position")
                                    .font(.subheadline)
                                    .padding(.horizontal)
                                    .padding(.top, 10)

                                Picker("Mangal Position", selection: $selectedMangalPosition) {
                                    Text("Above").tag("above")
                                    Text("Current").tag("current")
                                }
                                .pickerStyle(.segmented)
                                .padding(.horizontal)
                                .padding(.bottom, 10)
                            }
                            .background(Color(.systemBackground))
                            Divider().padding(.leading)

                            SettingsOptionPickerSlider(title: "Gurbani Font", selectedItem: .constant(""), options: [], textScale: $textScale)
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

                            SettingsOptionPickerSlider(title: "Punjabi", selectedItem: $selectedPunjabiSource, options: punjabiSources, textScale: $punjabiTransTextScale)

                            Divider().padding(.leading)

                            SettingsOptionPickerSlider(title: "Hindi", selectedItem: $selectedHindiSource, options: hindiSources, textScale: $hindiTransTextScale)
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Bani Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct BaniVerseView: View {
    let verse: BaniVerse
    @Binding var preSelectedLineIdForCopy: Int
    @Binding var showCopySheet: Bool

    // Settings passed as bindings to avoid duplicate @AppStorage subscriptions
    @Binding var globalLarivaarOn: Bool
    @Binding var larivaarAssist: Bool
    @Binding var fontType: String
    @Binding var textScale: Double
    @Binding var selectedVisraamSource: String
    @Binding var selectedTransliterationSource: String
    @Binding var selectedEnglishSource: String
    @Binding var selectedPunjabiSource: String
    @Binding var selectedHindiSource: String
    @Binding var transliterationTextScale: Double
    @Binding var enTransTextScale: Double
    @Binding var punjabiTransTextScale: Double
    @Binding var hindiTransTextScale: Double

    @State private var localLarivaar: Bool = false
    @State private var showDefinitionsSheet: Bool = false

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading) {
            Text(AttributedString(formattedGurbaniAttributedString))
                .font(resolveFont(size: 20 * textScale, fontType: fontType))
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        localLarivaar.toggle()
                    }
                }
                .onLongPressGesture {
                    showDefinitionsSheet = true
                }

            // Transliteration
            if selectedTransliterationSource != "none", let transliteration = getTransliteration() {
                Text(transliteration)
                    .font(.system(size: 14 * transliterationTextScale))
                    .foregroundColor(AppColors.transliterationColor(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // English Translation
            if let englishTrans = verse.verse.translation.getTranslation(for: "english", source: selectedEnglishSource) {
                Text(englishTrans)
                    .font(.system(size: 14 * enTransTextScale))
                    .foregroundColor(AppColors.englishTranslationColor(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Punjabi Translation
            if let punjabiTrans = verse.verse.translation.getTranslation(for: "punjabi", source: selectedPunjabiSource) {
                Text(punjabiTrans)
                    .font(.system(size: 14 * punjabiTransTextScale))
                    .foregroundColor(AppColors.punjabiTranslationColor(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Hindi Translation
            if let hindiTrans = verse.verse.translation.getTranslation(for: "hindi", source: selectedHindiSource) {
                Text(hindiTrans)
                    .font(.system(size: 14 * hindiTransTextScale))
                    .foregroundColor(AppColors.hindiTranslationColor(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onAppear {
            localLarivaar = globalLarivaarOn
        }
        .onChange(of: globalLarivaarOn) { _, newValue in
            localLarivaar = newValue
        }
        .sheet(isPresented: $showDefinitionsSheet) {
            WordDefinitionsSheet(
                verse: verse.verse,
                preSelectedLineIdForCopy: Binding(
                    get: { nil },
                    set: { newValue in
                        if let id = newValue?.id {
                            preSelectedLineIdForCopy = id
                            showCopySheet = true
                        }
                    }
                )
            )
        }
    }

    private func getTransliteration() -> String? {
        switch selectedTransliterationSource {
        case "en": return verse.verse.transliteration.en
        case "hi": return verse.verse.transliteration.hi
        case "ipa": return verse.verse.transliteration.ipa
        case "ur": return verse.verse.transliteration.ur
        default: return nil
        }
    }

    private var formattedGurbaniAttributedString: NSAttributedString {
        let text = fontType == "Unicode" ? verse.verse.verse.unicode : verse.verse.verse.gurmukhi
        let words = text.components(separatedBy: " ")

        // Get visraam points
        var visraamPoints: [Int: String] = [:]
        if selectedVisraamSource != "none", let visraam = verse.verse.visraam {
            let selectedVisraamData: [Visraam.VisraamPoint]
            switch selectedVisraamSource {
            case "sttm": selectedVisraamData = visraam.sttm ?? []
            case "sttm2": selectedVisraamData = visraam.sttm2 ?? []
            case "igurbani": selectedVisraamData = visraam.igurbani ?? []
            default: selectedVisraamData = []
            }
            for point in selectedVisraamData {
                visraamPoints[point.p] = point.t
            }
        }

        let result = NSMutableAttributedString()
        for (index, word) in words.enumerated() {
            let color: UIColor

            // Visraam coloring takes priority
            if let visraamType = visraamPoints[index] {
                color = UIColor(AppColors.visraamColor(type: visraamType, for: colorScheme))
            } else if larivaarAssist && localLarivaar {
                // Larivaar assist ONLY applies when IN larivaar mode (no spaces)
                color = UIColor(AppColors.larivaarAssistColor(index: index, for: colorScheme))
            } else {
                color = colorScheme == .dark ? .white : .black
            }

            let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: color]
            result.append(NSAttributedString(string: word, attributes: attributes))

            // Add space between words unless in larivaar mode
            if index < words.count - 1 && !localLarivaar {
                result.append(NSAttributedString(string: " "))
            }
        }

        return result
    }
}

// MARK: - Bani Meta Info Sheet

struct BaniMetaInfoSheet: View {
    let info: BaniInfo

    private let labelFont = Font.caption2.weight(.semibold)
    private let valueFont = Font.caption2

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 8) {
                    Text("Bani Info — Full Metadata")
                        .font(.subheadline).bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 2)

                    ForEach(chunkedPairs, id: \.0) { _, pairTuple in
                        HStack(alignment: .top, spacing: 12) {
                            PairView(label: pairTuple.0.label, value: pairTuple.0.value,
                                     labelFont: labelFont, valueFont: valueFont)

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
            .navigationTitle("Bani Info")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

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
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        }
    }

    private var allPairs: [(label: String, value: String)] {
        let items: [(String, String?)] = [
            ("baniID", "\(info.baniID)"),
            ("gurmukhi", info.gurmukhi),
            ("unicode", info.unicode),
            ("english", info.english),
            ("hindi", info.hindi),
            ("en (transliteration)", info.en),
            ("hi (transliteration)", info.hi),
            ("ipa", info.ipa),
            ("ur", info.ur),

            // Source
            ("source.sourceId", info.source?.sourceId),
            ("source.gurmukhi", info.source?.gurmukhi),
            ("source.unicode", info.source?.unicode),
            ("source.english", info.source?.english),
            ("source.pageNo", info.source?.pageNo.map { "\($0)" }),

            // Raag
            ("raag.raagId", info.raag?.raagId.map { "\($0)" }),
            ("raag.gurmukhi", info.raag?.gurmukhi),
            ("raag.unicode", info.raag?.unicode),
            ("raag.english", info.raag?.english),
            ("raag.raagWithPage", info.raag?.raagWithPage),

            // Writer
            ("writer.writerId", info.writer?.writerId.map { "\($0)" }),
            ("writer.gurmukhi", info.writer?.gurmukhi),
            ("writer.unicode", info.writer?.unicode),
            ("writer.english", info.writer?.english),
        ]

        return items.map { label, raw in
            let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return (label: label, value: trimmed.isEmpty ? "None" : trimmed)
        }
    }

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

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Auto Scroll View

struct AutoScrollView<Content: View>: UIViewControllerRepresentable {
    @Binding var controller: AutoScrollViewController<Content>?
    let content: () -> Content

    func makeUIViewController(context _: Context) -> AutoScrollViewController<Content> {
        let viewController = AutoScrollViewController(content: content())
        DispatchQueue.main.async {
            controller = viewController
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: AutoScrollViewController<Content>, context _: Context) {
        uiViewController.updateContent(content: content())
    }
}

class AutoScrollViewController<Content: View>: UIViewController, UIScrollViewDelegate {
    private var hostingController: UIHostingController<Content>
    private var scrollView: UIScrollView
    private var scrollTimer: Timer?
    private(set) var isPaused = false
    private var scrollSpeed: Double = 30.0
    var onScrollEnd: (() -> Void)?

    init(content: Content) {
        hostingController = UIHostingController(rootView: content)
        scrollView = UIScrollView()
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.delegate = self
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = false

        // Remove extra insets and offsets
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
        scrollView.contentOffset = .zero

        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = true
        scrollView.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        view.addSubview(scrollView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let width = scrollView.bounds.width
        guard width > 0 else { return }

        let size = hostingController.sizeThatFits(in: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        hostingController.view.frame = CGRect(x: 0, y: 0, width: width, height: size.height)
        scrollView.contentSize = CGSize(width: width, height: size.height)
    }

    func updateContent(content: Content) {
        hostingController.rootView = content
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    func scrollToTop() {
        scrollView.setContentOffset(.zero, animated: true)
    }

    func startScrolling(speed: Double) {
        stopScrolling() // Stop any existing timer
        scrollSpeed = speed
        isPaused = false

        // Timer fires every 50ms for smooth scrolling
        scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, !self.isPaused else { return }

            let currentOffset = self.scrollView.contentOffset.y
            let maxOffset = max(0, self.scrollView.contentSize.height - self.scrollView.bounds.height)

            // Calculate scroll amount: speed (pts/sec) * 0.05 (sec)
            let scrollAmount = self.scrollSpeed * 0.05

            let newOffset = min(currentOffset + scrollAmount, maxOffset)

            // Stop at the end
            if newOffset >= maxOffset {
                self.stopScrolling()
                self.onScrollEnd?()
                return
            }

            self.scrollView.setContentOffset(CGPoint(x: 0, y: newOffset), animated: false)
        }
    }

    func stopScrolling() {
        scrollTimer?.invalidate()
        scrollTimer = nil
        isPaused = false
    }

    func pauseScrolling() {
        isPaused = true
    }

    func resumeScrolling() {
        isPaused = false
    }

    func setScrollSpeed(_ speed: Double) {
        scrollSpeed = speed
    }
}
