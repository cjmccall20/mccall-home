//
//  McCallHomeApp.swift
//  McCallHome
//
//  Created by Cooper McCall on 11/30/25.
//

import SwiftUI
import Supabase
import GoogleSignIn

@main
struct McCallHomeApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var appearanceManager = AppearanceManager.shared
    @State private var pendingInviteToken: String?
    @State private var pendingHouseholdJoin: UUID?
    @State private var showUpdatePassword = false

    init() {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: Config.googleClientID)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    MainTabView()
                        .environmentObject(authViewModel)
                } else {
                    AuthContainerView()
                        .environmentObject(authViewModel)
                }
            }
            .applyAppearance()
            .task {
                if Config.skipAuthForDevelopment {
                    // Dev mode: skip auth, go straight to main app
                    await AuthService.shared.setupDevMode()
                } else {
                    await authViewModel.checkSession()
                    // Process any pending household join for returning users
                    if authViewModel.isAuthenticated {
                        await AuthService.shared.processPendingHouseholdJoin()
                    }
                }
            }
            .onOpenURL { url in
                // Give the Google sign-in flow first crack at its callback URL
                if GIDSignIn.sharedInstance.handle(url) {
                    return
                }
                handleDeepLink(url)
            }
            .sheet(item: $pendingInviteToken) { token in
                InviteAcceptView(token: token)
                    .environmentObject(authViewModel)
            }
            .sheet(item: $pendingHouseholdJoin) { householdId in
                JoinHouseholdView(householdId: householdId)
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showUpdatePassword) {
                UpdatePasswordView()
                    .environmentObject(authViewModel)
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        // Handle deep links: homerun://invite?token=xxx or homerun://join?household=xxx or homerun://reset-password
        guard url.scheme == "homerun" else { return }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        switch url.host {
        case "invite":
            if let token = components?.queryItems?.first(where: { $0.name == "token" })?.value {
                pendingInviteToken = token
            }
        case "join":
            if let householdIdString = components?.queryItems?.first(where: { $0.name == "household" })?.value,
               let householdId = UUID(uuidString: householdIdString) {
                pendingHouseholdJoin = householdId
            }
        case "reset-password":
            // User clicked password reset link - show update password sheet
            showUpdatePassword = true
        default:
            break
        }
    }
}

// Make String identifiable for sheet binding
extension String: @retroactive Identifiable {
    public var id: String { self }
}

// Make UUID identifiable for sheet binding
extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}
