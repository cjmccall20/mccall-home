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
}
