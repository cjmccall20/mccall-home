//
//  HouseholdMember.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import Foundation

struct HouseholdMember: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let householdId: UUID
    var name: String
    var email: String?
    var isActive: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case name
        case email
        case isActive = "is_active"
        case createdAt = "created_at"
    }

    init(id: UUID = UUID(), householdId: UUID, name: String, email: String? = nil, isActive: Bool = true, createdAt: Date = Date()) {
        self.id = id
        self.householdId = householdId
        self.name = name
        self.email = email
        self.isActive = isActive
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        householdId = try container.decode(UUID.self, forKey: .householdId)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true

        // Handle date - may have fractional seconds
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                createdAt = date
            } else if let date = ISO8601DateFormatter().date(from: dateString) {
                createdAt = date
            } else {
                createdAt = Date()
            }
        } else {
            createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        }
    }
}

// MARK: - Display Helpers

extension HouseholdMember {
    /// Display name with optional indicator for current user
    var displayName: String {
        name
    }

    /// First initial for avatars
    var initial: String {
        String(name.prefix(1)).uppercased()
    }
}
