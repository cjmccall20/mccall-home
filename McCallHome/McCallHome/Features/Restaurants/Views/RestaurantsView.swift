//
//  RestaurantsView.swift
//  McCallHome
//
//  Created by Claude on 12/1/25.
//

import SwiftUI

struct RestaurantsView: View {
    @StateObject private var viewModel = RestaurantsViewModel()
    @State private var showAddRestaurant = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.restaurants.isEmpty {
                    ProgressView("Loading restaurants...")
                } else if viewModel.restaurants.isEmpty {
                    ContentUnavailableView(
                        "No Restaurants",
                        systemImage: "fork.knife.circle",
                        description: Text("Add your favorite restaurants to track orders and dishes")
                    )
                } else {
                    restaurantList
                }
            }
            .navigationTitle("Restaurants")
            .searchable(text: $viewModel.searchText, prompt: "Search restaurants")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddRestaurant = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                await viewModel.fetchRestaurants()
            }
            .refreshable {
                await viewModel.fetchRestaurants()
            }
            .sheet(isPresented: $showAddRestaurant) {
                AddRestaurantView(viewModel: viewModel)
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                }
            }
        }
    }

    private var restaurantList: some View {
        List {
            // Favorites section
            if !viewModel.favoriteRestaurants.isEmpty {
                Section("Favorites") {
                    ForEach(viewModel.favoriteRestaurants) { restaurant in
                        NavigationLink {
                            RestaurantDetailView(restaurant: restaurant, viewModel: viewModel)
                        } label: {
                            RestaurantRowView(restaurant: restaurant)
                        }
                    }
                }
            }

            // Grouped by cuisine
            ForEach(viewModel.groupedByCuisine, id: \.cuisine) { group in
                Section(group.cuisine.displayName) {
                    ForEach(group.restaurants) { restaurant in
                        NavigationLink {
                            RestaurantDetailView(restaurant: restaurant, viewModel: viewModel)
                        } label: {
                            RestaurantRowView(restaurant: restaurant)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteRestaurant(restaurant)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                Task {
                                    await viewModel.toggleFavorite(restaurant)
                                }
                            } label: {
                                Label(
                                    restaurant.isFavorite ? "Unfavorite" : "Favorite",
                                    systemImage: restaurant.isFavorite ? "heart.slash" : "heart"
                                )
                            }
                            .tint(.pink)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Restaurant Row View

struct RestaurantRowView: View {
    let restaurant: Restaurant

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: restaurant.cuisineType.iconName)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(restaurant.name)
                        .font(.headline)

                    if restaurant.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(.pink)
                    }
                }

                if let address = restaurant.address, !address.isEmpty {
                    Text(address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}

#Preview {
    RestaurantsView()
}
