import SwiftData
import SwiftUI

struct SearchView: View {
    @Binding var shouldFocusSearchBar: Bool
    @State private var searchText = ""
    @State private var results: [SearchVerse] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    // @FocusState private var isSearchFieldFocused: Bool
    @State private var isSearchFieldFocused = false

    @State private var selectedShabad: ShabadAPIResponse?
    @State private var isNavigatingToSearchedSbd = false
    @State private var isNavigatingToHukam = false

    @State private var showingPunjabiKeyboard = false
    @State private var searchType: SearchType = .auto
    @State private var detectedSearchType: SearchType = .firstLetterAnywhere // Tracks what auto-detection chose

    @AppStorage("fontType") private var fontType: String = "Unicode"
    @AppStorage("settings.larivaarOn") private var larivaarOn: Bool = true
    @AppStorage("settings.qwertyKeyboard") private var qwertyKeyboard: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Searching for shabads...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if showingPunjabiKeyboard || isSearchFieldFocused {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showingPunjabiKeyboard = false
                                isSearchFieldFocused = false
                            }
                        }
                    }
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text("Search Error")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if showingPunjabiKeyboard || isSearchFieldFocused {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showingPunjabiKeyboard = false
                                isSearchFieldFocused = false
                            }
                        }
                    }
                } else if results.isEmpty && (!searchText.isEmpty || isSearchFieldFocused) {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text("No Results Found")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Try searching with different keywords")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if showingPunjabiKeyboard || isSearchFieldFocused {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showingPunjabiKeyboard = false
                                isSearchFieldFocused = false
                            }
                        }
                    }
                } else if searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "text.magnifyingglass")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text("Search Gurbani")
                            .font(.title2)
                            .foregroundColor(.primary)
                        Text("Enter keywords to search for shabads")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        VStack(spacing: 10) {
                            Button(action: {
                                Task { await openRandomShabad() }
                            }) {
                                Label("Random Shabad", systemImage: "shuffle")
                            }
                            .buttonStyle(.bordered)

                            Button {
                                isNavigatingToHukam = true
                            } label: {
                                Label("Darbar Sahib Hukamnama", systemImage: "calendar")
                            }
                            .buttonStyle(.bordered)
                        }
                        .navigationDestination(isPresented: $isNavigatingToSearchedSbd) {
                            if let sbd = selectedShabad {
                                ShabadViewDisplayWrapper(sbdRes: sbd, indexOfLine: 0)
                            }
                        }
                        .navigationDestination(isPresented: $isNavigatingToHukam) {
                            HukamnamaView()
                        }
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if showingPunjabiKeyboard || isSearchFieldFocused {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showingPunjabiKeyboard = false
                                isSearchFieldFocused = false
                            }
                        }
                    }
                } else {
                    List(results) { searchedLine in
                        NavigationLink(destination: ShabadViewFromSearchedLine(
                            searchedLine: searchedLine
                        )) {
                            SearchResultRowView(
                                verse: convertToVerse(from: searchedLine),
                                source: searchedLine.source,
                                writer: searchedLine.writer,
                                pageNo: searchedLine.pageNo,
                                searchQuery: searchText,
                                searchType: detectedSearchType // Use detected type for proper highlighting
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .listStyle(PlainListStyle())
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 10)
                            .onChanged { _ in
                                if showingPunjabiKeyboard || isSearchFieldFocused {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        showingPunjabiKeyboard = false
                                        isSearchFieldFocused = false
                                    }
                                }
                            }
                    )
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isLoading)
            .animation(.easeInOut(duration: 0.3), value: errorMessage)
            .animation(.easeInOut(duration: 0.3), value: results.isEmpty)
            .animation(.easeInOut(duration: 0.3), value: searchText.isEmpty)

            VStack(spacing: 8) {
                Menu {
                    ForEach(SearchType.allCases) { type in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                searchType = type
                            }
                        } label: {
                            HStack {
                                Text(type.name)
                                if searchType == type {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "magnifyingglass")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        if searchType == .auto {
                            Text("Auto → \(detectedSearchType.name)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text(searchType.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 10) {
                    MyTextField(text: $searchText, isFocused: $isSearchFieldFocused, showingPunjabiKeyboard: $showingPunjabiKeyboard, searchType: searchType, fontType: fontType, placeholder: searchType == .ang ? "123" : "cyq")
                        .frame(height: 34)
                        .shadow(color: .black.opacity(0.05), radius: 4, y: 1)

                    if !searchText.isEmpty {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                searchText = ""
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.secondary)
                                .frame(width: 44, height: 44)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: searchType)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showingPunjabiKeyboard)

            if !showingPunjabiKeyboard {
                Spacer()
                    .transition(.opacity)
                Spacer()
                    .transition(.opacity)
            } else {
                if searchType == .ang {
                    AngKeyboardView(
                        onKeyPress: { key in
                            searchText.append(key)
                        },
                        onDelete: {
                            if !searchText.isEmpty { searchText.removeLast() }
                        },
                        onReturn: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showingPunjabiKeyboard = false
                                isSearchFieldFocused = false
                            }
                            Task { await fetchResults() }
                        }
                    )
                    .frame(height: 260)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if qwertyKeyboard {
                    QwertyPunjabiKeyboardView(
                        onKeyPress: { key in
                            searchText.append(key)
                        },
                        onDelete: {
                            if !searchText.isEmpty { searchText.removeLast() }
                        },
                        onSpace: {
                            searchText.append(" ")
                        },
                        switchKeyboard: {
                            qwertyKeyboard.toggle()
                        },
                        onReturn: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showingPunjabiKeyboard = false
                                isSearchFieldFocused = false
                            }
                            Task { await fetchResults() }
                        }
                    )
                    .frame(height: 340)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    PunjabiKeyboardView(
                        onKeyPress: { key in
                            searchText.append(key)
                        },
                        onDelete: {
                            if !searchText.isEmpty { searchText.removeLast() }
                        },
                        onSpace: {
                            searchText.append(" ")
                        },
                        switchKeyboard: {
                            qwertyKeyboard.toggle()
                        },
                        onReturn: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showingPunjabiKeyboard = false
                                isSearchFieldFocused = false
                            }
                            Task { await fetchResults() }
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onChange(of: shouldFocusSearchBar) { _, newValue in
            if newValue {
                // Dismiss keyboard first if showing
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showingPunjabiKeyboard = false
                }

                // Then focus after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSearchFieldFocused = true
                }

                // Reset the binding after focusing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    shouldFocusSearchBar = false
                }
            }
        }
        .onChange(of: isSearchFieldFocused) { newValue in
            if newValue {
                // Show custom keyboard for Punjabi and Ang searches
                // Only native iOS keyboard for English searches
                if !searchType.needsEnglishKeyboard {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showingPunjabiKeyboard = true
                    }
                }
            }
        }
        .onChange(of: searchText) { newValue in
            // For auto mode, search after 2 characters or if it's detected as Ang
            if searchType == .auto {
                if newValue.count > 2 || (newValue.allSatisfy { $0.isNumber } && newValue.count > 0) {
                    Task { await fetchResults() }
                }
            } else if searchType == .ang && newValue.count > 0 {
                Task { await fetchResults() }
            } else if newValue.count > 2 {
                Task { await fetchResults() }
            }
        }
        .onChange(of: searchType) { _ in
            // Clear search when changing to/from Ang search
            searchText = ""
            results = []
            showingPunjabiKeyboard = false
        }
        .onDisappear {
            // Dismiss keyboard when navigating away
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                showingPunjabiKeyboard = false
                isSearchFieldFocused = false
            }
        }
        .navigationTitle(searchText.isEmpty ? "Gurbani Search" : "\(results.count) Results")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: ShabadHistoryView()) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.subheadline)
                        Text("History")
                            .font(.subheadline)
                    }
                }
            }
        }
        .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemGroupedBackground))
    }

    private func fetchResults() async {
        isLoading = true
        errorMessage = nil

        do {
            if searchText.isEmpty {
                results = []
                isLoading = false
                return
            }

            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

            // Determine the actual search type to use
            let actualSearchType: SearchType
            if searchType == .auto {
                actualSearchType = detectSearchType(from: trimmed)
                detectedSearchType = actualSearchType
                print("🤖 Auto-detected search type: \(actualSearchType.name)")
            } else {
                actualSearchType = searchType
                detectedSearchType = searchType
            }

            print("📍 Search type: \(actualSearchType.name) (rawValue: \(actualSearchType.rawValue))")
            print("📍 Search text: '\(trimmed)'")

            let queryString = "searchtype=\(actualSearchType.rawValue)"
            let decoded = try await searchGurbani(from: trimmed, queryString: queryString)

            print("✅ Results count: \(decoded.verses.count)")
            results = decoded.verses
            isLoading = false
        } catch let error as URLError {
            print("❌ URLError: \(error)")
            print("❌ Error code: \(error.code)")
            errorMessage = "Network error: \(error.localizedDescription)"
            isLoading = false
        } catch let error as DecodingError {
            print("❌ DecodingError: \(error)")
            errorMessage = "Failed to parse API response"
            isLoading = false
        } catch {
            print("❌ Unknown error: \(error)")
            errorMessage = "Failed to fetch results: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func openRandomShabad() async {
        if let response = await fetchRandomShabad() {
            selectedShabad = response
            isNavigatingToSearchedSbd = true
            let sbdHistory = ShabadHistory(sbdRes: response, indexOfSelectedLine: 0)
            addToHistory(sbdHistory: sbdHistory)
        }
    }

    private func addToHistory(sbdHistory: ShabadHistory) {
        let shabadID = sbdHistory.sbdRes.shabadInfo.shabadId
        let descriptor = FetchDescriptor<ShabadHistory>(
            predicate: #Predicate { $0.shabadID == shabadID }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.dateViewed = Date()
        } else {
            modelContext.insert(sbdHistory)
        }

        try? modelContext.save()
    }
}

