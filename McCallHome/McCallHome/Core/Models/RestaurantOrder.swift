//
//  RestaurantOrder.swift
//  McCallHome
//
//  Created by Claude on 12/1/25.
//

import Foundation

struct RestaurantOrder: Codable, Identifiable, Equatable {
    let id: UUID
    let restaurantId: UUID
    let householdId: UUID
    var householdMemberId: UUID?  // Which household member this order belongs to
    var orderName: String?        // Name of the order (e.g., "Breakfast Order", "Lunch Special")
    var orderDate: Date
    var items: [OrderItem]
    var totalAmount: Double?
    var rating: Int?  // 1-5 stars
    var notes: String?
    let createdAt: Date

    struct OrderItem: Codable, Equatable, Identifiable {
        var id: UUID = UUID()
        var name: String
        var price: Double?
        var isFavorite: Bool
        var notes: String?

        enum CodingKeys: String, CodingKey {
            case name, price
            case isFavorite = "is_favorite"
            case notes
        }

        init(id: UUID = UUID(), name: String, price: Double? = nil, isFavorite: Bool = false, notes: String? = nil) {
            self.id = id
            self.name = name
            self.price = price
            self.isFavorite = isFavorite
            self.notes = notes
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = UUID()
            self.name = try container.decode(String.self, forKey: .name)
            self.price = try container.decodeIfPresent(Double.self, forKey: .price)
            self.isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
            self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case restaurantId = "restaurant_id"
        case householdId = "household_id"
        case householdMemberId = "household_member_id"
        case orderName = "order_name"
        case orderDate = "order_date"
        case items
        case totalAmount = "total_amount"
        case rating
        case notes
        case createdAt = "created_at"
    }

    init(id: UUID = UUID(), restaurantId: UUID, householdId: UUID, householdMemberId: UUID? = nil, orderName: String? = nil, orderDate: Date = Date(), items: [OrderItem] = [], totalAmount: Double? = nil, rating: Int? = nil, notes: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.restaurantId = restaurantId
        self.householdId = householdId
        self.householdMemberId = householdMemberId
        self.orderName = orderName
        self.orderDate = orderDate
        self.items = items
        self.totalAmount = totalAmount
        self.rating = rating
        self.notes = notes
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        restaurantId = try container.decode(UUID.self, forKey: .restaurantId)
        householdId = try container.decode(UUID.self, forKey: .householdId)
        householdMemberId = try container.decodeIfPresent(UUID.self, forKey: .householdMemberId)
        orderName = try container.decodeIfPresent(String.self, forKey: .orderName)
        items = try container.decodeIfPresent([OrderItem].self, forKey: .items) ?? []
        totalAmount = try container.decodeIfPresent(Double.self, forKey: .totalAmount)
        rating = try container.decodeIfPresent(Int.self, forKey: .rating)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)

        // Handle order date
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let dateString = try? container.decode(String.self, forKey: .orderDate) {
            if let date = isoFormatter.date(from: dateString) {
                orderDate = date
            } else if let date = ISO8601DateFormatter().date(from: dateString) {
                orderDate = date
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                formatter.timeZone = TimeZone(identifier: "UTC")
                orderDate = formatter.date(from: dateString) ?? Date()
            }
        } else {
            orderDate = try container.decodeIfPresent(Date.self, forKey: .orderDate) ?? Date()
        }

        // Handle createdAt - may have fractional seconds
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
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

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(restaurantId, forKey: .restaurantId)
        try container.encode(householdId, forKey: .householdId)
        try container.encodeIfPresent(householdMemberId, forKey: .householdMemberId)
        try container.encodeIfPresent(orderName, forKey: .orderName)

        // Encode date as date-only string
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        try container.encode(formatter.string(from: orderDate), forKey: .orderDate)

        try container.encode(items, forKey: .items)
        try container.encodeIfPresent(totalAmount, forKey: .totalAmount)
        try container.encodeIfPresent(rating, forKey: .rating)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(ISO8601DateFormatter().string(from: createdAt), forKey: .createdAt)
    }
}

// MARK: - Display Helpers

extension RestaurantOrder {
    /// Display name for the order (uses orderName or falls back to date)
    var displayName: String {
        if let name = orderName, !name.isEmpty {
            return name
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: orderDate)
    }
}
