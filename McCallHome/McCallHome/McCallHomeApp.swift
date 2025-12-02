//
//  McCallHomeApp.swift
//  McCallHome
//
//  Created by Cooper McCall on 11/30/25.
//

import SwiftUI
import Supabase

@main
struct McCallHomeApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var pendingInviteToken: String?

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
            .task {
                if Config.skipAuthForDevelopment {
                    // Dev mode: skip auth, go straight to main app
                    await AuthService.shared.setupDevMode()
                } else {
                    await authViewModel.checkSession()
                }
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .sheet(item: $pendingInviteToken) { token in
                InviteAcceptView(token: token)
                    .environmentObject(authViewModel)
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        // Handle invitation deep links: mccallhome://invite?token=xxx
        guard url.scheme == "mccallhome" else { return }

        switch url.host {
        case "invite":
            if let token = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "token" })?
                .value {
                pendingInviteToken = token
            }
        default:
            break
        }
    }
}

// Make String identifiable for sheet binding
extension String: @retroactive Identifiable {
    public var id: String { self }
}
