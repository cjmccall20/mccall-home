//
//  InstacartService.swift
//  McCallHome
//
//  Created by Claude on 12/3/25.
//

import Foundation

/// Service for integrating with Instacart Developer Platform API
class InstacartService {
    static let shared = InstacartService()

    // TODO: Replace with actual API key from Instacart Developer Platform
    private var apiKey: String? {
        Config.instacartAPIKey
    }

    private let baseURL = "https://connect.instacart.com/idp/v1"

    private init() {}

    // MARK: - Line Item Model

    /// Represents an item to add to the Instacart shopping list
    struct LineItem: Encodable {
        let name: String
        let quantity: Double?
        let unit: String?
        let displayText: String?
        let filters: LineItemFilters?

        enum CodingKeys: String, CodingKey {
            case name
            case quantity
            case unit
            case displayText = "display_text"
            case filters
        }
    }

    struct LineItemFilters: Encodable {
        let brandFilters: [String]?

        enum CodingKeys: String, CodingKey {
            case brandFilters = "brand_filters"
        }
    }

    // MARK: - Request/Response Models

    struct CreateShoppingListRequest: Encodable {
        let title: String
        let lineItems: [LineItem]
        let linkType: String
        let expiresIn: Int?

        enum CodingKeys: String, CodingKey {
            case title
            case lineItems = "line_items"
            case linkType = "link_type"
            case expiresIn = "expires_in"
        }
    }

    struct CreateShoppingListResponse: Decodable {
        let productsLinkUrl: String

        enum CodingKeys: String, CodingKey {
            case productsLinkUrl = "products_link_url"
        }
    }

    // MARK: - Error Types

    enum InstacartError: Error, LocalizedError {
        case apiKeyMissing
        case invalidResponse
        case networkError(Error)
        case apiError(String)

        var errorDescription: String? {
            switch self {
            case .apiKeyMissing:
                return "Instacart API key is not configured"
            case .invalidResponse:
                return "Invalid response from Instacart"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .apiError(let message):
                return "Instacart API error: \(message)"
            }
        }
    }

    // MARK: - API Methods

    /// Create a shopping list on Instacart and return the URL
    /// - Parameters:
    ///   - items: Grocery items to add to the list
    ///   - title: Title for the shopping list (e.g., "Groceries - Dec 2-8")
    /// - Returns: URL to the Instacart shopping list page
    func createShoppingList(
        items: [GroceryItem],
        ingredientPreferences: [IngredientPreference],
        title: String
    ) async throws -> URL {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw InstacartError.apiKeyMissing
        }

        // Convert GroceryItems to LineItems
        let lineItems = items.compactMap { item -> LineItem? in
            // Find the ingredient preference for this item to get display name
            let preference = ingredientPreferences.first { pref in
                pref.canonicalName.lowercased() == item.name.lowercased() ||
                pref.displayName?.lowercased() == item.name.lowercased()
            }

            let displayName = preference?.effectiveDisplayName ?? item.name

            return LineItem(
                name: displayName,
                quantity: item.quantity,
                unit: item.unit,
                displayText: displayName,
                filters: nil  // Could add brand filters from preferences in the future
            )
        }

        guard !lineItems.isEmpty else {
            throw InstacartError.apiError("No items to add to shopping list")
        }

        let request = CreateShoppingListRequest(
            title: title,
            lineItems: lineItems,
            linkType: "shopping_list",
            expiresIn: 7  // Link expires in 7 days
        )

        // Make API request
        guard let url = URL(string: "\(baseURL)/products/products_link") else {
            throw InstacartError.invalidResponse
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw InstacartError.invalidResponse
            }

            if httpResponse.statusCode != 200 {
                // Try to parse error message
                if let errorMessage = String(data: data, encoding: .utf8) {
                    throw InstacartError.apiError("Status \(httpResponse.statusCode): \(errorMessage)")
                }
                throw InstacartError.apiError("Status code: \(httpResponse.statusCode)")
            }

            let decoder = JSONDecoder()
            let responseData = try decoder.decode(CreateShoppingListResponse.self, from: data)

            guard let shoppingListURL = URL(string: responseData.productsLinkUrl) else {
                throw InstacartError.invalidResponse
            }

            return shoppingListURL
        } catch let error as InstacartError {
            throw error
        } catch {
            throw InstacartError.networkError(error)
        }
    }

    /// Filter items for Instacart based on store preferences
    /// - Parameters:
    ///   - items: All grocery items
    ///   - preferences: Ingredient preferences with store info
    ///   - excludeNonInstacart: Whether to exclude items marked for non-Instacart stores
    ///   - excludeInPerson: Whether to exclude items marked for in-person shopping
    /// - Returns: Filtered items suitable for Instacart
    func filterItemsForInstacart(
        items: [GroceryItem],
        preferences: [IngredientPreference],
        excludeNonInstacart: Bool,
        excludeInPerson: Bool
    ) -> [GroceryItem] {
        return items.filter { item in
            // Find matching preference
            let preference = preferences.first { pref in
                pref.canonicalName.lowercased() == item.name.lowercased() ||
                pref.displayName?.lowercased() == item.name.lowercased()
            }

            // If no preference, include the item
            guard let pref = preference else {
                return true
            }

            // Check in-person preference
            if excludeInPerson && pref.isInPerson {
                return false
            }

            // Check store preference
            if excludeNonInstacart, let store = pref.preferredStore {
                if !store.isOnInstacart {
                    return false
                }
            }

            return true
        }
    }

    /// Group items by their preferred store
    /// - Parameters:
    ///   - items: All grocery items
    ///   - preferences: Ingredient preferences with store info
    /// - Returns: Dictionary of items grouped by store (nil key for items without store preference)
    func groupItemsByStore(
        items: [GroceryItem],
        preferences: [IngredientPreference]
    ) -> [Store?: [GroceryItem]] {
        var grouped: [Store?: [GroceryItem]] = [:]

        for item in items {
            let preference = preferences.first { pref in
                pref.canonicalName.lowercased() == item.name.lowercased() ||
                pref.displayName?.lowercased() == item.name.lowercased()
            }

            let store = preference?.preferredStore

            if grouped[store] == nil {
                grouped[store] = []
            }
            grouped[store]?.append(item)
        }

        return grouped
    }

    /// Check if Instacart integration is configured
    var isConfigured: Bool {
        guard let apiKey = apiKey else { return false }
        return !apiKey.isEmpty
    }
}