struct ShabadViewFromSearchedLine: View {
    let searchedLine: SearchVerse

    @State private var isLoadingShabad = true
    @State private var sbdHistory: ShabadHistory?
    @State private var indexOfLine: Int = -1
    @State private var errorMessage: String?
    @Environment(\.colorScheme) private var colorScheme
    @Query private var historyItems: [ShabadHistory]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack {
            if isLoadingShabad {
                ProgressView("Loading Shabad…")
            } else if let errorMessage = errorMessage {
                Text(errorMessage).foregroundColor(.red)
            } else if let sbdHist = sbdHistory {
                ShabadViewDisplayWrapper(sbdRes: sbdHist.sbdRes, indexOfLine: indexOfLine)
            }
        }
        .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemGroupedBackground))
        .task {
            await fetchFullShabad()
        }
    }

    private func fetchFullShabad() async {
        do {
            let decoded = try await fetchShabadResponse(from: searchedLine.shabadId)
            print("decoded", decoded)
            guard let indexOfLine = decoded.verses.firstIndex(where: { $0.verseId == searchedLine.verseId }) else {
                throw URLError(.cannotFindHost)
            }

            isLoadingShabad = false
            sbdHistory = ShabadHistory(sbdRes: decoded, indexOfSelectedLine: indexOfLine)
            self.indexOfLine = indexOfLine
            if let sbdHist = sbdHistory {
                addToHistory(sbdHistory: sbdHist)
            }

        } catch {
            isLoadingShabad = false
            errorMessage = "Failed to fetch shabad: \(error.localizedDescription)"

            print("Error: \(error)")
            print("LineId:", searchedLine.verseId, " ShabadId:", searchedLine.shabadId)
        }
    }

    private func addToHistory(sbdHistory: ShabadHistory) {
        let shabadID = sbdHistory.sbdRes.shabadInfo.shabadId
        let descriptor = FetchDescriptor<ShabadHistory>(
            predicate: #Predicate { $0.shabadID == shabadID }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.dateViewed = Date()
        } else {
            modelContext.insert(sbdHistory)
        }

        try? modelContext.save()
    }
}

