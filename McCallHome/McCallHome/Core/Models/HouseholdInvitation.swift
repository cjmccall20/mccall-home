//
//  HouseholdInvitation.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import Foundation

struct HouseholdInvitation: Codable, Identifiable, Equatable {
    let id: UUID
    let householdId: UUID

    // Invitation details
    let email: String
    let invitedBy: UUID
    let token: String

    // Status tracking
    var status: InvitationStatus
    let expiresAt: Date

    // Response tracking
    var respondedAt: Date?
    var acceptedBy: UUID?

    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case email
        case invitedBy = "invited_by"
        case token
        case status
        case expiresAt = "expires_at"
        case respondedAt = "responded_at"
        case acceptedBy = "accepted_by"
        case createdAt = "created_at"
    }

    init(
        id: UUID = UUID(),
        householdId: UUID,
        email: String,
        invitedBy: UUID,
        token: String = "",
        status: InvitationStatus = .pending,
        expiresAt: Date = Date().addingTimeInterval(7 * 24 * 60 * 60),
        respondedAt: Date? = nil,
        acceptedBy: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.householdId = householdId
        self.email = email
        self.invitedBy = invitedBy
        self.token = token
        self.status = status
        self.expiresAt = expiresAt
        self.respondedAt = respondedAt
        self.acceptedBy = acceptedBy
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        householdId = try container.decode(UUID.self, forKey: .householdId)
        email = try container.decode(String.self, forKey: .email)
        invitedBy = try container.decode(UUID.self, forKey: .invitedBy)
        token = try container.decode(String.self, forKey: .token)
        status = try container.decodeIfPresent(InvitationStatus.self, forKey: .status) ?? .pending
        acceptedBy = try container.decodeIfPresent(UUID.self, forKey: .acceptedBy)

        // Handle dates
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let dateString = try? container.decode(String.self, forKey: .expiresAt) {
            expiresAt = dateFormatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString) ?? Date()
        } else {
            expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt) ?? Date()
        }

        if let dateString = try? container.decode(String.self, forKey: .respondedAt) {
            respondedAt = dateFormatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString)
        } else {
            respondedAt = try container.decodeIfPresent(Date.self, forKey: .respondedAt)
        }

        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            createdAt = dateFormatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString) ?? Date()
        } else {
            createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        }
    }

    var isExpired: Bool {
        expiresAt < Date()
    }

    var isValid: Bool {
        status == .pending && !isExpired
    }
}

enum InvitationStatus: String, Codable, CaseIterable {
    case pending
    case accepted
    case declined
    case expired
    case revoked

    var displayName: String {
        rawValue.capitalized
    }
}

// Response from get_invitation_by_token function
struct InvitationDetails: Codable {
    let found: Bool
    let id: UUID?
    let email: String?
    let status: String?
    let expiresAt: String?
    let householdName: String?
    let invitedByName: String?
    let isValid: Bool?

    enum CodingKeys: String, CodingKey {
        case found
        case id
        case email
        case status
        case expiresAt = "expires_at"
        case householdName = "household_name"
        case invitedByName = "invited_by_name"
        case isValid = "is_valid"
    }
}

// Response from accept_invitation function
struct AcceptInvitationResult: Codable {
    let success: Bool
    let householdId: UUID?
    let message: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case success
        case householdId = "household_id"
        case message
        case error
    }
}
