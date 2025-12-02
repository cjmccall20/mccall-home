//
//  RecipeService.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation
import Supabase

@MainActor
class RecipeService {
    static let shared = RecipeService()
    private init() {}

    func fetchRecipes(for householdId: UUID) async throws -> [Recipe] {
        let response: [Recipe] = try await supabase
            .from("recipes")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .order("title", ascending: true)
            .execute()
            .value
        return response
    }

    func fetchRecipe(by id: UUID) async throws -> Recipe? {
        let response: [Recipe] = try await supabase
            .from("recipes")
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value
        return response.first
    }

    func fetchRecipesByProtein(proteinType: Recipe.ProteinType, for householdId: UUID) async throws -> [Recipe] {
        let response: [Recipe] = try await supabase
            .from("recipes")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .eq("protein_type", value: proteinType.rawValue)
            .order("title", ascending: true)
            .execute()
            .value
        return response
    }

    func createRecipe(_ recipe: Recipe) async throws {
        try await supabase
            .from("recipes")
            .insert(recipe)
            .execute()
    }

    func updateRecipe(_ recipe: Recipe) async throws {
        try await supabase
            .from("recipes")
            .update(recipe)
            .eq("id", value: recipe.id.uuidString)
            .execute()
    }

    func deleteRecipe(_ recipe: Recipe) async throws {
        try await supabase
            .from("recipes")
            .delete()
            .eq("id", value: recipe.id.uuidString)
            .execute()
    }

    func searchRecipes(query: String, in householdId: UUID) async throws -> [Recipe] {
        let response: [Recipe] = try await supabase
            .from("recipes")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .ilike("title", pattern: "%\(query)%")
            .execute()
            .value
        return response
    }

    // MARK: - Recipe Scraping

    struct ScrapedRecipeData: Codable {
        let title: String
        let ingredients: [ScrapedIngredient]
        let steps: [ScrapedStep]
        let prepTime: Int?
        let cookTime: Int?
        let baseServings: Int
        let dishCategory: String?
        let proteinType: String?
        let tags: [String]
        let sourceUrl: String

        enum CodingKeys: String, CodingKey {
            case title
            case ingredients
            case steps
            case prepTime = "prep_time"
            case cookTime = "cook_time"
            case baseServings = "base_servings"
            case dishCategory = "dish_category"
            case proteinType = "protein_type"
            case tags
            case sourceUrl = "source_url"
        }

        struct ScrapedIngredient: Codable {
            let name: String
            let quantity: Double?
            let unit: String?
            let notes: String?
        }

        struct ScrapedStep: Codable {
            let stepNumber: Int
            let instruction: String

            enum CodingKeys: String, CodingKey {
                case stepNumber = "step_number"
                case instruction
            }
        }
    }

    struct ScraperResponse: Codable {
        let success: Bool
        let recipe: ScrapedRecipeData?
        let error: String?
    }

    /// Scrape a recipe from a URL using the Edge Function
    func scrapeRecipe(from url: String) async throws -> ScrapedRecipeData {
        // Call the Edge Function
        let functionUrl = Config.supabaseURL.appendingPathComponent("functions/v1/scrape-recipe")

        var request = URLRequest(url: functionUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Only use apikey header since JWT verification is disabled for this function
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")

        let body = ["url": url]
        request.httpBody = try JSONEncoder().encode(body)

        print("🔗 Calling scrape-recipe function for: \(url)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RecipeScraperError.invalidResponse
        }

        print("📡 Response status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(responseString)")
            }
            if let errorResponse = try? JSONDecoder().decode(ScraperResponse.self, from: data) {
                throw RecipeScraperError.scraperError(errorResponse.error ?? "Unknown error")
            }
            throw RecipeScraperError.httpError(httpResponse.statusCode)
        }

        let scraperResponse = try JSONDecoder().decode(ScraperResponse.self, from: data)

        guard scraperResponse.success, let recipe = scraperResponse.recipe else {
            throw RecipeScraperError.scraperError(scraperResponse.error ?? "Failed to scrape recipe")
        }

        print("✅ Successfully scraped recipe: \(recipe.title)")
        return recipe
    }

    /// Create a Recipe from scraped data
    func createRecipeFromScraped(_ scraped: ScrapedRecipeData, householdId: UUID, dishCategoryOverride: Recipe.DishCategory? = nil, proteinTypeOverride: Recipe.ProteinType? = nil) -> Recipe {
        let ingredients = scraped.ingredients.map { ing in
            Recipe.Ingredient(
                name: ing.name,
                quantity: ing.quantity,
                unit: ing.unit,
                notes: ing.notes
            )
        }

        let steps = scraped.steps.map { step in
            Recipe.RecipeStep(
                stepNumber: step.stepNumber,
                instruction: step.instruction
            )
        }

        // Use scraped values or fallback to overrides or defaults
        let dishCategory: Recipe.DishCategory
        if let override = dishCategoryOverride {
            dishCategory = override
        } else if let scrapedCategory = scraped.dishCategory,
                  let parsed = Recipe.DishCategory(rawValue: scrapedCategory) {
            dishCategory = parsed
        } else {
            dishCategory = .entree
        }

        let proteinType: Recipe.ProteinType
        if let override = proteinTypeOverride {
            proteinType = override
        } else if let scrapedProtein = scraped.proteinType,
                  let parsed = Recipe.ProteinType(rawValue: scrapedProtein) {
            proteinType = parsed
        } else {
            proteinType = .other
        }

        return Recipe(
            id: UUID(),
            householdId: householdId,
            title: scraped.title,
            sourceUrl: scraped.sourceUrl,
            sourceType: .url,
            dishCategory: dishCategory,
            proteinType: proteinType,
            baseServings: scraped.baseServings,
            ingredients: ingredients,
            steps: steps,
            tags: scraped.tags.isEmpty ? nil : scraped.tags,
            prepTime: scraped.prepTime,
            cookTime: scraped.cookTime,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    enum RecipeScraperError: LocalizedError {
        case invalidResponse
        case httpError(Int)
        case scraperError(String)
        case noRecipeFound

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid response from server"
            case .httpError(let code):
                return "Server error: \(code)"
            case .scraperError(let message):
                return message
            case .noRecipeFound:
                return "Could not find recipe data on this page"
            }
        }
    }

    // MARK: - Grouping

    func groupedByProtein(_ recipes: [Recipe]) -> [(protein: Recipe.ProteinType, recipes: [Recipe])] {
        let grouped = Dictionary(grouping: recipes, by: { $0.proteinType })
        return Recipe.ProteinType.allCases
            .compactMap { proteinType in
                guard let recipes = grouped[proteinType], !recipes.isEmpty else { return nil }
                return (protein: proteinType, recipes: recipes.sorted { $0.title < $1.title })
            }
    }
}
