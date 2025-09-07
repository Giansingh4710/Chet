import SwiftUI
import SwiftData

struct SearchView: View {
    @State private var searchText = "qkml"
    @State private var results: [LineObjFromSearch] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Search header
            VStack(spacing: 16) {
                HStack {
                    TextField(
                        "Search Gurbani…",
                        text: $searchText,
                        onCommit: {
                            Task {
                                await fetchResults()
                            }
                        }
                    )
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isSearchFieldFocused)

                    Button(action: {
                        Task {
                            await fetchResults()
                        }
                    }) {
                        Text("Search")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
            .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.1), radius: 1, x: 0, y: 1)

            // Content area
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
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(results) { line in
                        NavigationLink(destination: ShabadViewFromSearchedLine(
                            searchedLine: line
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(line.gurmukhi.unicode)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .lineLimit(3)
                                        .multilineTextAlignment(.leading)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(line.id)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Text(line.translation.english.default)
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
            .navigationTitle("Gurbani Search")
            .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemGroupedBackground))
//            .onChange(of: searchState.shouldResetSearch) { _, newValue in
//                if newValue {
//                    searchText = ""
//                    isSearchFieldFocused = true
//                    // Force keyboard to appear
//                    UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
//                }
//            }
        }
    }

    private func fetchResults() async {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isLoading = true
        errorMessage = nil

        let urlString = "https://data.gurbaninow.com/v2/search/\(searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchText)"

        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200 ... 299).contains(httpResponse.statusCode)
            else {
                throw URLError(.badServerResponse)
            }

            let decoded = try JSONDecoder().decode(GurbaniSearchAPIResponse.self, from: data)
            await MainActor.run {
                results = decoded.shabads.map { $0.shabad }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to fetch results: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

struct ShabadViewFromSearchedLine: View {
    let searchedLine: LineObjFromSearch

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
            } else if let sbdHistory = sbdHistory {
                ShabadViewDisplayWrapper(sbdHistory: sbdHistory)
            }
        }
        .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemGroupedBackground))
        .task {
            await fetchFullShabad()
        }
    }

    private func fetchFullShabad() async {
        let urlString = "https://data.gurbaninow.com/v2/shabad/\(searchedLine.shabadid)"
        let foundByLineID = searchedLine.id
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
            guard let aindexOfLine = decoded.shabad.firstIndex(where: { $0.line.id == foundByLineID }) else {
                throw URLError(.badServerResponse)
            }
            await MainActor.run {
                isLoadingShabad = false
                sbdHistory = ShabadHistory(sbdRes: decoded, indexOfSelectedLine: aindexOfLine)
                indexOfLine = aindexOfLine
                addToHistory()
            }
        } catch {
            await MainActor.run {
                isLoadingShabad = false
                errorMessage = "Failed to fetch shabad: \(error.localizedDescription)"
                print(error)
                print(searchedLine.id, " ", searchedLine.shabadid)
                print(error.localizedDescription)
                print(url)
            }
        }
    }

    private func addToHistory() {
        guard let sbdHist = sbdHistory else { return }

        let shabadID = sbdHist.sbdRes.shabadinfo.shabadid
        let descriptor = FetchDescriptor<ShabadHistory>(
            predicate: #Predicate { $0.shabadID == shabadID }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.dateViewed = Date()
        } else {
            modelContext.insert(sbdHist)
        }

        try? modelContext.save()
    }
}
