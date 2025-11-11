//
//  ShabadHistoryView.swift
//  Chet
//
//  Created by gian singh on 8/29/25.
//

import SwiftData
import SwiftUI

// Remove the NavigationView wrapper in ShabadHistoryView
struct ShabadHistoryView: View {
    @Query(sort: \ShabadHistory.dateViewed, order: .reverse) private var historyItems: [ShabadHistory]
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var debouncedSearchText = ""
    @State private var isSearching = false
    @State private var showDeleteAllAlert = false
    @State private var searchTask: Task<Void, Never>?

    var filteredHistoryItems: [ShabadHistory] {
        if debouncedSearchText.isEmpty {
            return historyItems
        }

        let lowercaseQuery = debouncedSearchText.lowercased()
        return historyItems.filter { history in
            searchMatches(history: history, query: lowercaseQuery)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if historyItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary)
                    Text("No History")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Your viewed shabads will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 8) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                                .font(.system(size: 16))

                            TextField("Search history...", text: $searchText)
                                .textFieldStyle(.plain)
                                .autocorrectionDisabled()

                            if isSearching {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                    debouncedSearchText = ""
                                    searchTask?.cancel()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 16))
                                }
                            }
                        }
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .onChange(of: searchText) { oldValue, newValue in
                        // Cancel previous search task
                        searchTask?.cancel()

                        if newValue.isEmpty {
                            debouncedSearchText = ""
                            isSearching = false
                        } else {
                            isSearching = true
                            // Create new debounced search task
                            searchTask = Task {
                                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                                if !Task.isCancelled {
                                    await MainActor.run {
                                        debouncedSearchText = newValue
                                        isSearching = false
                                    }
                                }
                            }
                        }
                    }

                    // Result count bar
                    if !searchText.isEmpty {
                        HStack {
                            if isSearching {
                                Text("Searching...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(filteredHistoryItems.count) result\(filteredHistoryItems.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6).opacity(0.5))
                    }

                    if filteredHistoryItems.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 44))
                                .foregroundColor(.secondary)
                            Text("No Results Found")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Try different search terms")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(filteredHistoryItems) { historyItem in
                                NavigationLink(destination: ShabadViewDisplayWrapper(sbdRes: historyItem.sbdRes, indexOfLine: historyItem.indexOfSelectedLine, onIndexChange: { newIndex in
                                    historyItem.indexOfSelectedLine = newIndex
                                })) {
                                    RowView(
                                        verse: historyItem.sbdRes.verses[historyItem.indexOfSelectedLine],
                                        source: historyItem.sbdRes.shabadInfo.source,
                                        writer: historyItem.sbdRes.shabadInfo.writer,
                                        raag: historyItem.sbdRes.shabadInfo.raag,
                                        pageNo: historyItem.sbdRes.shabadInfo.pageNo,
                                        the_date: historyItem.dateViewed,
                                        searchQuery: debouncedSearchText,
                                        allVerses: historyItem.sbdRes.verses
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .onDelete(perform: deleteHistoryItems)
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
        }
        .navigationTitle("History")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if !debouncedSearchText.isEmpty {
                            Text("\(filteredHistoryItems.count) of \(historyItems.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(historyItems.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(6)

                    if !historyItems.isEmpty {
                        Button(role: .destructive) {
                            showDeleteAllAlert = true
                        } label: {
                            Label("Delete All", systemImage: "trash.fill")
                                .labelStyle(.iconOnly)
                                .foregroundColor(.red)
                                .font(.system(size: 16))
                        }
                    }
                }
            }
        }
        .alert("Delete All History?", isPresented: $showDeleteAllAlert) {
            Button("Delete All", role: .destructive) {
                clearHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all \(historyItems.count) viewed shabads from your history.")
        }
        .onDisappear {
            searchTask?.cancel()
        }
    }

    private func searchMatches(history: ShabadHistory, query: String) -> Bool {
        // Search through all verses
        for verse in history.sbdRes.verses {
            // Check Gurmukhi text
            if verse.verse.unicode.lowercased().contains(query) ||
               verse.verse.gurmukhi.lowercased().contains(query) ||
               verse.larivaar.unicode.lowercased().contains(query) {
                return true
            }

            // Check English translation
            if let englishTrans = verse.translation.en.bdb, englishTrans.lowercased().contains(query) {
                return true
            }
            if let englishTrans = verse.translation.en.ms, englishTrans.lowercased().contains(query) {
                return true
            }
            if let englishTrans = verse.translation.en.ssk, englishTrans.lowercased().contains(query) {
                return true
            }

            // Check Punjabi translation
            if let punjabiTrans = verse.translation.pu.bdb?.unicode, punjabiTrans.lowercased().contains(query) {
                return true
            }
            if let punjabiTrans = verse.translation.pu.ms?.unicode, punjabiTrans.lowercased().contains(query) {
                return true
            }

            // Check transliteration
            if !verse.transliteration.english.isEmpty && verse.transliteration.english.lowercased().contains(query) {
                return true
            }
        }

        // Search shabad info
        let info = history.sbdRes.shabadInfo
        if let english = info.source.english, !english.isEmpty && english.lowercased().contains(query) {
            return true
        }
        if let unicode = info.source.unicode, !unicode.isEmpty && unicode.lowercased().contains(query) {
            return true
        }
        if let writerEnglish = info.writer.english, writerEnglish.lowercased().contains(query) {
            return true
        }
        if let writerUnicode = info.writer.unicode, writerUnicode.lowercased().contains(query) {
            return true
        }
        if let raagEnglish = info.raag.english, raagEnglish.lowercased().contains(query) {
            return true
        }
        if let raagUnicode = info.raag.unicode, raagUnicode.lowercased().contains(query) {
            return true
        }

        return false
    }

    private func deleteHistoryItems(at offsets: IndexSet) {
        for index in offsets {
            let history = filteredHistoryItems[index]
            modelContext.delete(history)
        }
        try? modelContext.save()
    }

    private func clearHistory() {
        for history in historyItems {
            modelContext.delete(history)
        }
        try? modelContext.save()
    }
}

