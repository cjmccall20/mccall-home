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
    @Published var ratings: [RecipeRating] = []
    @Published var householdMembers: [HouseholdMember] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedProteinFilter: Recipe.ProteinType?
    @Published var showFavoritesOnly = false
    @Published var selectedMemberFilter: UUID?  // For filtering by who favorited

    // Scraper state
    @Published var isScraping = false
    @Published var scrapedRecipe: RecipeService.ScrapedRecipeData?
    @Published var scraperError: String?

    private let recipeService = RecipeService.shared
    private let ratingService = RecipeRatingService.shared
    private let householdMemberService = HouseholdMemberService.shared
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

        // Filter by favorites
        if showFavoritesOnly {
            let favoriteIds: Set<UUID>
            if let memberId = selectedMemberFilter {
                // Show only this member's favorites
                favoriteIds = Set(ratingService.getFavoriteRecipeIds(memberId: memberId, ratings: ratings))
            } else {
                // Show all household favorites
                favoriteIds = Set(ratings.filter { $0.isFavorite }.map { $0.recipeId })
            }
            result = result.filter { favoriteIds.contains($0.id) }
        }

        return result
    }

    var groupedByProtein: [(protein: Recipe.ProteinType, recipes: [Recipe])] {
        recipeService.groupedByProtein(filteredRecipes)
    }

    var householdId: UUID? {
        authService.currentUser?.householdId
    }

    /// Get the current user's household member ID by matching name
    var currentMemberId: UUID? {
        guard let userName = authService.currentUser?.name else { return nil }

        // Try exact match first
        if let member = householdMembers.first(where: { $0.name == userName }) {
            return member.id
        }

        // Try case-insensitive match
        if let member = householdMembers.first(where: { $0.name.lowercased() == userName.lowercased() }) {
            return member.id
        }

        // Try matching first name only
        let firstName = userName.split(separator: " ").first.map(String.init) ?? userName
        if let member = householdMembers.first(where: {
            $0.name.lowercased() == firstName.lowercased() ||
            $0.name.lowercased().hasPrefix(firstName.lowercased())
        }) {
            return member.id
        }

        // Fallback: return first member if only one exists
        if householdMembers.count == 1 {
            return householdMembers.first?.id
        }

        return nil
    }

    func fetchRecipes() async {
        guard let householdId = householdId else { return }

        isLoading = true
        error = nil

        do {
            async let recipesTask = recipeService.fetchRecipes(for: householdId)
            async let ratingsTask = ratingService.fetchRatings(for: householdId)
            async let membersTask = householdMemberService.fetchMembers(for: householdId)

            recipes = try await recipesTask
            ratings = try await ratingsTask
            householdMembers = try await membersTask
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Rating Functions

    /// Get rating info for a recipe (for current member if memberId provided)
    func getRating(for recipeId: UUID, memberId: UUID?) -> RecipeRating? {
        guard let memberId = memberId else { return nil }
        return ratingService.getMemberRating(recipeId: recipeId, memberId: memberId, ratings: ratings)
    }

    /// Get aggregate rating for a recipe
    func getAggregate(for recipeId: UUID) -> RecipeRatingAggregate {
        ratingService.getAggregate(for: recipeId, ratings: ratings)
    }

    /// Check if a recipe is favorited by a member
    func isFavorite(recipeId: UUID, memberId: UUID?) -> Bool {
        guard let memberId = memberId else { return false }
        return ratingService.getMemberRating(recipeId: recipeId, memberId: memberId, ratings: ratings)?.isFavorite ?? false
    }

    /// Toggle favorite status
    func toggleFavorite(recipeId: UUID, memberId: UUID) async {
        guard let householdId = householdId else { return }

        do {
            let updated = try await ratingService.toggleFavorite(
                recipeId: recipeId,
                memberId: memberId,
                householdId: householdId
            )

            // Update local state
            if let index = ratings.firstIndex(where: { $0.id == updated.id }) {
                ratings[index] = updated
            } else {
                ratings.append(updated)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Set rating for a recipe
    func setRating(recipeId: UUID, memberId: UUID, rating: Int) async {
        guard let householdId = householdId else { return }

        do {
            let updated = try await ratingService.setRating(
                recipeId: recipeId,
                memberId: memberId,
                householdId: householdId,
                rating: rating
            )

            // Update local state
            if let index = ratings.firstIndex(where: { $0.id == updated.id }) {
                ratings[index] = updated
            } else {
                ratings.append(updated)
            }
        } catch {
            self.error = error.localizedDescription
        }
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
