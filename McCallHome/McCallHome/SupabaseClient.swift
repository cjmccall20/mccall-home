//
//  SupabaseClient.swift
//  McCallHome
//
//  Created by Cooper McCall on 11/30/25.
//

import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: Config.supabaseURL,
    supabaseKey: Config.supabaseAnonKey
)
