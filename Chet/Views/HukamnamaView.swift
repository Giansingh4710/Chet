import SwiftData
import SwiftUI

struct HukamnamaView: View {
    @State private var hukamnamaResponse: HukamnamaAPIResponse?
    @State private var selectedDate = Date()
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showDatePicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView("Loading Hukamnama...")
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Retry") {
                            Task { await fetchHukamnama(for: selectedDate) }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else if let response = hukamnamaResponse {
                    HukamnamaDisplayView(
                        hukamnamaResponse: response,
                        selectedDate: $selectedDate,
                        showDatePicker: $showDatePicker,
                        onDateChange: { newDate in
                            Task { await fetchHukamnama(for: newDate) }
                        }
                    )
                }
            }
            .navigationTitle("Hukamnama")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showDatePicker = true
                    } label: {
                        Image(systemName: "calendar")
                    }
                }
            }
            .sheet(isPresented: $showDatePicker) {
                HukamnamaDatePickerSheet(
                    selectedDate: $selectedDate,
                    onConfirm: {
                        Task { await fetchHukamnama(for: selectedDate) }
                    }
                )
                .presentationDetents([.medium])
            }
            .task {
                await fetchHukamnama(for: selectedDate)
            }
        }
    }

    private func fetchHukamnama(for date: Date) async {
        isLoading = true
        errorMessage = nil

        do {
            let data = try await fetchHukam(for: date)
            await MainActor.run {
                isLoading = false
                hukamnamaResponse = data
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to fetch Hukamnama: \(error.localizedDescription)"
            }
        }
    }
}

struct HukamnamaDisplayView: View {
    let hukamnamaResponse: HukamnamaAPIResponse
    @Binding var selectedDate: Date
    @Binding var showDatePicker: Bool
    var onDateChange: (Date) -> Void

    @State private var indexOfLine: Int = 0

    // private var currentShabad: ShabadAPIResponse {
    //     hukamnamaResponse.shabads[currentShabadIndex]
    // }

    private var combinedShabad: ShabadAPIResponse {
        getSbdObjFromHukamObj(hukamObj: hukamnamaResponse)
    }

    var body: some View {
        ZStack {
            // Main content using ShabadViewDisplay
            ShabadViewDisplay(
                sbdRes: combinedShabad,
                fetchNewShabad: { _ in }, // Not used for Hukamnama
                indexOfLine: indexOfLine
            )

            // Custom navigation overlay for date navigation
            VStack {
                Spacer()
                HStack {
                    // Previous Day Button
                    Button {
                        navigateToPreviousDay()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    // Date Display
                    Button {
                        showDatePicker = true
                    } label: {
                        VStack(spacing: 2) {
                            Text(dateFormatter.string(from: selectedDate))
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }

                    Spacer()

                    // Next Day Button (only if not today)
                    if !Calendar.current.isDateInToday(selectedDate) {
                        Button {
                            navigateToNextDay()
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                .frame(width: 44, height: 44)
                        }
                    } else {
                        Spacer().frame(width: 44)
                    }
                }
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }

    private func navigateToPreviousDay() {
        guard let newDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) else { return }
        selectedDate = newDate
        onDateChange(newDate)
    }

    private func navigateToNextDay() {
        // Don't go beyond today
        let today = Calendar.current.startOfDay(for: Date())
        let currentDay = Calendar.current.startOfDay(for: selectedDate)

        guard currentDay < today else { return }

        guard let newDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) else { return }

        // Make sure we don't go past today
        if Calendar.current.startOfDay(for: newDate) <= today {
            selectedDate = newDate
            onDateChange(newDate)
        }
    }
}

struct HukamnamaDatePickerSheet: View {
    @Binding var selectedDate: Date
    var onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    // let dateRange = Calendar.current.date(from: DateComponents(year: 2002, month: 1, day: 1))! ... Date()
    let dateRange = Calendar.current.date(from: DateComponents(year: 2002, month: 1, day: 1))! ... Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                DatePicker(
                    "Select a date to view past Hukamnama",
                    selection: $selectedDate,
                    in: dateRange, // 2002 → today
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()

                Spacer()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Load") {
                        onConfirm()
                        dismiss()
                    }
                }
            }
        }
    }
}

// Preview
#Preview {
    HukamnamaView()
}
