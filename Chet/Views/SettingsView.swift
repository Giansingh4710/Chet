import SwiftData
import SwiftUI
import WidgetKit

struct SettingsView: View {
    @AppStorage("CompactRowViewSetting") private var compactRowViewSetting = false
    @AppStorage("swipeToGoToNextShabadSetting") private var swipeToGoToNextShabadSetting = true
    @AppStorage("colorScheme") private var colorScheme: String = "system"

    @AppStorage("randSbdRefreshInterval", store: UserDefaults.appGroup) var randSbdRefreshInterval: Int = 3 // default: every 3 hours
    @AppStorage("favSbdRefreshInterval", store: UserDefaults.appGroup) private var favSbdRefreshInterval: Int = 3
    @AppStorage("favSbdFolderName", store: UserDefaults.appGroup) private var favSbdFolderName: String = default_fav_widget_folder_name
    @Query private var allFolders: [Folder]
    @Query(sort: \ShabadHistory.dateViewed, order: .reverse) var histories: [ShabadHistory]

    @AppStorage("larivaar") private var larivaarOn: Bool = true
    @AppStorage("fontType") private var fontType: String = "Unicode"

    @State private var randSbdLst: [RandSbdForWidget] = []
    @State private var widgetShabads: [SavedShabad] = []
    @Environment(\.modelContext) private var context

