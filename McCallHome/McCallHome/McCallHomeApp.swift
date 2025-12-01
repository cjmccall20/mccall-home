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
                await authViewModel.checkSession()
            }
        }
    }
}