struct AngKeyboardView: View {
    let onKeyPress: (String) -> Void
    let onDelete: () -> Void
    let onReturn: () -> Void

    private let rows: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["delete", "0", "return"],
    ]

    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let spacing: CGFloat = 8
            let buttonWidth = (totalWidth - spacing * 4) / 3 // 3 columns, 4 gaps

            VStack(spacing: spacing) {
                ForEach(rows, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(row, id: \.self) { key in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    handleKeyPress(key)
                                }
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(UIColor.systemGray5))
                                        .frame(width: buttonWidth, height: 52)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(UIColor.systemGray3), lineWidth: 0.5)
                                        )
                                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)

                                    // Key label or icon
                                    if key == "delete" {
                                        Image(systemName: "delete.left")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.primary)
                                    } else if key == "return" {
                                        Image(systemName: "return")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.primary)
                                    } else {
                                        Text(key)
                                            .font(.system(size: 26, weight: .medium, design: .rounded))
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, spacing)
            .padding(.vertical, 10)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(16)
        }
        .frame(height: 260)
    }

    private func handleKeyPress(_ key: String) {
        switch key {
        case "delete":
            onDelete()
        case "return":
            onReturn()
        default:
            onKeyPress(key)
        }
    }
}

struct PunjabiKeyboardView: View {
    let onKeyPress: (String) -> Void
    let onDelete: () -> Void
    let onSpace: () -> Void
    let switchKeyboard: () -> Void
    let onReturn: () -> Void

