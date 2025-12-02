//
//  User.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: UUID
    let householdId: UUID
    var name: String
    let email: String
    var notificationTimes: [String]?
    var deviceToken: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case name
        case email
        case notificationTimes = "notification_times"
        case deviceToken = "device_token"
        case createdAt = "created_at"
    }

    init(id: UUID, householdId: UUID, name: String, email: String, notificationTimes: [String]? = nil, deviceToken: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.householdId = householdId
        self.name = name
        self.email = email
        self.notificationTimes = notificationTimes
        self.deviceToken = deviceToken
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        householdId = try container.decode(UUID.self, forKey: .householdId)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        notificationTimes = try container.decodeIfPresent([String].self, forKey: .notificationTimes)
        deviceToken = try container.decodeIfPresent(String.self, forKey: .deviceToken)

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
