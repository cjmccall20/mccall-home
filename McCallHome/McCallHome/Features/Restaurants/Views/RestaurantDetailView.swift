//
//  RestaurantDetailView.swift
//  McCallHome
//
//  Created by Claude on 12/1/25.
//

import SwiftUI

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    @ObservedObject var viewModel: RestaurantsViewModel
    @State private var showAddOrder = false
    @State private var showEditRestaurant = false

    var body: some View {
        List {
            // Restaurant info section
            Section {
                HStack {
                    Image(systemName: restaurant.cuisineType.iconName)
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                        .frame(width: 50)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(restaurant.name)
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(restaurant.cuisineType.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        Task {
                            await viewModel.toggleFavorite(restaurant)
                        }
                    } label: {
                        Image(systemName: restaurant.isFavorite ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundStyle(restaurant.isFavorite ? .pink : .secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 8)

                if let address = restaurant.address, !address.isEmpty {
                    Label(address, systemImage: "mappin.circle")
                        .font(.subheadline)
                }

                if let phone = restaurant.phoneNumber, !phone.isEmpty {
                    Label(phone, systemImage: "phone")
                        .font(.subheadline)
                }

                if let website = restaurant.website, !website.isEmpty {
                    Link(destination: URL(string: website) ?? URL(string: "https://google.com")!) {
                        Label("Website", systemImage: "globe")
                            .font(.subheadline)
                    }
                }

                if let notes = restaurant.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Favorite dishes section
            let favoriteItems = viewModel.favoriteItems(for: restaurant)
            if !favoriteItems.isEmpty {
                Section("Favorite Dishes") {
                    ForEach(favoriteItems) { item in
                        HStack {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)

                            Text(item.name)

                            Spacer()

                            if let price = item.price {
                                Text(String(format: "$%.2f", price))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            // Add Order section
            Section {
                Button {
                    showAddOrder = true
                } label: {
                    Label("Add Order", systemImage: "plus.circle")
                }
            }

            // Orders grouped by household member
            if !viewModel.orders.isEmpty {
                ForEach(viewModel.ordersByMember, id: \.member?.id) { group in
                    Section {
                        ForEach(group.orders) { order in
                            NavigationLink {
                                OrderDetailView(order: order, restaurant: restaurant, viewModel: viewModel)
                            } label: {
                                OrderRowView(order: order, memberName: viewModel.memberName(for: order.householdMemberId))
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteOrder(order)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: "person.circle")
                            Text(group.member?.name ?? "Unassigned")
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(restaurant.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showEditRestaurant = true
                }
            }
        }
        .task {
            viewModel.selectedRestaurant = restaurant
            await viewModel.fetchOrders(for: restaurant)
        }
        .sheet(isPresented: $showAddOrder) {
            AddOrderView(restaurant: restaurant, viewModel: viewModel)
        }
        .sheet(isPresented: $showEditRestaurant) {
            EditRestaurantView(restaurant: restaurant, viewModel: viewModel)
        }
    }
}

// MARK: - Order Row View

struct OrderRowView: View {
    let order: RestaurantOrder
    var memberName: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Show order name prominently if it exists
                if let orderName = order.orderName, !orderName.isEmpty {
                    Text(orderName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                } else {
                    Text(order.orderDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                if let rating = order.rating {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundStyle(star <= rating ? .yellow : .secondary)
                        }
                    }
                }
            }

            // Show date if we have an order name
            if order.orderName != nil {
                Text(order.orderDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !order.items.isEmpty {
                Text(order.items.map { $0.name }.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if let total = order.totalAmount {
                Text(String(format: "Total: $%.2f", total))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        RestaurantDetailView(
            restaurant: Restaurant(
                householdId: UUID(),
                name: "Test Restaurant",
                cuisineType: .italian,
                address: "123 Main St"
            ),
            viewModel: RestaurantsViewModel()
        )
    }
}