    @AppStorage("fontType") private var fontType: String = "Unicode"

    private let numberRow: [String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]

    // private let rows: [[String]] = [ ["a", "A", "e", "s", "h", "k", "K", "g", "G", "|"], ["c", "C", "j", "J", "\\", "t", "T", "f", "F", "x"], ["q", "Q", "d", "D", "n", "p", "P", "b", "B", "m"], ["X", "r", "l", "v", "V", "S", "^", "Z", "z", "&"] ]

    private let rows: [[String]] = [
        ["a", "A", "e", "s", "h", "q", "Q", "d", "D", "n"],
        ["k", "K", "g", "G", "|", "p", "P", "b", "B", "m"],
        ["c", "C", "j", "J", "\\", "X", "r", "l", "v", "V"],
        ["t", "T", "f", "F", "x", "S", "^", "Z", "z", "&"],
    ]

    var body: some View {
        VStack(spacing: 12) {
            // Number row
            HStack(spacing: 6) {
                ForEach(numberRow, id: \.self) { key in
                    Button(action: {
                        onKeyPress(key)
                    }) {
                        Text(key)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color(UIColor.systemGray5))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(Color(UIColor.systemGray3), lineWidth: 0.5)
                                    )
                            )
                    }
                }
                Button(action: onDelete) {
                    Image(systemName: "delete.left")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                        .frame(height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(UIColor.systemGray5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Color(UIColor.systemGray3), lineWidth: 0.5)
                                )
                        )
                }
            }

            // Regular rows
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 6) {
                    ForEach(Array(rows[rowIndex].enumerated()), id: \.offset) { index, key in
                        KeyButton(label: key, fontType: fontType) {
                            onKeyPress(key)
                        }
                        if (index + 1) % 5 == 0 && index != rows[rowIndex].count - 1 {
                            Spacer(minLength: 14)
                        }
                    }
                }
            }

            LastKeyBoardRow(
                switchKeyboard: switchKeyboard,
                onSpace: onSpace,
                onReturn: onReturn
            )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(Color(UIColor.systemGray6))
    }
}

struct QwertyPunjabiKeyboardView: View {
    let onKeyPress: (String) -> Void
    let onDelete: () -> Void
    let onSpace: () -> Void
    let switchKeyboard: () -> Void
    let onReturn: () -> Void

    @AppStorage("fontType") private var fontType: String = "Unicode"
    @State private var isShifted: Bool = false

    // Number row
    private let numberRow: [String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]

    // Lowercase layout - exact QWERTY
    private let lowercaseRows: [[String]] = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m"],
    ]

    // Uppercase layout - exact QWERTY shifted
    private let uppercaseRows: [[String]] = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["Z", "X", "C", "V", "B", "N", "M"],
    ]

    var currentRows: [[String]] {
        isShifted ? uppercaseRows : lowercaseRows
    }

    var body: some View {
        VStack(spacing: 12) {
            // Number row
            HStack(spacing: 6) {
                ForEach(numberRow, id: \.self) { key in
                    Button(action: {
                        onKeyPress(key)
                    }) {
                        Text(key)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color(UIColor.systemGray5))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(Color(UIColor.systemGray3), lineWidth: 0.5)
                                    )
                            )
                    }
                }
            }

            // Letter rows
            ForEach(currentRows.indices, id: \.self) { rowIndex in
                HStack(spacing: 6) {
                    // Add padding for rows to create QWERTY offset
                    if rowIndex == 1 {
                        Spacer().frame(width: 10)
                    } else if rowIndex == 2 {
                        Button(action: {
                            isShifted.toggle()
                        }) {
                            Image(systemName: isShifted ? "shift.fill" : "shift")
                                .font(.system(size: 20))
                                .foregroundColor(.primary)
                                .frame(width: 50, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(isShifted ? Color(UIColor.systemGray3) : Color(UIColor.systemGray5))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .stroke(Color(UIColor.systemGray3), lineWidth: 0.5)
                                        )
                                )
                        }
                        // Spacer().frame(width: 40)
                    }

                    ForEach(currentRows[rowIndex], id: \.self) { key in
                        KeyButton(label: key, fontType: fontType) {
                            onKeyPress(key)
                        }
                    }
                    if rowIndex == 2 {
                        // Backspace button
                        Button(action: onDelete) {
                            Image(systemName: "delete.left")
                                .font(.system(size: 20))
                                .foregroundColor(.primary)
                                .frame(width: 50, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color(UIColor.systemGray5))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .stroke(Color(UIColor.systemGray3), lineWidth: 0.5)
                                        )
                                )
                        }
                    }

                    if rowIndex == 1 {
                        Spacer().frame(width: 10)
                    }
                }
            }

            // Bottom row with shift, space, and backspace
            LastKeyBoardRow(switchKeyboard: switchKeyboard, onSpace: onSpace, onReturn: onReturn)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(Color(UIColor.systemGray6))
    }
}

