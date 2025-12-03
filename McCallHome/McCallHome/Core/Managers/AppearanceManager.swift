//
//  AppearanceManager.swift
//  McCallHome
//
//  Created by Claude on 12/3/25.
//

import SwiftUI
import Combine

/// Manages app appearance settings including dark mode
@MainActor
class AppearanceManager: ObservableObject {
    static let shared = AppearanceManager()

    @Published var appearanceMode: HouseholdSettings.AppearanceMode = .system

    /// The preferred color scheme based on the appearance mode
    var preferredColorScheme: ColorScheme? {
        switch appearanceMode {
        case .system:
            return nil  // Use system setting
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    private let settingsService = HouseholdSettingsService.shared
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Listen for auth changes to load settings
        authService.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                if user != nil {
                    Task {
                        await self?.loadSettings()
                    }
                }
            }
            .store(in: &cancellables)
    }

    /// Load appearance settings from household settings
    func loadSettings() async {
        guard let householdId = authService.currentUser?.householdId else { return }

        do {
            let settings = try await settingsService.fetchSettings(for: householdId)
            appearanceMode = settings.darkMode
        } catch {
            // Use default (system) on error
            appearanceMode = .system
        }
    }

    /// Update appearance mode
    func setAppearanceMode(_ mode: HouseholdSettings.AppearanceMode) async {
        guard let householdId = authService.currentUser?.householdId else { return }

        appearanceMode = mode

        do {
            try await settingsService.updateDarkMode(for: householdId, mode: mode)
        } catch {
            // Revert on error
            await loadSettings()
        }
    }
}

/// View modifier to apply the preferred color scheme
struct AppearanceModifier: ViewModifier {
    @ObservedObject var manager = AppearanceManager.shared

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(manager.preferredColorScheme)
    }
}

extension View {
    /// Apply the app's preferred appearance settings
    func applyAppearance() -> some View {
        modifier(AppearanceModifier())
    }
}
