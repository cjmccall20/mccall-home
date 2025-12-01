//
//  Recipe.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation

struct Recipe: Codable, Identifiable, Equatable {
    let id: UUID
    let householdId: UUID
    var title: String
    var sourceUrl: String?
    var sourceType: SourceType?
    var baseServings: Int
    var ingredients: [Ingredient]
    var steps: [RecipeStep]
    var tags: [String]?
    var prepTime: Int?
    var cookTime: Int?
    var notes: String?
    let createdAt: Date
    var updatedAt: Date

    enum SourceType: String, Codable, CaseIterable {
        case url, manual, imported
    }

    struct Ingredient: Codable, Equatable, Identifiable {
        var id: UUID = UUID()
        var name: String
        var quantity: Double?
        var unit: String?
        var notes: String?

        enum CodingKeys: String, CodingKey {
            case name, quantity, unit, notes
        }

        init(id: UUID = UUID(), name: String, quantity: Double? = nil, unit: String? = nil, notes: String? = nil) {
            self.id = id
            self.name = name
            self.quantity = quantity
            self.unit = unit
            self.notes = notes
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = UUID()
            self.name = try container.decode(String.self, forKey: .name)
            self.quantity = try container.decodeIfPresent(Double.self, forKey: .quantity)
            self.unit = try container.decodeIfPresent(String.self, forKey: .unit)
            self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
        }
    }

    struct RecipeStep: Codable, Equatable, Identifiable {
        var id: UUID = UUID()
        var stepNumber: Int
        var instruction: String

        enum CodingKeys: String, CodingKey {
            case stepNumber = "step_number"
            case instruction
        }

        init(id: UUID = UUID(), stepNumber: Int, instruction: String) {
            self.id = id
            self.stepNumber = stepNumber
            self.instruction = instruction
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = UUID()
            self.stepNumber = try container.decode(Int.self, forKey: .stepNumber)
            self.instruction = try container.decode(String.self, forKey: .instruction)
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case title
        case sourceUrl = "source_url"
        case sourceType = "source_type"
        case baseServings = "base_servings"
        case ingredients
        case steps
        case tags
        case prepTime = "prep_time"
        case cookTime = "cook_time"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