struct LastKeyBoardRow: View {
    let switchKeyboard: () -> Void
    let onSpace: () -> Void
    let onReturn: () -> Void
    var body: some View {
        HStack(spacing: 6) {
            Button(action: switchKeyboard) {
                Image(systemName: "keyboard.onehanded.right")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
                    .frame(width: 50, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(UIColor.systemGray3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color(UIColor.systemGray3), lineWidth: 0.5)
                            )
                    )
            }
            // Space bar
            Button(action: onSpace) {
                Text("ਖਾਲੀ ਥਾਂ")
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(UIColor.systemGray5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color(UIColor.systemGray3), lineWidth: 0.5)
                            )
                    )
            }
            Button(action: onReturn) {
                Text("Return")
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 14) // adds a bit of space around text
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(UIColor.systemGray5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color(UIColor.systemGray3), lineWidth: 0.5)
                            )
                    )
            }
        }
    }
}

struct KeyButton: View {
    let label: String
    let fontType: String
    let action: () -> Void

    // Add dotted circle to matras for display purposes
    var displayLabel: String {
        let matras = ["w", "y", "u", "i", "o", "W", "R", "Y", "U", "I", "O", "H", "N", "M"] // Matras that need a base character
        if matras.contains(label) {
            return "◌" + label
        }
        return label
    }

    var body: some View {
        Button(action: action) {
            Text(displayLabel)
                .font(resolveFont(size: 20, fontType: fontType == "Unicode" ? "AnmolLipiSG" : fontType))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(UIColor.systemGray5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color(UIColor.systemGray3), lineWidth: 0.5)
                        )
                )
        }
    }
}

