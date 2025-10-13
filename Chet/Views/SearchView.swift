import SwiftData
import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var results: [SearchVerse] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isSearchFieldFocused: Bool
    @Environment(\.modelContext) private var modelContext

    @State private var selectedShabad: ShabadAPIResponse?
    @State private var isNavigating = false

    @State private var showingPunjabiKeyboard = false

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
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text("Search Error")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if results.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No Results Found")
                            .font(.headline)
                        Text("Try searching with different keywords")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        Text("Search Gurbani")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Enter keywords to search for shabads")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            Button(action: {
                                Task { await openRandomShabad() }
                            }) {
                                Image(systemName: "shuffle")
                                Text("Random Shabad")
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Darbar Sahib Hukamnama") {
                                Task { await openHukamnama() }
                            }
                            .buttonStyle(.bordered)
                        }
                        .navigationDestination(isPresented: $isNavigating) {
                            if let sbd = selectedShabad {
                                ShabadViewDisplayWrapper(sbdRes: sbd, indexOfLine: 0)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(results) { searchedLine in
                        NavigationLink(destination: ShabadViewFromSearchedLine(
                            searchedLine: searchedLine
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(searchedLine.verse.unicode)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .lineLimit(3)
                                        .multilineTextAlignment(.leading)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("Ang \(String(searchedLine.pageNo))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Text(searchedLine.translation.en.bdb)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .listStyle(PlainListStyle())
                }
            }

            HStack(spacing: 16) {
                // Search text field
                TextField("cyq", text: $searchText, onCommit: {
                    Task { await fetchResults() }
                })
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .font(.custom("AnmolLipiBoldTrue", size: 16))
                .focused($isSearchFieldFocused)

                // Clear button
                if !searchText.isEmpty {
                    Button(action: {
                        searchText.removeLast()
                    }) {
                        Image(systemName: "delete.left.fill")
                            .foregroundColor(.gray)
                    }

                    Button(action: {
                        searchText = ""
                        results = []
                        errorMessage = nil
                        isSearchFieldFocused = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }

                // Punjabi keyboard toggle
                Button(action: {
                    withAnimation(.spring()) {
                        showingPunjabiKeyboard.toggle()
                        isSearchFieldFocused = false
                    }
                }) {
                    Image(systemName: "keyboard")
                        .foregroundColor(showingPunjabiKeyboard ? .blue : .gray)
                        .animation(.spring(), value: showingPunjabiKeyboard)
                }

                // Search button
                Button(action: {
                    Task { await fetchResults() }
                    showingPunjabiKeyboard = false
                    isSearchFieldFocused = false
                }) {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .cornerRadius(12)
                .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 5)
            .background(Color(.systemGray6))
            .cornerRadius(10) // pill shape
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
            .padding(.horizontal)
            .offset(y: -20)

            if showingPunjabiKeyboard {
                PunjabiKeyboardView { key in
                    if key == "\u{232B}" {
                        if !searchText.isEmpty { searchText.removeLast() }
                    } else {
                        searchText.append(key)
                    }
                }
                .onChange(of: isSearchFieldFocused) { newValue in
                    if newValue { showingPunjabiKeyboard = false }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .background(Color(.systemBackground)).shadow(radius: 5)
            }
        }
        .navigationTitle(!results.isEmpty ? "\(results.count) results" : "Gurbani Search")
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
            let decoded = try await searchGurbani(from: searchText)
            results = decoded.verses
            isLoading = false
        } catch {
            errorMessage = "Failed to fetch results: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func openRandomShabad() async {
        if let response = await fetchRandomShabad() {
            selectedShabad = response
            isNavigating = true
            let sbdHistory = ShabadHistory(sbdRes: response, indexOfSelectedLine: 0)
            addToHistory(sbdHistory: sbdHistory)
        }
    }

    private func openHukamnama() async {
        if let hukam = await fetchHukam() {
            isNavigating = true
            // selectedShabad = hukam
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

struct PunjabiKeyboardView: View {
    let onKeyPress: (String) -> Void

    private let rows: [[String]] = [
        ["a", "A", "e", "s", "h", "k", "K", "g", "G", "|"],
        ["c", "C", "j", "J", "\\", "t", "T", "f", "F", "x"],
        ["q", "Q", "d", "D", "n", "p", "P", "b", "B", "m"],
        ["X", "r", "l", "v", "V", "S", "^", "Z", "z", "&"],
    ]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(Array(row.enumerated()), id: \.offset) { index, key in
                        KeyButton(label: key) {
                            onKeyPress(key)
                        }

                        // Insert a grouping gap every 5 keys
                        if (index + 1) % 5 == 0 && index != row.count - 1 {
                            Spacer(minLength: 14) // creates the gap
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(Color(UIColor.systemGray6))
    }
}

struct KeyButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.custom("AnmolLipiBoldTrue", size: 20))
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

