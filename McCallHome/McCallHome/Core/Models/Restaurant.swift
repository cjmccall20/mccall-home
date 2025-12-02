//
//  Restaurant.swift
//  McCallHome
//
//  Created by Claude on 12/1/25.
//

import Foundation

struct Restaurant: Codable, Identifiable, Equatable {
    let id: UUID
    let householdId: UUID
    var name: String
    var cuisineType: CuisineType
    var address: String?
    var phoneNumber: String?
    var website: String?
    var notes: String?
    var isFavorite: Bool
    let createdAt: Date

    enum CuisineType: String, Codable, CaseIterable {
        case american
        case italian
        case mexican
        case chinese
        case japanese
        case thai
        case indian
        case mediterranean
        case french
        case korean
        case vietnamese
        case barbecue
        case seafood
        case pizza
        case fastFood
        case cafe
        case bakery
        case other

        var displayName: String {
            switch self {
            case .fastFood: return "Fast Food"
            default: return rawValue.capitalized
            }
        }

        var iconName: String {
            switch self {
            case .italian, .pizza: return "leaf"
            case .mexican: return "flame"
            case .chinese, .japanese, .korean, .vietnamese, .thai: return "takeoutbag.and.cup.and.straw"
            case .indian: return "sparkles"
            case .mediterranean, .french: return "fork.knife"
            case .barbecue: return "flame"
            case .seafood: return "fish"
            case .fastFood: return "car.side"
            case .cafe: return "cup.and.saucer"
            case .bakery: return "birthday.cake"
            default: return "fork.knife.circle"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case name
        case cuisineType = "cuisine_type"
        case address
        case phoneNumber = "phone_number"
        case website
        case notes
        case isFavorite = "is_favorite"
        case createdAt = "created_at"
    }

    init(id: UUID = UUID(), householdId: UUID, name: String, cuisineType: CuisineType = .other, address: String? = nil, phoneNumber: String? = nil, website: String? = nil, notes: String? = nil, isFavorite: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.householdId = householdId
        self.name = name
        self.cuisineType = cuisineType
        self.address = address
        self.phoneNumber = phoneNumber
        self.website = website
        self.notes = notes
        self.isFavorite = isFavorite
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        householdId = try container.decode(UUID.self, forKey: .householdId)
        name = try container.decode(String.self, forKey: .name)
        cuisineType = try container.decodeIfPresent(CuisineType.self, forKey: .cuisineType) ?? .other
        address = try container.decodeIfPresent(String.self, forKey: .address)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        website = try container.decodeIfPresent(String.self, forKey: .website)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false

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