struct MyTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    @Binding var showingPunjabiKeyboard: Bool
    let searchType: SearchType
    let fontType: String
    let placeholder: String

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder

        // Use system font for English/Numeric searches, Gurmukhi font otherwise
        if searchType.needsEnglishKeyboard || searchType.needsNumericKeyboard {
            tf.font = .systemFont(ofSize: 16)
        } else {
            tf.font = resolveFont(size: 16, fontType: fontType == "Unicode" ? "AnmolLipiSG" : fontType)
        }

        tf.textColor = .label
        tf.backgroundColor = .systemGray6
        tf.layer.cornerRadius = 12
        tf.clearButtonMode = .whileEditing
        tf.tintColor = .systemBlue

        // Configure keyboard based on search type
        if searchType.needsEnglishKeyboard {
            tf.keyboardType = .default
            tf.autocorrectionType = .no
            tf.autocapitalizationType = .none
            tf.inputView = nil
            tf.inputAccessoryView = nil
        } else {
            // Punjabi keyboard - hide native keyboard
            tf.inputView = UIView()
            tf.inputAccessoryView = UIView()
        }

        // Left search icon with proper padding
        let iconView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 44))
        let icon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        icon.tintColor = .systemGray
        icon.contentMode = .center
        icon.frame = CGRect(x: 8, y: 12, width: 20, height: 20)
        iconView.addSubview(icon)
        tf.leftView = iconView
        tf.leftViewMode = .always

        // Right padding for clear button
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 44))
        tf.rightViewMode = .always

        tf.delegate = context.coordinator

        // Tap recognizer to set SwiftUI focus with animation
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.didTap))
        tf.addGestureRecognizer(tap)

        return tf
    }

    func updateUIView(_ tf: UITextField, context: Context) {
        tf.text = text
        tf.placeholder = placeholder

        // Update font based on search type
        if searchType.needsEnglishKeyboard || searchType.needsNumericKeyboard {
            tf.font = .systemFont(ofSize: 16)
        } else {
            tf.font = resolveFont(size: 16, fontType: fontType == "Unicode" ? "AnmolLipiSG" : fontType)
        }

        // Update keyboard configuration based on search type
        if searchType.needsEnglishKeyboard {
            tf.keyboardType = .default
            tf.autocorrectionType = .no
            tf.autocapitalizationType = .none
            tf.inputView = nil
            tf.inputAccessoryView = nil
        } else {
            // Punjabi keyboard - hide native keyboard
            tf.inputView = UIView()
            tf.inputAccessoryView = UIView()
        }

        // Update coordinator's searchType
        context.coordinator.searchType = searchType

        if isFocused {
            tf.becomeFirstResponder()
        } else {
            tf.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFocused: $isFocused, showingPunjabiKeyboard: $showingPunjabiKeyboard, searchType: searchType)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        @Binding var isFocused: Bool
        @Binding var showingPunjabiKeyboard: Bool
        var searchType: SearchType

        init(text: Binding<String>, isFocused: Binding<Bool>, showingPunjabiKeyboard: Binding<Bool>, searchType: SearchType) {
            _text = text
            _isFocused = isFocused
            _showingPunjabiKeyboard = showingPunjabiKeyboard
            self.searchType = searchType
        }

        func textFieldDidChangeSelection(_ tf: UITextField) {
            text = tf.text ?? ""
        }

        @objc func didTap() {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                // If already focused, dismiss keyboard
                if isFocused {
                    isFocused = false
                    showingPunjabiKeyboard = false
                } else {
                    // Otherwise, show keyboard
                    isFocused = true
                    // Show custom keyboard for Punjabi and Ang searches
                    if !searchType.needsEnglishKeyboard {
                        showingPunjabiKeyboard = true
                    }
                }
            }
        }

        @objc func dismissKeyboard() {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isFocused = false
                showingPunjabiKeyboard = false
            }
        }
    }
}

func convertToVerse(from searchVerse: SearchVerse) -> Verse {
    return Verse(
        verseId: searchVerse.verseId,
        shabadId: searchVerse.shabadId,
        verse: searchVerse.verse,
        larivaar: searchVerse.larivaar,
        translation: searchVerse.translation,
        transliteration: searchVerse.transliteration,
        pageNo: searchVerse.pageNo,
        lineNo: searchVerse.lineNo,
        updated: searchVerse.updated,
        visraam: searchVerse.visraam
    )
}

// MARK: - Highlighted Text Helper

func createHighlightedAttributedString(text: String, searchQuery: String, searchType: SearchType) -> AttributedString {
    var attributedString = AttributedString(text)

    // For Ang search, no highlighting needed
    if searchType == .ang || searchQuery.isEmpty {
        return attributedString
    }

    let lowercaseText = text.lowercased()
    let lowercaseQuery = searchQuery.lowercased()

    // Handle different search types
    switch searchType {
    case .firstLetterStart, .firstLetterAnywhere, .mainLetter:
        // Highlight matching first letters
        return highlightFirstLettersAttributed(text: text, query: lowercaseQuery)

    case .fullWord, .fullWordTranslation, .romanizedGurmukhi, .romanizedFirstLetter:
        // Highlight full word matches
        return highlightFullWordAttributed(text: text, query: lowercaseQuery)

    default:
        return attributedString
    }
}

