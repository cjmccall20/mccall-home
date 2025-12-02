//
//  RestaurantService.swift
//  McCallHome
//
//  Created by Claude on 12/1/25.
//

import Foundation
import Supabase

@MainActor
class RestaurantService {
    static let shared = RestaurantService()
    private init() {}

    // MARK: - Restaurants

    func fetchRestaurants(for householdId: UUID) async throws -> [Restaurant] {
        let response: [Restaurant] = try await supabase
            .from("restaurants")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .order("name", ascending: true)
            .execute()
            .value
        return response
    }

    func fetchRestaurant(by id: UUID) async throws -> Restaurant? {
        let response: [Restaurant] = try await supabase
            .from("restaurants")
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value
        return response.first
    }

    func createRestaurant(_ restaurant: Restaurant) async throws {
        try await supabase
            .from("restaurants")
            .insert(restaurant)
            .execute()
    }

    func updateRestaurant(_ restaurant: Restaurant) async throws {
        try await supabase
            .from("restaurants")
            .update(restaurant)
            .eq("id", value: restaurant.id.uuidString)
            .execute()
    }

    func deleteRestaurant(_ restaurant: Restaurant) async throws {
        try await supabase
            .from("restaurants")
            .delete()
            .eq("id", value: restaurant.id.uuidString)
            .execute()
    }

    func toggleFavorite(_ restaurant: Restaurant) async throws {
        struct FavoriteUpdate: Encodable {
            let is_favorite: Bool
        }
        try await supabase
            .from("restaurants")
            .update(FavoriteUpdate(is_favorite: !restaurant.isFavorite))
            .eq("id", value: restaurant.id.uuidString)
            .execute()
    }

    // MARK: - Orders

    func fetchOrders(for restaurantId: UUID) async throws -> [RestaurantOrder] {
        let response: [RestaurantOrder] = try await supabase
            .from("restaurant_orders")
            .select()
            .eq("restaurant_id", value: restaurantId.uuidString)
            .order("order_date", ascending: false)
            .execute()
            .value
        return response
    }

    func fetchRecentOrders(for householdId: UUID, limit: Int = 10) async throws -> [RestaurantOrder] {
        let response: [RestaurantOrder] = try await supabase
            .from("restaurant_orders")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .order("order_date", ascending: false)
            .limit(limit)
            .execute()
            .value
        return response
    }

    func createOrder(_ order: RestaurantOrder) async throws {
        try await supabase
            .from("restaurant_orders")
            .insert(order)
            .execute()
    }

    func updateOrder(_ order: RestaurantOrder) async throws {
        try await supabase
            .from("restaurant_orders")
            .update(order)
            .eq("id", value: order.id.uuidString)
            .execute()
    }

    func deleteOrder(_ order: RestaurantOrder) async throws {
        try await supabase
            .from("restaurant_orders")
            .delete()
            .eq("id", value: order.id.uuidString)
            .execute()
    }

    // MARK: - Favorite Items

    /// Get all favorite items across all orders for a restaurant
    func favoriteItems(for restaurantId: UUID, from orders: [RestaurantOrder]) -> [RestaurantOrder.OrderItem] {
        orders
            .filter { $0.restaurantId == restaurantId }
            .flatMap { $0.items }
            .filter { $0.isFavorite }
            .reduce(into: [String: RestaurantOrder.OrderItem]()) { result, item in
                // Deduplicate by name, keeping the most recent one
                if result[item.name.lowercased()] == nil {
                    result[item.name.lowercased()] = item
                }
            }
            .values
            .sorted { $0.name < $1.name }
    }

    // MARK: - Grouping

    func groupedByCuisine(_ restaurants: [Restaurant]) -> [(cuisine: Restaurant.CuisineType, restaurants: [Restaurant])] {
        let grouped = Dictionary(grouping: restaurants, by: { $0.cuisineType })
        return Restaurant.CuisineType.allCases
            .compactMap { cuisineType in
                guard let restaurants = grouped[cuisineType], !restaurants.isEmpty else { return nil }
                return (cuisine: cuisineType, restaurants: restaurants.sorted { $0.name < $1.name })
            }
    }
}
