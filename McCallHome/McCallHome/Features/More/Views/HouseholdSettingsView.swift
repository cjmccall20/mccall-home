//
//  HouseholdSettingsView.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import SwiftUI
import Combine

struct HouseholdSettingsView: View {
    @StateObject private var viewModel = HouseholdSettingsViewModel()
    @State private var showCalendarSetup = false

    var body: some View {
        Form {
            // Calendar Integration
            Section {
                Toggle("Enable Google Calendar", isOn: $viewModel.settings.googleCalendarEnabled)
                    .onChange(of: viewModel.settings.googleCalendarEnabled) { _, newValue in
                        if newValue && !viewModel.hasCalendarConnected {
                            showCalendarSetup = true
                            viewModel.settings.googleCalendarEnabled = false
                        } else if !newValue {
                            Task {
                                await viewModel.disconnectCalendar()
                            }
                        }
                    }

                if viewModel.settings.googleCalendarEnabled {
                    Toggle("Sync meals to calendar", isOn: $viewModel.settings.syncMealsToCalendar)

                    if let calendarId = viewModel.settings.googleCalendarId {
                        HStack {
                            Text("Calendar")
                            Spacer()
                            Text(calendarId)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            } header: {
                Text("Calendar")
            } footer: {
                Text("Connect Google Calendar to sync meal plans and household events.")
            }

            // Meal Times
            Section {
                MealTimePicker(label: "Breakfast", time: $viewModel.settings.breakfastTime)
                MealTimePicker(label: "Lunch", time: $viewModel.settings.lunchTime)
                MealTimePicker(label: "Dinner", time: $viewModel.settings.dinnerTime)
            } header: {
                Text("Default Meal Times")
            } footer: {
                Text("These times are used when syncing meals to your calendar.")
            }

            // Morning Email
            Section {
                Toggle("Morning Email", isOn: $viewModel.settings.morningEmailEnabled)

                if viewModel.settings.morningEmailEnabled {
                    MealTimePicker(label: "Send at", time: $viewModel.settings.morningEmailTime)

                    NavigationLink {
                        EmailRecipientsView(recipients: $viewModel.emailRecipients)
                    } label: {
                        HStack {
                            Text("Recipients")
                            Spacer()
                            Text("\(viewModel.emailRecipients.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Morning Email")
            } footer: {
                Text("Receive a daily email with today's meals, who's cooking, tasks, and calendar events.")
            }

            // Timezone
            Section {
                Picker("Timezone", selection: $viewModel.settings.timezone) {
                    ForEach(commonTimezones, id: \.self) { tz in
                        Text(tz.replacingOccurrences(of: "_", with: " "))
                            .tag(tz)
                    }
                }
            } header: {
                Text("Timezone")
            }
        }
        .navigationTitle("Household Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadSettings()
        }
        .onChange(of: viewModel.settings) { _, _ in
            viewModel.saveSettingsDebounced()
        }
        .sheet(isPresented: $showCalendarSetup) {
            CalendarSetupView(viewModel: viewModel)
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
    }

    private var commonTimezones: [String] {
        [
            "America/New_York",
            "America/Chicago",
            "America/Denver",
            "America/Los_Angeles",
            "America/Phoenix",
            "Pacific/Honolulu",
            "America/Anchorage",
            "America/Detroit",
            "America/Indiana/Indianapolis",
            "America/Kentucky/Louisville"
        ]
    }
}

// MARK: - Meal Time Picker

struct MealTimePicker: View {
    let label: String
    @Binding var time: String

    private var dateBinding: Binding<Date> {
        Binding(
            get: {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                return formatter.date(from: time) ?? Date()
            },
            set: { newDate in
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                time = formatter.string(from: newDate)
            }
        )
    }

    var body: some View {
        DatePicker(
            label,
            selection: dateBinding,
            displayedComponents: .hourAndMinute
        )
    }
}

// MARK: - Email Recipients View

struct EmailRecipientsView: View {
    @Binding var recipients: [String]
    @State private var newEmail = ""

    var body: some View {
        List {
            Section {
                ForEach(recipients, id: \.self) { email in
                    Text(email)
                }
                .onDelete { indexSet in
                    recipients.remove(atOffsets: indexSet)
                }
            }

            Section {
                HStack {
                    TextField("Email address", text: $newEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    Button("Add") {
                        if !newEmail.isEmpty && newEmail.contains("@") {
                            recipients.append(newEmail.lowercased())
                            newEmail = ""
                        }
                    }
                    .disabled(newEmail.isEmpty || !newEmail.contains("@"))
                }
            }
        }
        .navigationTitle("Email Recipients")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Calendar Setup View

struct CalendarSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: HouseholdSettingsViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Connect Google Calendar")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Sign in with your Google account to sync your meal plan with your calendar.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button {
                    viewModel.startGoogleSignIn()
                } label: {
                    HStack {
                        Image(systemName: "g.circle.fill")
                        Text("Sign in with Google")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("Calendar Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - ViewModel

@MainActor
class HouseholdSettingsViewModel: ObservableObject {
    @Published var settings = HouseholdSettings(householdId: UUID())
    @Published var emailRecipients: [String] = []
    @Published var isLoading = false
    @Published var error: String?

    private let settingsService = HouseholdSettingsService.shared
    private let authService = AuthService.shared
    private var saveTask: Task<Void, Never>?

    var hasCalendarConnected: Bool {
        settings.googleCalendarId != nil
    }

    func loadSettings() async {
        guard let householdId = authService.currentUser?.householdId else { return }

        isLoading = true
        do {
            settings = try await settingsService.fetchSettings(for: householdId)
            emailRecipients = settings.morningEmailRecipients ?? []
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func saveSettingsDebounced() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await saveSettings()
        }
    }

    private func saveSettings() async {
        var updated = settings
        updated.morningEmailRecipients = emailRecipients.isEmpty ? nil : emailRecipients

        do {
            try await settingsService.updateSettings(updated)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func disconnectCalendar() async {
        guard let householdId = authService.currentUser?.householdId else { return }

        do {
            try await settingsService.clearGoogleCalendar(for: householdId)
            settings.googleCalendarEnabled = false
            settings.googleCalendarId = nil
            settings.syncMealsToCalendar = false
        } catch {
            self.error = error.localizedDescription
        }
    }

    func startGoogleSignIn() {
        // This will be implemented with Google Sign-In SDK
        // For now, show a placeholder
        error = "Google Sign-In will be configured in the next step"
    }
}

#Preview {
    NavigationStack {
        HouseholdSettingsView()
    }
}