func highlightFirstLettersAttributed(text: String, query: String) -> AttributedString {
    var attributedString = AttributedString(text)
    let queryChars = Array(query)

    if queryChars.isEmpty { return attributedString }

    // Build array of words with their positions
    var words: [(text: String, start: String.Index, end: String.Index)] = []
    var currentIndex = text.startIndex

    while currentIndex < text.endIndex {
        // Skip whitespace
        while currentIndex < text.endIndex && text[currentIndex].isWhitespace {
            currentIndex = text.index(after: currentIndex)
        }

        if currentIndex >= text.endIndex { break }

        // Find the end of the current word
        let wordStart = currentIndex
        var wordEnd = currentIndex
        while wordEnd < text.endIndex && !text[wordEnd].isWhitespace {
            wordEnd = text.index(after: wordEnd)
        }

        let wordString = String(text[wordStart ..< wordEnd])
        words.append((text: wordString, start: wordStart, end: wordEnd))
        currentIndex = wordEnd
    }

    // Find consecutive words that match the query
    for startIdx in 0 ..< words.count {
        var matches = true
        var endIdx = startIdx

        // Check if we have enough words left
        if startIdx + queryChars.count > words.count {
            break
        }

        // Check if consecutive words match the query
        for queryIdx in 0 ..< queryChars.count {
            let wordIdx = startIdx + queryIdx
            let word = words[wordIdx]
            let firstChar = getFirstNonMatraChar(from: word.text)

            if firstChar.lowercased() != String(queryChars[queryIdx]).lowercased() {
                matches = false
                break
            }
            endIdx = wordIdx
        }

        // If we found a match, highlight it
        if matches {
            let highlightStart = words[startIdx].start
            let highlightEnd = words[endIdx].end
            let highlightRange = highlightStart ..< highlightEnd

            if let attributedRange = Range<AttributedString.Index>(highlightRange, in: attributedString) {
                attributedString[attributedRange].backgroundColor = Color.orange.opacity(0.25)
                attributedString[attributedRange].foregroundColor = .primary
            }
            break // Only highlight the first match
        }
    }

    return attributedString
}

func highlightFullWordAttributed(text: String, query: String) -> AttributedString {
    var attributedString = AttributedString(text)
    let lowercaseText = text.lowercased()

    // Find all ranges of the query in text
    var searchStartIndex = lowercaseText.startIndex

    while searchStartIndex < lowercaseText.endIndex,
          let range = lowercaseText.range(of: query, range: searchStartIndex ..< lowercaseText.endIndex)
    {
        if let attributedRange = Range<AttributedString.Index>(range, in: attributedString) {
            attributedString[attributedRange].backgroundColor = Color.orange.opacity(0.25)
            attributedString[attributedRange].foregroundColor = .primary
        }

        searchStartIndex = range.upperBound
    }

    return attributedString
}

func getFirstNonMatraChar(from word: String) -> String {
    let matras: Set<Character> = ["i", "o", "u", "w", "y", "H", "I", "M", "N", "O", "R", "U", "W", "Y", "`", "~", "@", "†", "ü", "®", "µ", "æ", "ƒ", "œ", "Í", "Ï", "Ò", "Ú", "§", "¤", "ç", "Î", "ï", "î"]

    for char in word {
        if !matras.contains(char) {
            return String(char)
        }
    }
    return String(word.first ?? " ")
}

enum SearchType: Int, CaseIterable, Identifiable {
    case firstLetterStart = 0
    case firstLetterAnywhere = 1
    case fullWord = 2
    case fullWordTranslation = 3
    case romanizedGurmukhi = 4
    case ang = 5
    case mainLetter = 6
    case romanizedFirstLetter = 7
    case auto = 99 // Special value that won't conflict with API

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .auto: return "Auto"
        case .firstLetterStart: return "First Letter (Start)"
        case .firstLetterAnywhere: return "First Letter (Anywhere)"
        case .fullWord: return "Full Word"
        case .fullWordTranslation: return "Translation"
        case .romanizedGurmukhi: return "Romanized"
        case .ang: return "Ang Number"
        case .mainLetter: return "Main Letter"
        case .romanizedFirstLetter: return "Romanized (Anywhere)"
        }
    }

    var description: String {
        switch self {
        case .auto: return "Automatically detect search type based on input"
        case .firstLetterStart: return "First letter of each word from start"
        case .firstLetterAnywhere: return "First letter of each word anywhere"
        case .fullWord: return "Full word (Gurmukhi)"
        case .fullWordTranslation: return "Full word in translation (English)"
        case .romanizedGurmukhi: return "Romanized Gurmukhi"
        case .ang: return "Search by page number"
        case .mainLetter: return "Main letter (Gurmukhi)"
        case .romanizedFirstLetter: return "Romanized first letter anywhere"
        }
    }

    var needsEnglishKeyboard: Bool {
        return self == .fullWordTranslation || self == .romanizedGurmukhi || self == .romanizedFirstLetter
    }

    var needsNumericKeyboard: Bool {
        return self == .ang
    }
}