struct MatchedContent {
    let matchType: String
    let matchedText: String
    let lineNumber: Int?
}

struct RowView: View {
    let verse: Verse
    let source: Source
    let writer: Writer
    let raag: Raag
    let pageNo: Int?
    let the_date: Date?
    let searchQuery: String
    let allVerses: [Verse]

    @AppStorage("CompactRowViewSetting") private var compactRowViewSetting = false
    @AppStorage("settings.larivaarOn") private var larivaarOn: Bool = true
    @AppStorage("fontType") private var fontType: String = "Unicode"

    let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    var gurmukhiText: String {
        if fontType == "Unicode" {
            if larivaarOn {
                return verse.larivaar.unicode
            }
            return verse.verse.unicode
        } else {
            if larivaarOn {
                return verse.larivaar.gurmukhi
            }
            return verse.verse.gurmukhi
        }
    }

    var body: some View {
        if compactRowViewSetting {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(highlightedGurmukhiText)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if !searchQuery.isEmpty, let matchInfo = getMatchInfo() {
                        VStack(alignment: .leading, spacing: 4) {
                            // Match type badge
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption2)
                                if let lineNum = matchInfo.lineNumber {
                                    Text("Line \(lineNum) - \(matchInfo.matchType)")
                                        .font(.caption2)
                                } else {
                                    Text(matchInfo.matchType)
                                        .font(.caption2)
                                }
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)

                            // Matched text preview
                            if matchInfo.lineNumber != nil || matchInfo.matchType == "Writer" || matchInfo.matchType == "Source" || matchInfo.matchType == "Transliteration" || matchInfo.matchType == "Raag" {
                                Text(highlightMatchedText(matchInfo.matchedText))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                    .padding(.leading, 4)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(highlightedGurmukhiText)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        if let a = verse.translation.en.bdb {
                            Text(highlightedTranslationText(a))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }

                        if !searchQuery.isEmpty, let matchInfo = getMatchInfo() {
                            VStack(alignment: .leading, spacing: 4) {
                                // Match type badge
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption2)
                                    if let lineNum = matchInfo.lineNumber {
                                        Text("Line \(lineNum) - \(matchInfo.matchType)")
                                            .font(.caption2)
                                    } else {
                                        Text(matchInfo.matchType)
                                            .font(.caption2)
                                    }
                                }
                                .foregroundColor(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)

                                // Matched text preview
                                if matchInfo.lineNumber != nil || matchInfo.matchType == "Writer" || matchInfo.matchType == "Source" || matchInfo.matchType == "Transliteration" || matchInfo.matchType == "Raag" {
                                    Text(highlightMatchedText(matchInfo.matchedText))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                        .padding(.leading, 4)
                                }
                            }
                        }
                    }
                    Spacer()
                    if let the_date = the_date {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(the_date, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(the_date, style: .time)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                HStack(spacing: 6) {
                    Text(getCustomSrcName(source))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue.opacity(0.15))
                        )
                        .foregroundColor(.blue)

                    Text(writer.english ?? "Unknown")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.green.opacity(0.15))
                        )
                        .foregroundColor(.green)

                    if let pageNo = pageNo {
                        Text("Ang \(String(pageNo))")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.orange.opacity(0.15))
                            )
                            .foregroundColor(.orange)
                    }

                    Spacer()
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    var highlightedGurmukhiText: AttributedString {
        var attributed = AttributedString(gurmukhiText)
        let fontSize: Double = compactRowViewSetting ? 20.0 : 24.0
        attributed.font = resolveFont(size: fontSize, fontType: fontType == "Unicode" ? "AnmolLipiSG" : fontType)

        if searchQuery.isEmpty {
            return attributed
        }

        let lowercaseText = gurmukhiText.lowercased()
        let lowercaseQuery = searchQuery.lowercased()

        var searchStartIndex = lowercaseText.startIndex
        while searchStartIndex < lowercaseText.endIndex,
              let range = lowercaseText.range(of: lowercaseQuery, range: searchStartIndex..<lowercaseText.endIndex) {
            if let attributedRange = Range<AttributedString.Index>(range, in: attributed) {
                attributed[attributedRange].backgroundColor = Color.yellow.opacity(0.4)
                attributed[attributedRange].foregroundColor = .primary
            }
            searchStartIndex = range.upperBound
        }

        return attributed
    }

    func highlightedTranslationText(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)

        if searchQuery.isEmpty {
            return attributed
        }

        let lowercaseText = text.lowercased()
        let lowercaseQuery = searchQuery.lowercased()

        var searchStartIndex = lowercaseText.startIndex
        while searchStartIndex < lowercaseText.endIndex,
              let range = lowercaseText.range(of: lowercaseQuery, range: searchStartIndex..<lowercaseText.endIndex) {
            if let attributedRange = Range<AttributedString.Index>(range, in: attributed) {
                attributed[attributedRange].backgroundColor = Color.yellow.opacity(0.4)
                attributed[attributedRange].foregroundColor = .primary
            }
            searchStartIndex = range.upperBound
        }

        return attributed
    }

    func highlightMatchedText(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)

        if searchQuery.isEmpty {
            return attributed
        }

        let lowercaseText = text.lowercased()
        let lowercaseQuery = searchQuery.lowercased()

        var searchStartIndex = lowercaseText.startIndex
        while searchStartIndex < lowercaseText.endIndex,
              let range = lowercaseText.range(of: lowercaseQuery, range: searchStartIndex..<lowercaseText.endIndex) {
            if let attributedRange = Range<AttributedString.Index>(range, in: attributed) {
                attributed[attributedRange].backgroundColor = Color.yellow.opacity(0.4)
                attributed[attributedRange].foregroundColor = .primary
            }
            searchStartIndex = range.upperBound
        }

        return attributed
    }

    func getMatchInfo() -> MatchedContent? {
        let lowercaseQuery = searchQuery.lowercased()

        // Check if match is in current verse Gurmukhi (check all formats)
        if verse.verse.unicode.lowercased().contains(lowercaseQuery) {
            return MatchedContent(matchType: "Current line (Gurmukhi)", matchedText: verse.verse.unicode, lineNumber: nil)
        }
        if verse.verse.gurmukhi.lowercased().contains(lowercaseQuery) {
            return MatchedContent(matchType: "Current line (Gurmukhi)", matchedText: verse.verse.gurmukhi, lineNumber: nil)
        }
        if verse.larivaar.unicode.lowercased().contains(lowercaseQuery) {
            return MatchedContent(matchType: "Current line (Gurmukhi)", matchedText: verse.larivaar.unicode, lineNumber: nil)
        }

        // Check if match is in current verse translations (all sources)
        if let translation = verse.translation.en.bdb, translation.lowercased().contains(lowercaseQuery) {
            return MatchedContent(matchType: "Current line (Translation)", matchedText: translation, lineNumber: nil)
        }
        if let translation = verse.translation.en.ms, translation.lowercased().contains(lowercaseQuery) {
            return MatchedContent(matchType: "Current line (Translation)", matchedText: translation, lineNumber: nil)
        }
        if let translation = verse.translation.en.ssk, translation.lowercased().contains(lowercaseQuery) {
            return MatchedContent(matchType: "Current line (Translation)", matchedText: translation, lineNumber: nil)
        }
        if let translation = verse.translation.pu.bdb?.unicode, translation.lowercased().contains(lowercaseQuery) {
            return MatchedContent(matchType: "Current line (Punjabi)", matchedText: translation, lineNumber: nil)
        }
        if let translation = verse.translation.pu.ms?.unicode, translation.lowercased().contains(lowercaseQuery) {
            return MatchedContent(matchType: "Current line (Punjabi)", matchedText: translation, lineNumber: nil)
        }

        // Check transliteration for current verse
        if !verse.transliteration.english.isEmpty && verse.transliteration.english.lowercased().contains(lowercaseQuery) {
            return MatchedContent(matchType: "Current line (Transliteration)", matchedText: verse.transliteration.english, lineNumber: nil)
        }

        // Check if match is in other verses
        for (index, v) in allVerses.enumerated() {
            if v.verseId == verse.verseId { continue }

            if v.verse.unicode.lowercased().contains(lowercaseQuery) {
                return MatchedContent(matchType: "Gurmukhi", matchedText: v.verse.unicode, lineNumber: index + 1)
            }
            if v.verse.gurmukhi.lowercased().contains(lowercaseQuery) {
                return MatchedContent(matchType: "Gurmukhi", matchedText: v.verse.gurmukhi, lineNumber: index + 1)
            }
            if v.larivaar.unicode.lowercased().contains(lowercaseQuery) {
                return MatchedContent(matchType: "Gurmukhi", matchedText: v.larivaar.unicode, lineNumber: index + 1)
            }

            // Check all translation sources for other verses
            if let trans = v.translation.en.bdb, trans.lowercased().contains(lowercaseQuery) {
                return MatchedContent(matchType: "Translation", matchedText: trans, lineNumber: index + 1)
            }
            if let trans = v.translation.en.ms, trans.lowercased().contains(lowercaseQuery) {
                return MatchedContent(matchType: "Translation", matchedText: trans, lineNumber: index + 1)
            }
            if let trans = v.translation.en.ssk, trans.lowercased().contains(lowercaseQuery) {
                return MatchedContent(matchType: "Translation", matchedText: trans, lineNumber: index + 1)
            }
            if let trans = v.translation.pu.bdb?.unicode, trans.lowercased().contains(lowercaseQuery) {
                return MatchedContent(matchType: "Punjabi", matchedText: trans, lineNumber: index + 1)
            }
            if let trans = v.translation.pu.ms?.unicode, trans.lowercased().contains(lowercaseQuery) {
                return MatchedContent(matchType: "Punjabi", matchedText: trans, lineNumber: index + 1)
            }

            // Check transliteration for other verses
            if !v.transliteration.english.isEmpty && v.transliteration.english.lowercased().contains(lowercaseQuery) {
                return MatchedContent(matchType: "Transliteration", matchedText: v.transliteration.english, lineNumber: index + 1)
            }
        }

        // Check writer/source/raag
        if let writerEnglish = writer.english, writerEnglish.lowercased().contains(lowercaseQuery) {
            return MatchedContent(matchType: "Writer", matchedText: writerEnglish, lineNumber: nil)
        }
        if let writerUnicode = writer.unicode, writerUnicode.lowercased().contains(lowercaseQuery) {
            return MatchedContent(matchType: "Writer", matchedText: writerUnicode, lineNumber: nil)
        }
        if let english = source.english, !english.isEmpty && english.lowercased().contains(lowercaseQuery) {
            return MatchedContent(matchType: "Source", matchedText: english, lineNumber: nil)
        }
        if let unicode = source.unicode, !unicode.isEmpty && unicode.lowercased().contains(lowercaseQuery) {
            return MatchedContent(matchType: "Source", matchedText: unicode, lineNumber: nil)
        }
        if let raagEnglish = raag.english, raagEnglish.lowercased().contains(lowercaseQuery) {
            return MatchedContent(matchType: "Raag", matchedText: raagEnglish, lineNumber: nil)
        }
        if let raagUnicode = raag.unicode, raagUnicode.lowercased().contains(lowercaseQuery) {
            return MatchedContent(matchType: "Raag", matchedText: raagUnicode, lineNumber: nil)
        }

        return nil
    }
}

