//
//  Feedback.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import Foundation

struct Feedback: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    let householdId: UUID

    // Feedback content
    var type: FeedbackType
    var title: String
    var description: String

    // Context
    var appVersion: String?
    var iosVersion: String?
    var deviceModel: String?
    var screenName: String?

    // Admin fields (read-only for users)
    var status: FeedbackStatus
    var adminNotes: String?

    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case householdId = "household_id"
        case type
        case title
        case description
        case appVersion = "app_version"
        case iosVersion = "ios_version"
        case deviceModel = "device_model"
        case screenName = "screen_name"
        case status
        case adminNotes = "admin_notes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        householdId: UUID,
        type: FeedbackType = .general,
        title: String,
        description: String,
        appVersion: String? = nil,
        iosVersion: String? = nil,
        deviceModel: String? = nil,
        screenName: String? = nil,
        status: FeedbackStatus = .new,
        adminNotes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.householdId = householdId
        self.type = type
        self.title = title
        self.description = description
        self.appVersion = appVersion
        self.iosVersion = iosVersion
        self.deviceModel = deviceModel
        self.screenName = screenName
        self.status = status
        self.adminNotes = adminNotes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        householdId = try container.decode(UUID.self, forKey: .householdId)

        type = try container.decodeIfPresent(FeedbackType.self, forKey: .type) ?? .general
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)

        appVersion = try container.decodeIfPresent(String.self, forKey: .appVersion)
        iosVersion = try container.decodeIfPresent(String.self, forKey: .iosVersion)
        deviceModel = try container.decodeIfPresent(String.self, forKey: .deviceModel)
        screenName = try container.decodeIfPresent(String.self, forKey: .screenName)

        status = try container.decodeIfPresent(FeedbackStatus.self, forKey: .status) ?? .new
        adminNotes = try container.decodeIfPresent(String.self, forKey: .adminNotes)

        // Handle dates
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            createdAt = dateFormatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString) ?? Date()
        } else {
            createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        }

        if let dateString = try? container.decode(String.self, forKey: .updatedAt) {
            updatedAt = dateFormatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString) ?? Date()
        } else {
            updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        }
    }
}

enum FeedbackType: String, Codable, CaseIterable {
    case bug
    case feature
    case general
    case praise

    var displayName: String {
        switch self {
        case .bug: return "Bug Report"
        case .feature: return "Feature Request"
        case .general: return "General Feedback"
        case .praise: return "Praise"
        }
    }

    var iconName: String {
        switch self {
        case .bug: return "ladybug"
        case .feature: return "lightbulb"
        case .general: return "bubble.left"
        case .praise: return "heart"
        }
    }
}

enum FeedbackStatus: String, Codable, CaseIterable {
    case new
    case reviewed
    case inProgress = "in_progress"
    case resolved
    case wontFix = "wont_fix"

    var displayName: String {
        switch self {
        case .new: return "New"
        case .reviewed: return "Reviewed"
        case .inProgress: return "In Progress"
        case .resolved: return "Resolved"
        case .wontFix: return "Won't Fix"
        }
    }
}
