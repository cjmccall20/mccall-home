//
//  RestaurantsViewModel.swift
//  McCallHome
//
//  Created by Claude on 12/1/25.
//

import Foundation
import Combine

@MainActor
class RestaurantsViewModel: ObservableObject {
    @Published var restaurants: [Restaurant] = []
    @Published var orders: [RestaurantOrder] = []
    @Published var householdMembers: [HouseholdMember] = []
    @Published var selectedRestaurant: Restaurant?
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedCuisineFilter: Restaurant.CuisineType?

    private let restaurantService = RestaurantService.shared
    private let memberService = HouseholdMemberService.shared
    private let authService = AuthService.shared

    var householdId: UUID? {
        authService.currentUser?.householdId
    }

    var filteredRestaurants: [Restaurant] {
        var result = restaurants

        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { restaurant in
                restaurant.name.localizedCaseInsensitiveContains(searchText) ||
                restaurant.cuisineType.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Filter by cuisine type
        if let cuisineFilter = selectedCuisineFilter {
            result = result.filter { $0.cuisineType == cuisineFilter }
        }

        return result
    }

    var groupedByCuisine: [(cuisine: Restaurant.CuisineType, restaurants: [Restaurant])] {
        restaurantService.groupedByCuisine(filteredRestaurants)
    }

    var favoriteRestaurants: [Restaurant] {
        restaurants.filter { $0.isFavorite }.sorted { $0.name < $1.name }
    }

    func fetchRestaurants() async {
        guard let householdId = householdId else { return }

        isLoading = true
        error = nil

        do {
            // Fetch restaurants and household members in parallel
            async let restaurantsTask = restaurantService.fetchRestaurants(for: householdId)
            async let membersTask = memberService.fetchMembers(for: householdId)

            restaurants = try await restaurantsTask
            householdMembers = try await membersTask
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // Helper to get member name
    func memberName(for memberId: UUID?) -> String? {
        guard let memberId = memberId else { return nil }
        return householdMembers.first { $0.id == memberId }?.name
    }

    // Group orders by household member
    var ordersByMember: [(member: HouseholdMember?, orders: [RestaurantOrder])] {
        var result: [(member: HouseholdMember?, orders: [RestaurantOrder])] = []

        // Group orders by member
        let memberOrders = Dictionary(grouping: orders.filter { $0.householdMemberId != nil }) { $0.householdMemberId! }

        // Add orders for each member
        for member in householdMembers {
            if let memberOrderList = memberOrders[member.id], !memberOrderList.isEmpty {
                result.append((member: member, orders: memberOrderList.sorted { $0.orderDate > $1.orderDate }))
            }
        }

        // Add orders without a member
        let unassignedOrders = orders.filter { $0.householdMemberId == nil }
        if !unassignedOrders.isEmpty {
            result.append((member: nil, orders: unassignedOrders.sorted { $0.orderDate > $1.orderDate }))
        }

        return result
    }

    func createRestaurant(_ restaurant: Restaurant) async {
        do {
            try await restaurantService.createRestaurant(restaurant)
            await fetchRestaurants()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateRestaurant(_ restaurant: Restaurant) async {
        do {
            try await restaurantService.updateRestaurant(restaurant)
            await fetchRestaurants()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteRestaurant(_ restaurant: Restaurant) async {
        do {
            try await restaurantService.deleteRestaurant(restaurant)
            await fetchRestaurants()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func toggleFavorite(_ restaurant: Restaurant) async {
        do {
            try await restaurantService.toggleFavorite(restaurant)
            await fetchRestaurants()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Orders

    func fetchOrders(for restaurant: Restaurant) async {
        do {
            orders = try await restaurantService.fetchOrders(for: restaurant.id)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createOrder(_ order: RestaurantOrder) async {
        do {
            try await restaurantService.createOrder(order)
            if let restaurant = selectedRestaurant {
                await fetchOrders(for: restaurant)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateOrder(_ order: RestaurantOrder) async {
        do {
            try await restaurantService.updateOrder(order)
            if let restaurant = selectedRestaurant {
                await fetchOrders(for: restaurant)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteOrder(_ order: RestaurantOrder) async {
        do {
            try await restaurantService.deleteOrder(order)
            if let restaurant = selectedRestaurant {
                await fetchOrders(for: restaurant)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func favoriteItems(for restaurant: Restaurant) -> [RestaurantOrder.OrderItem] {
        restaurantService.favoriteItems(for: restaurant.id, from: orders)
    }

    // MARK: - Filtering

    func setCuisineFilter(_ cuisine: Restaurant.CuisineType?) {
        selectedCuisineFilter = cuisine
    }

    func clearFilters() {
        selectedCuisineFilter = nil
        searchText = ""
    }
}