    @State private var infoType: InfoType?
    @State private var showDeleteHistoryAlert = false

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    HStack {
                        Toggle("Compact Row View", isOn: $compactRowViewSetting)
                        Spacer()
                        infoButton(.compactRow)
                    }
                    HStack {
                        Toggle("Swipe to go to next shabad", isOn: $swipeToGoToNextShabadSetting)
                    }
                    HStack {
                        Toggle("Larivaar", isOn: $larivaarOn)
                    }
                    FontPicker()
                    Button("Delete all history", role: .destructive) {
                        showDeleteHistoryAlert = true
                    }
                    .alert("Are you sure?", isPresented: $showDeleteHistoryAlert) {
                        Button("Delete All", role: .destructive) {
                            for history in histories {
                                context.delete(history)
                            }
                            try? context.save()
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                }

                // Row 2: Dark Mode Picker
                Section {
                    HStack {
                        Text("Appearance")
                        Spacer()
                        Picker("", selection: $colorScheme) {
                            Text("System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                        infoButton(.appearance)
                    }
                }

                // Random Shabad Widget
                Section("Random Shabad Widget") {
                    if randSbdLst.isEmpty {
                        Text("No Random Shabad Widget yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(randSbdLst, id: \.index) { item in
                            NavigationLink(destination: ShabadViewDisplayWrapper(sbdRes: item.sbd, indexOfLine: 0)) {
                                HStack {
                                    Text(item.sbd.verses[0].verse.unicode)
                                        .lineLimit(1)
                                    Spacer()
                                    Text(item.date, style: .time)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    HStack {
                        Picker("Get New Shabad Every", selection: $randSbdRefreshInterval) {
                            Text("1 hour").tag(1)
                            Text("3 hours").tag(3)
                            Text("6 hours").tag(6)
                            Text("12 hours").tag(12)
                            Text("24 hours").tag(24)
                        }
                        infoButton(.randSbdRefreshInterval)
                    }
                    .onChange(of: randSbdRefreshInterval) { newValue in
                        Task {
                            await updateRandWidgetSbds(interval: newValue)
                        }
                    }

                    Button(action: {
                        Task { await updateRandWidgetSbds(interval: randSbdRefreshInterval) }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                        .font(.body)
                    }
                }

                Section("Favorite Shabad Widget") {
                    if widgetShabads.isEmpty {
                        Text("No Shabads in '\(favSbdFolderName)' folder")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(widgetShabads) { svdSbd in
                            NavigationLink(destination: ShabadViewDisplayWrapper(sbdRes: svdSbd.sbdRes, indexOfLine: svdSbd.indexOfSelectedLine, onIndexChange: { newIndex in
                                svdSbd.indexOfSelectedLine = newIndex
                            })) {
                                HStack {
                                    Text(svdSbd.sbdRes.verses[svdSbd.indexOfSelectedLine].verse.unicode)
                                        .lineLimit(1)
                                    Spacer()
                                }
                            }
                        }
                    }

                    HStack {
                        Picker("Get New Shabad every", selection: $favSbdRefreshInterval) {
                            Text("1 hour").tag(1)
                            Text("3 hours").tag(3)
                            Text("6 hours").tag(6)
                            Text("12 hours").tag(12)
                            Text("24 hours").tag(24)
                        }
                        infoButton(.favSbdRefreshInterval)
                    }
                    .onChange(of: favSbdRefreshInterval) { _ in
                        WidgetCenter.shared.reloadTimelines(ofKind: "xyz.gians.Chet.FavShabadsWidget") // Ask widget to refresh
                    }

                    HStack {
                        Picker("Folder for 'Favorite Shabads' Widget", selection: $favSbdFolderName) {
                            ForEach(allFolders, id: \.self) { folder in
                                Text(folder.name) // show folder name
                                    .tag(folder.name) // bind value to AppStorage
                            }
                        }
                        infoButton(.favSbdFolderName)
                    }
                    .onChange(of: favSbdFolderName) { newFolderName in
                        loadWidgetShabads(newFolderName)
                        WidgetCenter.shared.reloadTimelines(ofKind: "xyz.gians.Chet.FavShabadsWidget") // Ask widget to refresh
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            loadRandSbds()
            loadWidgetShabads()
            for folder in allFolders {
                print("Folder name: \(folder.name) parent: \(folder.parentFolder?.name ?? "nil")")
            }
        }
        .alert(item: $infoType) { type in
            Alert(title: Text("Info"), message: Text(type.message), dismissButton: .default(Text("OK")))
        }
    }

    // Info button factory
    private func infoButton(_ type: InfoType) -> some View {
        Button {
            infoType = type
        } label: {
            Image(systemName: "info.circle")
                .foregroundColor(.blue)
        }
        .buttonStyle(.plain)
    }

    private func updateRandWidgetSbds(interval: Int) async {
        let newList: [RandSbdForWidget] = await getRandShabads(interval: interval)
        randSbdLst = newList
        WidgetCenter.shared.reloadTimelines(ofKind: "xyz.gians.Chet.RandomShabadWidget") // Ask widget to refresh
    }

    private func loadRandSbds() {
        if let historyData = UserDefaults.appGroup.array(forKey: "randShabadList") as? [Data] {
            randSbdLst = historyData.compactMap { try? JSONDecoder().decode(RandSbdForWidget.self, from: $0) }
            print("Loaded \(randSbdLst.count) Random Shabad Widget")
        }
    }

    private func loadWidgetShabads(_ folderName: String = "") {
        let fldName = folderName.isEmpty ? favSbdFolderName : folderName
        if let folder = allFolders.first(where: { $0.name == fldName }) {
            let folderID = folder.id // <-- capture as plain UUID
            let descriptor = FetchDescriptor<SavedShabad>(
                predicate: #Predicate { $0.folder?.id == folderID },
                sortBy: [SortDescriptor(\.sortIndex)]
            )
            widgetShabads = (try? context.fetch(descriptor)) ?? []
        } else {
            widgetShabads = []
        }
    }
}

enum InfoType: Identifiable {
    case compactRow
    case appearance
    case randSbdRefreshInterval
    case favSbdRefreshInterval
    case favSbdFolderName

    var id: Int {
        hashValue
    }

    var message: String {
        switch self {
        case .compactRow:
            return "Compact Row View shows less spacing between rows so more can fit on the screen."
        case .appearance:
            return "Appearance lets you choose between following the system theme, light mode, or dark mode."
        case .randSbdRefreshInterval:
            return "This determines how often new random Shabads are generated for the widget."
        case .favSbdRefreshInterval:
            return "This determines how often the shabads in your chosen folder switch in your widget."
        case .favSbdFolderName:
            return "The folder you choose will be used to display the shabads in the 'Favorite Shabads' widget."
        }
    }
}
