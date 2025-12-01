//
//  Household.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation

struct Household: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt = "created_at"
    }
}