// Smart search type detection based on input
func detectSearchType(from input: String) -> SearchType {
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

    // Empty input - default to first letter anywhere
    if trimmed.isEmpty {
        return .firstLetterAnywhere
    }

    // Check if only digits - Ang search
    if trimmed.allSatisfy({ $0.isNumber }) {
        return .ang
    }

    // Define matras (vowel signs that attach to consonants)
    let matras: Set<Character> = [
        "i", "o", "u", "w", "y", "H", "I", "M", "N", "O", "R", "U", "W", "Y",
        "`", "~", "@", "†", "ü", "®", "µ", "æ", "ƒ", "œ", "Í", "Ï", "Ò", "Ú",
        "§", "¤", "ç", "Î", "ï", "î",
    ]

    // Check if contains matras - indicates full word with vowel marks
    let containsMatras = trimmed.contains(where: { matras.contains($0) })

    if containsMatras {
        // Full word search when matras are present
        return .fullWord
    }

    // Default to first letter anywhere for consonant sequences
    return .firstLetterAnywhere
}

struct SearchResultRowView: View {
    let verse: Verse
    let source: Source
    let writer: Writer
    let pageNo: Int?
    let searchQuery: String
    let searchType: SearchType

    @AppStorage("CompactRowViewSetting") private var compactRowViewSetting = false
    @AppStorage("settings.larivaarOn") private var larivaarOn: Bool = true
    @AppStorage("settings.larivaarAssist") private var larivaarAssist: Bool = false
    @AppStorage("fontType") private var fontType: String = "Unicode"

    @Environment(\.colorScheme) private var colorScheme

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

    var gurmukhiAttributedString: AttributedString {
        let fontSize: Double = compactRowViewSetting ? 20.0 : 24.0

        // Apply larivaar assist colors if enabled and in larivaar mode
        if larivaarAssist && larivaarOn {
            // Get the verse text WITH spaces for splitting into words
            let textWithSpaces = fontType == "Unicode" ? verse.verse.unicode : verse.verse.gurmukhi
            let words = textWithSpaces.components(separatedBy: " ")

            // Build attributed string word by word
            var result = AttributedString("")
            for (index, word) in words.enumerated() {
                let color = AppColors.larivaarAssistColor(index: index, for: colorScheme)
                var wordAttr = AttributedString(word)
                wordAttr.foregroundColor = color
                wordAttr.font = resolveFont(size: fontSize, fontType: fontType == "Unicode" ? "AnmolLipiSG" : fontType)
                result = result + wordAttr

                // No spaces in larivaar mode
            }

            // Apply search highlighting (overwrites colors)
            if !searchQuery.isEmpty {
                let fullText = String(result.characters)
                let lowercaseText = fullText.lowercased()
                let lowercaseQuery = searchQuery.lowercased()

                var searchStartIndex = lowercaseText.startIndex
                while searchStartIndex < lowercaseText.endIndex,
                      let range = lowercaseText.range(of: lowercaseQuery, range: searchStartIndex ..< lowercaseText.endIndex)
                {
                    if let attributedRange = Range<AttributedString.Index>(range, in: result) {
                        result[attributedRange].backgroundColor = Color.orange.opacity(0.25)
                        result[attributedRange].foregroundColor = .primary
                    }
                    searchStartIndex = range.upperBound
                }
            }

            return result
        } else {
            // Normal mode (no larivaar assist)
            var attributed = createHighlightedAttributedString(text: gurmukhiText, searchQuery: searchQuery, searchType: searchType)
            attributed.font = resolveFont(size: fontSize, fontType: fontType == "Unicode" ? "AnmolLipiSG" : fontType)
            return attributed
        }
    }

    var translationAttributedString: AttributedString {
        let translation = verse.translation.en.bdb ?? ""

        if searchType == .fullWordTranslation {
            var attributed = createHighlightedAttributedString(text: translation, searchQuery: searchQuery, searchType: searchType)
            attributed.font = .subheadline
            return attributed
        } else {
            var attributed = AttributedString(translation)
            attributed.font = .subheadline
            return attributed
        }
    }

    var body: some View {
        if compactRowViewSetting {
            VStack(alignment: .leading, spacing: 6) {
                Text(gurmukhiAttributedString)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                // Main text content
                VStack(alignment: .leading, spacing: 6) {
                    Text(gurmukhiAttributedString)
                        .fontWeight(.medium)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    if verse.translation.en.bdb != nil {
                        Text(translationAttributedString)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }

                // Metadata badges
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
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
