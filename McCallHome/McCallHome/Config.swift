//
//  Config.swift
//  McCallHome
//
//  Created by Cooper McCall on 11/30/25.
//

import Foundation

enum Config {
    static let supabaseURL = URL(string: "https://uzxomgyifkgbfwmcwxbm.supabase.co")!
    static let supabaseAnonKey = "sb_publishable_rcKGDCW76QGA6WqXhQeSHQ_c_iDGbbk"

    // Google Calendar (for later)
    static let googleClientID = "243332420634-da474f55hp2hn68vkbvfbnjg9r0is1j2.apps.googleusercontent.com"

    // MARK: - Development Mode
    // Set to true to skip authentication and use a dev household
    static let skipAuthForDevelopment = true

    // Fixed UUIDs for development mode (these get created in DB if they don't exist)
    static let devHouseholdId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let devUserId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
}
