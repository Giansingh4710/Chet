import SwiftUI
import WidgetKit

struct SettingsView: View {
    @AppStorage("CompactRowViewSetting") private var compactRowViewSetting = false
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    @AppStorage("refreshInterval", store: UserDefaults.appGroup) var refreshInterval: Int = 3 // default: every 3 hours

    @State private var randSbdLst: [RandSbdForWidget] = []

    var body: some View {
        NavigationView {
            List {
                // Row 1: Compact Row Toggle
                Section {
                    Toggle("Compact Row View", isOn: $compactRowViewSetting)
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
                        .frame(width: 180) // keeps it compact
                    }
                }

                Section("Random Shabad Widget") {
                    if randSbdLst.isEmpty {
                        Text("No Random Shabad Widget yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(randSbdLst, id: \.index) { item in
                            NavigationLink(destination: ShabadViewDisplayWrapper(sbdRes: item.sbd, indexOfLine: 0)) {
                                HStack {
                                    Text(item.sbd.shabad[0].line.gurmukhi.unicode) // Shabad text
                                        .lineLimit(1)
                                    Spacer()
                                    Text(item.date, style: .time) // Scheduled time
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    Button("Regenerate Random Shabads For Widgets") {
                        Task {
                            var newList: [RandSbdForWidget] = await getRandShabads(interval: refreshInterval)
                            randSbdLst = newList
                            WidgetCenter.shared.reloadTimelines(ofKind: "xyz.gians.Chet.RandomShabadWidget") // Ask widget to refresh
                        }
                    }

                    Picker("Refresh Interval", selection: $refreshInterval) {
                        Text("1 hour").tag(1)
                        Text("3 hours").tag(3)
                        Text("6 hours").tag(6)
                        Text("12 hours").tag(12)
                        Text("24 hours").tag(24)
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .onAppear {
            loadHistory()
        }
    }

    private func loadHistory() {
        if let historyData = UserDefaults.appGroup.data(forKey: "randShabadList"),
           let decoded = try? JSONDecoder().decode([RandSbdForWidget].self, from: historyData)
        {
            randSbdLst = decoded
            print("Loaded \(randSbdLst.count) Random Shabad Widget")
            for (index, item) in randSbdLst.enumerated() {
                print("Item \(index), \(item.index): \(item.sbd.shabad[0].line.gurmukhi.unicode)")
            }
        } else {
            randSbdLst = []
            print("No history found for Random Shabad Widget")
        }
    }
}
