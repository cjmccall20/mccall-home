//
//  GroceryItem.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation

struct GroceryItem: Codable, Identifiable, Equatable {
    let id: UUID
    let groceryListId: UUID
    var name: String
    var quantity: Double?
    var unit: String?
    var category: Category
    var isChecked: Bool
    var sortOrder: Int
    let createdAt: Date

    enum Category: String, Codable, CaseIterable {
        case verifyPantry = "verify_pantry"
        case produce
        case dairy
        case meat
        case pantry
        case frozen
        case other

        var displayName: String {
            switch self {
            case .verifyPantry: return "Pantry Check"
            case .produce: return "Produce"
            case .dairy: return "Dairy"
            case .meat: return "Meat"
            case .pantry: return "Pantry"
            case .frozen: return "Frozen"
            case .other: return "Other"
            }
        }

        var sortOrder: Int {
            switch self {
            case .verifyPantry: return 0
            case .produce: return 1
            case .dairy: return 2
            case .meat: return 3
            case .pantry: return 4
            case .frozen: return 5
            case .other: return 6
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case groceryListId = "grocery_list_id"
        case name
        case quantity
        case unit
        case category
        case isChecked = "is_checked"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
    }
}
