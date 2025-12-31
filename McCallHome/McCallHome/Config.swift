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

    // Instacart Developer Platform API Key
    // Sign up at: https://www.instacart.com/company/business/developers
    static let instacartAPIKey: String? = nil  // TODO: Add your Instacart API key

    // MARK: - Development Mode
    // Set to true to auto-sign-in with dev credentials (no manual login needed)
    static let skipAuthForDevelopment = false

    // Dev account credentials - auto signs in so RLS policies work
    // Use your real Supabase account here
    static let devEmail = "fmcjmccall12@gmail.com"
    static let devPassword = Secrets.devPassword  // Set in Secrets.swift (gitignored)

    // Fallback UUIDs if auto-sign-in fails
    static let devHouseholdId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let devUserId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
}
