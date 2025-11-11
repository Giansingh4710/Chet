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

    @AppStorage("settings.larivaarOn") private var larivaarOn: Bool = true
    @AppStorage("settings.larivaarAssist") private var larivaarAssist: Bool = false

    // Bani-specific settings (separate from ShabadView)
    @AppStorage("bani.textScale") private var textScale: Double = 1.0
    @AppStorage("bani.fontType") private var fontType: String = "Unicode"
    @AppStorage("bani.visraamSource") private var selectedVisraamSource = "igurbani"
    @AppStorage("bani.englishSource") private var selectedEnglishSource = "bdb"
    @AppStorage("bani.punjabiSource") private var selectedPunjabiSource = "none"
    @AppStorage("bani.hindiSource") private var selectedHindiSource = "none"
    @AppStorage("bani.transliterationSource") private var selectedTransliterationSource = "none"
    @AppStorage("bani.englishTranslationTextScale") private var enTransTextScale: Double = 1.0
    @AppStorage("bani.punjabiTranslationTextScale") private var punjabiTransTextScale: Double = 1.0
    @AppStorage("bani.hindiTranslationTextScale") private var hindiTransTextScale: Double = 1.0
    @AppStorage("bani.transliterationTextScale") private var transliterationTextScale: Double = 1.0
    @AppStorage("bani.paragraphMode") private var isParagraphMode: Bool = true
    @AppStorage("bani.recension") private var selectedRecension: String = "taksal"

    @Environment(\.colorScheme) var colorScheme

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
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 24) {
                            // Show section info if partitions exist
                            if !partitionIndexes.isEmpty {
                                HStack {
                                    Spacer()
                                    Text("Section \(currentSectionIndex + 1) of \(partitionIndexes.count)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.bottom, 4)
                            }

                            // Show either paragraph mode or line mode
                            if isParagraphMode {
                                paragraphView(verses: getCurrentSectionVerses())
                            } else {
                                lineView(verses: getCurrentSectionVerses())
                            }
                        }
                        .padding(.bottom, 30)
                    }
                    .background(colorScheme == .dark ? Color.black : Color.white)
                    .onChange(of: currentSectionIndex) { _, _ in
                        withAnimation {
                            proxy.scrollTo("top", anchor: .top)
                        }
                    }
                }
            }
        }
        .navigationTitle(baniTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Section navigation menu (leading)
            // Previous/Next section buttons (bottom bar)
            ToolbarItemGroup(placement: .bottomBar) {
                if !partitionIndexes.isEmpty {
                    Button(action: goToPreviousSection) {
                        Label("Previous", systemImage: "chevron.left")
                    }
                    .disabled(!canGoPrevious)

                    Spacer()

                    Text(getSectionTitle(for: currentSectionIndex))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Spacer()

                    Button(action: goToNextSection) {
                        Label("Next", systemImage: "chevron.right")
                    }
                    .disabled(!canGoNext)
                }
            }

            // Settings button (trailing)
            ToolbarItem(placement: .navigationBarTrailing) {
                if !partitionIndexes.isEmpty {
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
                        Label("Sections", systemImage: "list.bullet")
                    }
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                }
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
            MagnificationGesture()
                .onChanged { value in
                    gestureScale = value
                }
                .onEnded { _ in
                    textScale *= gestureScale
                    gestureScale = 1.0
                }
        )
        .onAppear {
            loadBani()
        }
    }

    private func loadBani() {
        guard let url = Bundle.main.url(forResource: baniFilename, withExtension: "json") else {
            errorMessage = "Bani file '\(baniFilename)' not found"
            isLoading = false
            return
        }

        do {
            let data = try Data(contentsOf: url)
            baniData = try JSONDecoder().decode(BaniResponse.self, from: data)
            isLoading = false
        } catch {
            errorMessage = "Failed to load bani: \(error.localizedDescription)"
            print("❌ JSON Decode Error: \(error)")
            isLoading = false
        }
    }

    // MARK: - Section Navigation Helpers

    /// Get the verses for the current section
    private func getCurrentSectionVerses() -> [BaniVerse] {
        guard let baniData = baniData else { return [] }

        // Get section verses
        let sectionVerses: [BaniVerse]
        if partitionIndexes.isEmpty {
            // No partitions, use all verses
            sectionVerses = baniData.verses
        } else {
            // Get start index for current section
            let startIndex = partitionIndexes[currentSectionIndex]

            // Get end index (either next partition or end of verses)
            let endIndex: Int
            if currentSectionIndex < partitionIndexes.count - 1 {
                endIndex = partitionIndexes[currentSectionIndex + 1]
            } else {
                endIndex = baniData.verses.count
            }

            // Get verses in range
            sectionVerses = Array(baniData.verses[startIndex ..< endIndex])
        }

        // Apply recension filter
        switch selectedRecension {
        case "sgpc":
            return sectionVerses.filter { $0.existsSGPC == 1 }
        case "medium":
            return sectionVerses.filter { $0.existsMedium == 1 }
        case "buddhaDal":
            return sectionVerses.filter { $0.existsBuddhaDal == 1 }
        default: // "taksal" (default)
            return sectionVerses.filter { $0.existsTaksal == 1 }
        }
    }

    /// Get section title for display
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
        if title.count > 30 {
            return String(title.prefix(30)) + "..."
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

    /// Navigate to next section
    private func goToNextSection() {
        if canGoNext {
            currentSectionIndex += 1
        }
    }

    private func lineView(verses: [BaniVerse]) -> some View {
        let paragraphs = groupVersesByParagraph(verses)

        return ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(paragraph) { baniVerse in
                        renderGurbaniLine(baniVerse.verse)
                            .font(resolveFont(size: 22 * textScale * gestureScale, fontType: fontType))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                larivaarOn.toggle()
                            }
                            .onLongPressGesture {
                                preSelectedLineIdForCopy = baniVerse.verse.verseId
                                selectedVerse = baniVerse.verse
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    showWordDefinitions = true
                                }
                            }
                    }
                }
                .padding(.horizontal, 2)

                // Combined Transliteration paragraph (if enabled)
                if selectedTransliterationSource != "none" {
                    let transliterationText = paragraph.compactMap {
                        $0.verse.transliteration.value(for: selectedTransliterationSource)
                    }.joined(separator: " ")

                    if !transliterationText.isEmpty {
                        Text(transliterationText)
                            .font(.system(size: 16 * transliterationTextScale * gestureScale, design: .monospaced))
                            .foregroundColor(colorScheme == .dark ? Color(red: 0.75, green: 0.75, blue: 0.75) : Color(red: 0.5, green: 0.5, blue: 0.5))
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 2)
                    }
                }

                // Combined English Translation paragraph (if enabled)
                if selectedEnglishSource != "none" {
                    let translationText = paragraph.compactMap {
                        $0.verse.translation.getTranslation(for: "english", source: selectedEnglishSource)
                    }.joined(separator: " ")

                    if !translationText.isEmpty {
                        Text(translationText)
                            .font(.system(size: 16 * enTransTextScale * gestureScale))
                            .foregroundColor(.secondary)
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // Combined Punjabi Translation paragraph (if enabled)
                if selectedPunjabiSource != "none" {
                    let translationText = paragraph.compactMap {
                        $0.verse.translation.getTranslation(for: "punjabi", source: selectedPunjabiSource)
                    }.joined(separator: " ")

                    if !translationText.isEmpty {
                        Text(translationText)
                            .font(.system(size: 16 * punjabiTransTextScale * gestureScale))
                            .foregroundColor(.secondary)
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // Combined Hindi Translation paragraph (if enabled)
                if selectedHindiSource != "none" {
                    let translationText = paragraph.compactMap {
                        $0.verse.translation.getTranslation(for: "hindi", source: selectedHindiSource)
                    }.joined(separator: " ")

                    if !translationText.isEmpty {
                        Text(translationText)
                            .font(.system(size: 16 * hindiTransTextScale * gestureScale))
                            .foregroundColor(.secondary)
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color(.systemGray6).opacity(0.5))
            )
        }
    }

    private func paragraphView(verses: [BaniVerse]) -> some View {
        let paragraphs = groupVersesByParagraph(verses)

        return ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
            VStack(alignment: .leading, spacing: 6) {
                // --- Gurbani Paragraph ---
                renderParagraph(paragraph: paragraph)
                    .font(resolveFont(size: 22 * textScale * gestureScale, fontType: fontType))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        larivaarOn.toggle()
                    }

                // --- Transliteration ---
                if selectedTransliterationSource != "none" {
                    let transliterationText = paragraph.compactMap {
                        $0.verse.transliteration.value(for: selectedTransliterationSource)
                    }.joined(separator: " ")

                    if !transliterationText.isEmpty {
                        Text(transliterationText)
                            .font(.system(size: 16 * transliterationTextScale * gestureScale, design: .monospaced))
                            .foregroundColor(colorScheme == .dark ? Color(red: 0.75, green: 0.75, blue: 0.75) : Color(red: 0.5, green: 0.5, blue: 0.5))
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 2)
                    }
                }

                // --- English Translation ---
                if selectedEnglishSource != "none" {
                    let translationText = paragraph.compactMap {
                        $0.verse.translation.getTranslation(for: "english", source: selectedEnglishSource)
                    }.joined(separator: " ")

                    if !translationText.isEmpty {
                        Text(translationText)
                            .font(.system(size: 16 * enTransTextScale * gestureScale))
                            .foregroundColor(.secondary)
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // --- Punjabi Translation ---
                if selectedPunjabiSource != "none" {
                    let translationText = paragraph.compactMap {
                        $0.verse.translation.getTranslation(for: "punjabi", source: selectedPunjabiSource)
                    }.joined(separator: " ")

                    if !translationText.isEmpty {
                        Text(translationText)
                            .font(.system(size: 16 * punjabiTransTextScale * gestureScale))
                            .foregroundColor(.secondary)
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // --- Hindi Translation ---
                if selectedHindiSource != "none" {
                    let translationText = paragraph.compactMap {
                        $0.verse.translation.getTranslation(for: "hindi", source: selectedHindiSource)
                    }.joined(separator: " ")

                    if !translationText.isEmpty {
                        Text(translationText)
                            .font(.system(size: 16 * hindiTransTextScale * gestureScale))
                            .foregroundColor(.secondary)
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color(.systemGray6).opacity(0.5))
            )
        }
    }

    private func renderParagraph(paragraph: [BaniVerse]) -> Text {
        var result = Text("")

        for (verseIndex, baniVerse) in paragraph.enumerated() {
            let words = baniVerse.verse.verse.gurmukhi.components(separatedBy: " ")

            var visraamPoints: [Int: String] = [:] // [position: type]
            if let visraam = baniVerse.verse.visraam {
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

            for (index, word) in words.enumerated() {
                let color: Color

                if let visraamType = visraamPoints[index] {
                    switch visraamType {
                    case "v":
                        color = colorScheme == .dark ? Color(red: 1.0, green: 0.5, blue: 0.3) : Color(red: 0.9, green: 0.2, blue: 0.0)
                    case "y":
                        color = colorScheme == .dark ? Color(red: 0.3, green: 1.0, blue: 0.3) : Color(red: 0.0, green: 0.7, blue: 0.0)
                    default:
                        color = .primary
                    }
                } else if larivaarAssist {
                    let isEvenWord = index % 2 == 0
                    color = isEvenWord
                        ? (colorScheme == .dark ? Color(red: 0.75, green: 0.85, blue: 1.0) : Color(red: 0.05, green: 0.25, blue: 0.55))
                        : (colorScheme == .dark ? Color(red: 1.0, green: 0.8, blue: 0.65) : Color(red: 0.55, green: 0.35, blue: 0.05))
                } else {
                    color = .primary
                }

                result = result + Text(word).foregroundColor(color)

                // Add a space after each word unless it's the last in the paragraph
                if verseIndex != paragraph.count - 1 || index < words.count - 1 {
                    result = result + Text(" ")
                }
            }
        }

        return result
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

    private func renderGurbaniLine(_ verse: Verse) -> Text {
        // let isLarivaarMode = lineLarivaar
        let isLarivaarMode = larivaarOn || larivaarAssist
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
                switch visraamType {
                case "v": // small pause
                    color = colorScheme == .dark ? Color(red: 1.0, green: 0.5, blue: 0.3) : Color(red: 0.9, green: 0.2, blue: 0.0)
                case "y": // big pause
                    color = colorScheme == .dark ? Color(red: 0.3, green: 1.0, blue: 0.3) : Color(red: 0.0, green: 0.7, blue: 0.0)
                default:
                    color = .primary
                }
            } else if larivaarAssist {
                let isEvenWord = index % 2 == 0
                color = isEvenWord
                    ? (colorScheme == .dark
                        ? Color(red: 0.75, green: 0.85, blue: 1.0) // soft sky blue
                        : Color(red: 0.05, green: 0.25, blue: 0.55)) // muted navy
                    : (colorScheme == .dark
                        ? Color(red: 1.0, green: 0.8, blue: 0.65) // warm apricot
                        : Color(red: 0.55, green: 0.35, blue: 0.05)) // amber brown
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

let bani_title_to_filename: [String: String] = [
    "ਰਾਗੁ ਬਿਲਾਵਲੁ": "bilaaval",
    "ਰਾਗੁ ਬਸੰਤੁ": "basant",
    "ਰਾਗੁ ਆਸਾ": "aasa",
    "ਬਾਰਹ ਮਾਹਾ ਮਾਂਝ": "baarehmaha",
    "ਗੂਜਰੀ ਕੀ ਵਾਰ ਮਹਲਾ ੩": "gujrikivaarm3",
    "ਰਾਗੁ ਸੋਰਠਿ": "sorat",
    "ਰਾਗੁ ਗੋਂਡ": "gond",
    "ਫੁਨਹੇ ਮਹਲਾ ੫": "funhem5",
    "ਸਲੋਕ ਸੇਖ ਫਰੀਦ ਕੇ": "salokfareed",
    "ਗੁਣਵੰਤੀ": "gunvanti",
    "ਅਥ ਚੰਡੀਚਰਿਤ੍ਰ": "athchandichariter",
    "ਅਰਦਾਸ": "ardas",
    "ਵਣਜਾਰਾ": "vanjaara",
    "ਕੁਚਜੀ": "kuchji",
    "ਰਾਗੁ ਗਉੜੀ": "gauri",
    "ਬਾਵਨ ਅਖਰੀ ਕਬੀਰ ਜੀਉ ਕੀ": "baavanakhrikabirjee",
    "ਰਾਗੁ ਮਾਲੀ ਗਉੜਾ": "maaligauri",
    "ਸੁਚਜੀ": "suchji",
    "ਥਿਤੰੀ ਕਬੀਰ ਜੀ ਕੰੀ": "thitteekabirjee",
    "ਸੁਖਮਨੀ ਸਾਹਿਬ": "sukhmani",
    "ਰਾਮਕਲੀ ਕੀ ਵਾਰ ਮਹਲਾ ੩": "ramkalikivaarm3",
    "ਬੇਨਤੀ ਚੌਪਈ ਸਾਹਿਬ": "chaupai",
    "ਮਾਰੂ ਵਾਰ ਮਹਲਾ ੫ ਡਖਣੇ": "vaarmaroodakhnem5",
    "ਰਾਗੁ ਜੈਤਸਰੀ": "jaitsree",
    "ਕਰਹਲੇ": "karhalai",
    "ਰਾਗੁ ਮਲਾਰ": "malaar",
    "ਮਹਲਾ ੫ ਰੁਤੀ": "ruteem5",
    "ਸਲੋਕ ਭਗਤ ਕਬੀਰ ਜੀਉ ਕੇ": "salokkabir",
    "ਰਾਗੁ ਸਿਰੀਰਾਗੁ (ਕਬੀਰ ਜੀਉ ਕਾ)": "sriraag",
    "ਬਾਰਹ ਮਾਹਾ ਸਵੈਯਾ": "baarehmahasvaye",
    "ਸ਼ਬਦ ਹਜ਼ਾਰੇ ਪਾਤਿਸ਼ਾਹੀ ੧੦": "shabadhazare10",
    "ਸਵਈਏ ਮਹਲੇ ਪਹਿਲੇ ਕੇ": "svaiyem1",
    "ਅਕਾਲ ਉਸਤਤ ਚੌਪਈ": "akaalustatchaupai",
    "ਰਾਗੁ ਕੇਦਾਰਾ": "kedaara",
    "ਸਾਰੰਗ ਕੀ ਵਾਰ ਮਹਲਾ ੪": "sarangkivaarm4",
    "ਸਿਧ ਗੋਸਟਿ": "sidhgosht",
    "ਰਾਗੁ ਗੂਜਰੀ ਵਾਰ ਮਹਲਾ ੫": "gujrikivaarm5",
    "ਥਿਤੀ ਮਹਲਾ ੧": "thitteem1",
    "ਰਾਮਕਲੀ ਕੀ ਵਾਰ ਮਹਲਾ ੫": "ramkalikivaarm5",
    "ਪਟੀ ਲਿਖੀ": "patteelikhee",
    "ਅਕਾਲ ਉਸਤਤ": "akalustat",
    "ਸਵਯੇ ਸ੍ਰੀ ਮੁਖਬਾਕੵ ਮਹਲਾ ੫ - ੨": "sirimukhbaakm1b",
    "ਵਡਹੰਸ ਕੀ ਵਾਰ ਮਹਲਾ ੪": "vadhanskeevaarm4",
    "ਗਉੜੀ ਵਾਰ ਕਬੀਰ ਜੀਉ ਕੇ": "vaarkabirjee",
    "ਸ੍ਰੀ ਭਗਉਤੀ ਅਸਤੋਤ੍ਰ (ਪੰਥ ਪ੍ਰਕਾਸ਼)": "bhagautiastotr",
    "ਆਸਾ ਦੀ ਵਾਰ": "asadivar",
    "ਸ਼ਸਤ੍ਰ ਨਾਮ ਮਾਲਾ": "shastarnaammala",
    "ਰਾਗੁ ਸਾਰੰਗ": "saarang",
    "ਜਾਪੁ ਸਾਹਿਬ": "jaap",
    "ਬਿਲਾਵਲੁ ਕੀ ਵਾਰ ਮਹਲਾ ੪": "bilaavalkivaar",
    "ਰਾਗੁ ਤਿਲੰਗ (ਬਾਣੀ ਭਗਤਾ ਕੀ ਕਬੀਰ ਜੀ)": "tilang",
    "ਦਖਣੀ ਓਅੰਕਾਰੁ": "dhakhnioankar",
    "ਦੁਖ ਭੰਜਨੀ ਸਾਹਿਬ": "dukhbhanjani",
    "ਬਸੰਤ ਕੀ ਵਾਰ": "basantkivar",
    "ਸਵਈਏ ਮਹਲੇ ਤੀਜੇ ਕੇ": "svaiyem3",
    "ਰਾਗੁ ਧਨਾਸਰੀ": "dhanasari",
    "ਵਾਰ ਮਲਾਰ ਕੀ ਮਹਲਾ ੧": "malaarkivaarm1",
    "ਗਉੜੀ ਕੀ ਵਾਰ ਮਹਲਾ ੫": "gaurikivaarm5",
    "ਬਿਰਹੜੇ": "birharre",
    "ਰਾਗੁ ਟੋਡੀ (ਬਾਣੀ ਭਗਤਾਂ ਕੀ)": "toddee",
    "ਰਾਗੁ ਰਾਮਕਲੀ (ਸਦੁ)": "ramkali",
    "ਰਾਗੁ ਮਾਰੂ": "maaru",
    "ਰਾਮਕਲੀ ਕੀ ਵਾਰ (ਰਾਇ ਬਲਵੰਡਿ ਤਥਾ ਸਤੈ)": "ramkalikivar",
    "ਚੰਡੀ ਦੀ ਵਾਰ": "chandidivar",
    "ਰਾਗੁ ਸੂਹੀ": "soohee",
    "ਸਲੋਕ ਮਹਲਾ ੯": "salokm9",
    "ਸੋਹਿਲਾ ਸਾਹਿਬ": "sohila",
    "ਸਵਯੇ ਸ੍ਰੀ ਮੁਖਬਾਕੵ ਮਹਲਾ ੫ - ੧": "sirimukhbaakm1a",
    "ਸ਼ਬਦ ਹਜ਼ਾਰੇ": "shabadhazare",
    "ਰਹਰਾਸਿ ਸਾਹਿਬ": "rehras",
    "ਤ੍ਵ ਪ੍ਰਸਾਦਿ ਸਵੱਯੇ (ਸ੍ਰਾਵਗ ਸੁੱਧ)": "svaiye",
    "ਰਾਗੁ ਪ੍ਰਭਾਤੀ": "prabhaati",
    "ਆਰਤੀ": "aarti",
    "ਸੁਖਮਨਾ ਸਾਹਿਬ": "sukhmana",
    "ਗਉੜੀ ਕੀ ਵਾਰ ਮਹਲਾ ੪": "gaurikivaarm4",
    "ਘੋੜੀਆ": "ghorrian",
    "ਬਿਹਾਗੜੇ ਕੀ ਵਾਰ ਮਹਲਾ ੪": "bihagrakivaarm4",
    "ਸਵਈਏ ਮਹਲੇ ਦੂਜੇ ਕੇ": "svaiyem2",
    "ਅਨੰਦੁ ਸਾਹਿਬ": "anand",
    "ਲਾਵਾਂ": "lavaa",
    "ਰਾਗੁ ਗੂਜਰੀ": "gujri",
    "ਬਾਵਨ ਅਖਰੀ": "bavanakhree",
    "ਰਾਮਕਲੀ ਸਦੁ": "sadd",
    "ਰਾਗ ਮਾਲਾ": "raagmala",
    "ਜੈਤਸਰੀ ਕੀ ਵਾਰ": "jaitsrikivar",
    "ਸ੍ਰੀ ਭਗਉਤੀ ਅਸਤੋਤ੍ਰ (ਸ੍ਰੀ ਹਜ਼ੂਰ ਸਾਹਿਬ)": "bhagautiastotrhazoor",
    "ਸਵਈਏ ਮਹਲੇ ਪੰਜਵੇ ਕੇ": "svaiyem5",
    "ਵਾਰ ਮਾਝ ਕੀ": "maajhkivaar",
    "ਕਾਨੜੇ ਕੀ ਵਾਰ ਮਹਲਾ ੪": "kaanrekivaarm4",
    "ਪਟੀ ਮਹਲਾ ੩": "patteem3",
    "ਸਵਈਏ ਮਹਲੇ ਚਉਥੇ ਕੇ": "svaiyem4",
    "ਰਾਗੁ ਸੋਰਠਿ ਵਾਰ ਮਹਲੇ ੪ ਕੀ": "soratkivaarm4",
    "ਤ੍ਵ ਪ੍ਰਸਾਦਿ ਸਵੱਯੇ (ਦੀਨਨ ਕੀ)": "svaiyedeenan",
    "ਰਾਗੁ ਭੈਰਉ": "bhairo",
    "ਉਗ੍ਰਦੰਤੀ": "ogardanti",
    "ਸਿਰੀਰਾਗ ਕੀ ਵਾਰ ਮਹਲਾ ੪": "siriraagkivaar",
    "ਵਾਰ ਸੂਹੀ ਕੀ": "soohikivaar",
    "ਮਾਰੂ ਵਾਰ ਮਹਲਾ ੩": "maarookivaarm3",
    "ਰਾਗੁ ਕਾਨੜਾ": "kaanra",
    "ਬਿਲਾਵਲੁ ਮਹਲਾ ੩ ਵਾਰ ਸਤ": "vaarsat",
    "ਚਉਬੋਲੇ": "chaubole",
    "ਜਪੁਜੀ ਸਾਹਿਬ": "japji",
    "ਥਿਤੀ ਮਹਲਾ ੫": "thitteem5",
]

let bani_partitions: [String: [Int]] = [
    "aarti": [0],
    "aasa": [0, 14, 26, 44, 55, 66, 77, 88, 99, 110, 124, 133, 144, 155, 170, 183, 196, 208, 221, 234, 247, 260, 273, 284, 293, 302, 311, 320, 329, 338, 347, 356, 363, 370, 381, 392, 403, 414, 426, 437, 448, 457, 464, 477, 486, 495, 504, 521, 534, 553, 566],
    "akaalustatchaupai": [0],
    "akalustat": [0, 8, 49, 90, 131, 212, 293, 374, 576, 657, 819, 840, 921, 970, 1011, 1068],
    "anand": [0],
    "ardas": [0],
    "asadivar": [0, 21, 61, 99, 135, 179, 210, 248, 276, 318, 352, 386, 415, 447, 478, 518, 557, 579, 607, 637, 663, 683, 714, 732],
    "athchandichariter": [0, 22],
    "baarehmaha": [0],
    "baarehmahasvaye": [0],
    "baavanakhrikabirjee": [0],
    "basant": [0, 90, 101, 118, 147, 168],
    "basantkivar": [0, 8],
    "bavanakhree": [0, 12, 15, 26, 29, 38, 41, 50, 53, 61, 64, 73, 76, 84, 87, 96, 99, 108, 111, 120, 123, 132, 135, 144, 147, 156, 159, 168, 170, 178, 181, 190, 193, 202, 205, 214, 217, 226, 229, 238, 241, 250, 253, 262, 265, 273, 276, 285, 288, 297, 300, 309, 312, 321, 324, 333, 336, 344, 347, 356, 359, 368, 371, 380, 383, 392, 395, 404, 407, 415, 418, 427, 430, 437, 440, 449, 452, 461, 464, 473, 476, 485, 488, 497, 500, 508, 511, 522, 525, 533, 536, 545, 548, 556, 559, 567, 570, 578, 581, 590, 593, 602, 605, 613, 616, 625, 628, 637, 640, 649, 654, 663],
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
    "dhakhnioankar": [0],
    "dhanasari": [0, 42, 99, 124, 142, 152, 159],
    "dukhbhanjani": [0, 12, 23, 34, 45, 56, 67, 74, 85, 96, 111, 118, 125, 132, 139, 146, 157, 164, 173, 180, 187, 194, 201, 208, 219, 226, 233, 240, 247, 254, 261, 268, 275, 282],
    "funhem5": [0],
    "gauri": [0, 14, 25, 36, 47, 58, 69, 80, 91, 102, 113, 124, 135, 146, 157, 170, 185, 200, 219, 228, 237, 246, 255, 264, 273, 281, 288, 297, 306, 315, 324, 332, 341, 350, 357, 364, 388, 395, 442, 451, 458, 475, 488, 499, 508, 517, 526, 539, 550, 563, 574, 585, 596, 607, 618, 629, 640, 651, 661, 671, 682, 691, 698, 705, 713, 720, 727, 734, 755, 764, 775, 943, 950, 1017, 1052, 1062, 1087, 1098, 1108],
    "gaurikivaarm4": [0, 15, 29, 41, 53, 69, 88, 111, 136, 160, 183, 204, 226, 254, 283, 318, 338, 358, 378, 397, 427, 449, 468, 484, 500, 516, 538, 640],
    "gaurikivaarm5": [0, 15, 27, 39, 51, 63, 75, 87, 99, 113, 125, 137, 149, 161, 173, 185, 206, 218, 230, 242, 256],
    "ghorrian": [0],
    "gond": [0, 13, 22, 52, 71, 90, 109, 131, 150, 169, 188, 206, 217, 224, 237, 258, 271, 283, 304],
    "gujri": [0, 14, 25, 40, 48, 63, 76, 88],
    "gujrikivaarm3": [0, 14, 31, 44, 60, 80, 94, 112, 130, 145, 165, 183, 204, 221, 238, 256, 273, 293, 314, 335, 348, 362],
    "gujrikivaarm5": [0, 18, 35, 50, 65, 80, 95, 110, 125, 140, 155, 170, 185, 200, 215, 230, 244, 259, 274, 289, 314],
    "gunvanti": [0],
    "jaap": [0, 11, 120, 181, 238, 248, 288, 309, 342, 371, 380, 393, 410, 531, 568, 581, 602, 647, 688, 745, 762, 795],
    "jaitsree": [0],
    "jaitsrikivar": [0, 9, 20, 31, 42, 53, 64, 75, 86, 97, 108, 119, 131, 142, 153, 164, 175, 186, 197, 208],
    "japji": [0, 10, 48, 60, 84, 108, 132, 171, 199, 241, 267, 299, 316, 335, 371, 378],
    "kaanra": [0],
    "kaanrekivaarm4": [0, 14, 30, 48, 69, 88, 105, 117, 131, 148, 163, 178, 190, 202, 217],
    "karhalai": [0],
    "kedaara": [0, 55],
    "kuchji": [0],
    "lavaa": [0],
    "maajhkivaar": [0, 3, 38, 62, 81, 104, 125, 145, 171, 189, 215, 239, 259, 292, 331, 355, 378, 398, 424, 453, 475, 495, 512, 535, 553, 570, 585, 624],
    "maaligauri": [0],
    "maarookivaarm3": [0, 14, 34, 49, 63, 75, 87, 100, 112, 132, 148, 162, 176, 191, 208, 225, 242, 267, 280, 299, 311, 323],
    "maaru": [0, 62, 87, 92, 105, 116, 134, 143],
    "malaar": [0, 30, 39, 50, 59],
    "malaarkivaarm1": [0, 19, 34, 51, 66, 83, 100, 122, 145, 163, 183, 203, 222, 241, 256, 275, 293, 308, 329, 364, 390, 420, 445, 464, 494, 539, 554],
    "ogardanti": [0, 49, 52, 97, 100, 145, 148, 193, 196, 241, 244, 289, 294],
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
    "sidhgosht": [0, 3, 7, 9, 13, 17, 21, 25, 29, 33, 37, 41, 45, 49, 53, 57, 61, 65, 69, 73, 77, 83, 89, 95, 101, 107, 113, 119, 125, 131, 137, 143, 149, 155, 161, 167, 173, 179, 185, 191, 197, 203, 209, 215, 221, 227, 233, 239, 245, 251, 257, 263, 269, 274, 280, 286, 292, 298, 304, 310, 316, 322, 328, 334, 340, 346, 352, 358, 364, 370, 376, 382, 388, 394, 400],
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

    @AppStorage("settings.larivaarOn") private var larivaarOn: Bool = true
    @AppStorage("settings.larivaarAssist") private var larivaarAssist: Bool = false

    @AppStorage("bani.textScale") private var textScale: Double = 1.0
    @AppStorage("bani.visraamSource") private var selectedVisraamSource: String = "igurbani"
    @AppStorage("bani.englishSource") private var selectedEnglishSource: String = "bdb"
    @AppStorage("bani.punjabiSource") private var selectedPunjabiSource: String = "none"
    @AppStorage("bani.hindiSource") private var selectedHindiSource: String = "none"
    @AppStorage("bani.englishTranslationTextScale") private var enTransTextScale: Double = 1.0
    @AppStorage("bani.punjabiTranslationTextScale") private var punjabiTransTextScale: Double = 1.0
    @AppStorage("bani.hindiTranslationTextScale") private var hindiTransTextScale: Double = 1.0
    @AppStorage("bani.transliterationSource") private var selectedTransliterationSource: String = "none"
    @AppStorage("bani.transliterationTextScale") private var transliterationTextScale: Double = 1.0
    @AppStorage("bani.fontType") private var fontType: String = "Unicode"
    @AppStorage("bani.paragraphMode") private var isParagraphMode: Bool = true
    @AppStorage("bani.recension") private var selectedRecension: String = "taksal"

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

                            BaniSettingsOptionPickerSlider(title: "Gurbani Font", selectedItem: $fontType, options: fonts, textScale: $textScale)

                            Divider().padding(.leading)

                            BaniSettingsOptionPickerSlider(title: "Transliteration", selectedItem: $selectedTransliterationSource, options: transliterationSources, textScale: $transliterationTextScale)
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
                            BaniSettingsOptionPickerSlider(title: "English", selectedItem: $selectedEnglishSource, options: englishSources, textScale: $enTransTextScale)

                            Divider().padding(.leading)

                            BaniSettingsOptionPickerSlider(title: "Punjabi", selectedItem: $selectedPunjabiSource, options: punjabiSources, textScale: $punjabiTransTextScale)

                            Divider().padding(.leading)

                            BaniSettingsOptionPickerSlider(title: "Hindi", selectedItem: $selectedHindiSource, options: hindiSources, textScale: $hindiTransTextScale)
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

struct BaniSettingsOptionPickerSlider: View {
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
    }
}

struct BaniLineView: View {
    let baniVerse: BaniVerse
    let gestureScale: Double

    @AppStorage("bani.larivaarOn") private var larivaarOn: Bool = false
    @AppStorage("bani.larivaarAssist") private var larivaarAssist: Bool = false
    @AppStorage("bani.textScale") private var textScale: Double = 1.0
    @AppStorage("bani.visraamSource") private var selectedVisraamSource = "igurbani"
    @AppStorage("bani.englishSource") private var selectedEnglishSource = "bdb"
    @AppStorage("bani.punjabiSource") private var selectedPunjabiSource = "none"
    @AppStorage("bani.hindiSource") private var selectedHindiSource = "none"
    @AppStorage("bani.englishTranslationTextScale") private var enTransTextScale: Double = 1.0
    @AppStorage("bani.punjabiTranslationTextScale") private var punjabiTransTextScale: Double = 1.0
    @AppStorage("bani.hindiTranslationTextScale") private var hindiTransTextScale: Double = 1.0
    @AppStorage("bani.transliterationSource") private var selectedTransliterationSource = "none"
    @AppStorage("bani.transliterationTextScale") private var transliterationTextScale: Double = 1.0
    @AppStorage("bani.fontType") private var fontType: String = "Unicode"

    @State private var lineLarivaar = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Gurbani line with tap to toggle larivaar
            renderGurbaniLine(baniVerse.verse)
                .font(resolveFont(size: 20 * textScale * gestureScale, fontType: fontType))
                .fontWeight(.medium)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
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
                .padding(.bottom, hasAnyTranslation ? 6 : 0)

            // Transliteration (if enabled)
            if selectedTransliterationSource != "none",
               let transliteration = baniVerse.verse.transliteration.value(for: selectedTransliterationSource)
            {
                Text(transliteration)
                    .font(.system(size: 15 * transliterationTextScale * gestureScale, design: .monospaced))
                    .foregroundColor(colorScheme == .dark ? Color(red: 0.75, green: 0.75, blue: 0.75) : Color(red: 0.5, green: 0.5, blue: 0.5))
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(0.9)
                    .padding(.bottom, 3)
            }

            // English Translation (if enabled)
            if selectedEnglishSource != "none",
               let translation = baniVerse.verse.translation.getTranslation(for: "english", source: selectedEnglishSource)
            {
                Text(translation)
                    .font(.system(size: 16 * enTransTextScale * gestureScale, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? Color(red: 0.7, green: 0.85, blue: 1.0) : Color(red: 0.2, green: 0.4, blue: 0.7))
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 3)
            }

            // Punjabi Translation (if enabled)
            if selectedPunjabiSource != "none",
               let translation = baniVerse.verse.translation.getTranslation(for: "punjabi", source: selectedPunjabiSource)
            {
                Text(translation)
                    .font(.system(size: 15 * punjabiTransTextScale * gestureScale))
                    .foregroundColor(colorScheme == .dark ? Color(red: 1.0, green: 0.85, blue: 0.6) : Color(red: 0.65, green: 0.45, blue: 0.2))
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 3)
            }

            // Hindi Translation (if enabled)
            if selectedHindiSource != "none",
               let translation = baniVerse.verse.translation.getTranslation(for: "hindi", source: selectedHindiSource)
            {
                Text(translation)
                    .font(.system(size: 15 * hindiTransTextScale * gestureScale))
                    .foregroundColor(colorScheme == .dark ? Color(red: 0.9, green: 0.75, blue: 0.85) : Color(red: 0.6, green: 0.3, blue: 0.5))
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 3)
            }

            // Header divider with extra spacing
            if baniVerse.header == 1 {
                Divider()
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            }
        }
        .padding(.vertical, 10)
    }

    // Helper to check if any translation/transliteration is enabled
    private var hasAnyTranslation: Bool {
        selectedTransliterationSource != "none" ||
            selectedEnglishSource != "none" ||
            selectedPunjabiSource != "none" ||
            selectedHindiSource != "none"
    }

    // Render Gurbani line with visraam highlighting
    private func renderGurbaniLine(_ verse: Verse) -> Text {
        let text: String
        let isLarivaarMode = lineLarivaar || larivaarAssist

        if isLarivaarMode {
            text = fontType == "Unicode" ? verse.larivaar.unicode : verse.larivaar.gurmukhi
        } else {
            text = fontType == "Unicode" ? verse.verse.unicode : verse.verse.gurmukhi
        }
        let words = text.components(separatedBy: " ")

        // Get visraam points
        var visraamPoints: [Int: String] = [:]
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

            // Check if this word has a visraam marker
            if let visraamType = visraamPoints[index] {
                // Word has visraam - always use visraam color regardless of assist mode
                switch visraamType {
                case "v": // small pause
                    color = colorScheme == .dark ? Color(red: 1.0, green: 0.5, blue: 0.3) : Color(red: 0.9, green: 0.2, blue: 0.0)
                case "y": // big pause
                    color = colorScheme == .dark ? Color(red: 0.3, green: 1.0, blue: 0.3) : Color(red: 0.0, green: 0.7, blue: 0.0)
                default:
                    // Unknown visraam type - fall through to alternating colors if assist is on
                    if larivaarAssist {
                        let isEvenWord = index % 2 == 0
                        color = isEvenWord
                            ? (colorScheme == .dark ? Color(red: 0.7, green: 0.85, blue: 1.0) : Color(red: 0.1, green: 0.2, blue: 0.6))
                            : (colorScheme == .dark ? Color(red: 1.0, green: 0.85, blue: 0.5) : Color(red: 0.6, green: 0.45, blue: 0.0))
                    } else {
                        color = .primary
                    }
                }
            } else if larivaarAssist {
                // No visraam marker - use alternating colors for larivaar assist
                let isEvenWord = index % 2 == 0
                color = isEvenWord
                    ? (colorScheme == .dark ? Color(red: 0.7, green: 0.85, blue: 1.0) : Color(red: 0.1, green: 0.2, blue: 0.6))
                    : (colorScheme == .dark ? Color(red: 1.0, green: 0.85, blue: 0.5) : Color(red: 0.6, green: 0.45, blue: 0.0))
            } else {
                // Normal mode - just primary color
                color = .primary
            }

            wordText = Text(word).foregroundColor(color)
            result = result + wordText

            // Add space between words (except for last word), only if not in larivaar mode
            if index < words.count - 1 && !isLarivaarMode {
                result = result + Text(" ")
            }
        }

        return result
    }
}
