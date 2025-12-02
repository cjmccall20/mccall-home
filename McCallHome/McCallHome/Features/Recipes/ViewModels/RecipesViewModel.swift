//
//  RecipesViewModel.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation
import Combine

@MainActor
class RecipesViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedProteinFilter: Recipe.ProteinType?

    // Scraper state
    @Published var isScraping = false
    @Published var scrapedRecipe: RecipeService.ScrapedRecipeData?
    @Published var scraperError: String?

    private let recipeService = RecipeService.shared
    private let authService = AuthService.shared

    var filteredRecipes: [Recipe] {
        var result = recipes

        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { recipe in
                recipe.title.localizedCaseInsensitiveContains(searchText) ||
                (recipe.tags?.contains { $0.localizedCaseInsensitiveContains(searchText) } ?? false)
            }
        }

        // Filter by protein type
        if let proteinFilter = selectedProteinFilter {
            result = result.filter { $0.proteinType == proteinFilter }
        }

        return result
    }

    var groupedByProtein: [(protein: Recipe.ProteinType, recipes: [Recipe])] {
        recipeService.groupedByProtein(filteredRecipes)
    }

    var householdId: UUID? {
        authService.currentUser?.householdId
    }

    func fetchRecipes() async {
        guard let householdId = householdId else { return }

        isLoading = true
        error = nil

        do {
            recipes = try await recipeService.fetchRecipes(for: householdId)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func createRecipe(_ recipe: Recipe) async {
        do {
            try await recipeService.createRecipe(recipe)
            await fetchRecipes()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateRecipe(_ recipe: Recipe) async {
        do {
            try await recipeService.updateRecipe(recipe)
            await fetchRecipes()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteRecipe(_ recipe: Recipe) async {
        do {
            try await recipeService.deleteRecipe(recipe)
            await fetchRecipes()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - URL Scraping

    func scrapeRecipe(from url: String) async {
        isScraping = true
        scrapedRecipe = nil
        scraperError = nil

        do {
            scrapedRecipe = try await recipeService.scrapeRecipe(from: url)
        } catch {
            scraperError = error.localizedDescription
        }

        isScraping = false
    }

    func createRecipeFromScraped(dishCategory: Recipe.DishCategory? = nil, proteinType: Recipe.ProteinType? = nil) async -> Recipe? {
        guard let scraped = scrapedRecipe,
              let householdId = householdId else { return nil }

        let recipe = recipeService.createRecipeFromScraped(scraped, householdId: householdId, dishCategoryOverride: dishCategory, proteinTypeOverride: proteinType)

        do {
            try await recipeService.createRecipe(recipe)
            await fetchRecipes()
            clearScrapedRecipe()
            return recipe
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }

    func clearScrapedRecipe() {
        scrapedRecipe = nil
        scraperError = nil
    }

    // MARK: - Filtering

    func setProteinFilter(_ protein: Recipe.ProteinType?) {
        selectedProteinFilter = protein
    }

    func clearFilters() {
        selectedProteinFilter = nil
        searchText = ""
    }
}
