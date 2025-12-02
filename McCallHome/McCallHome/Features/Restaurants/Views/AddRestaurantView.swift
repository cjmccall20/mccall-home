//
//  AddRestaurantView.swift
//  McCallHome
//
//  Created by Claude on 12/1/25.
//

import SwiftUI

struct AddRestaurantView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: RestaurantsViewModel

    @State private var name = ""
    @State private var cuisineType: Restaurant.CuisineType = .other
    @State private var address = ""
    @State private var phoneNumber = ""
    @State private var website = ""
    @State private var notes = ""
    @State private var isFavorite = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Restaurant Info") {
                    TextField("Name", text: $name)

                    Picker("Cuisine Type", selection: $cuisineType) {
                        ForEach(Restaurant.CuisineType.allCases, id: \.self) { cuisine in
                            Label(cuisine.displayName, systemImage: cuisine.iconName)
                                .tag(cuisine)
                        }
                    }

                    Toggle("Favorite", isOn: $isFavorite)
                }

                Section("Contact Info") {
                    TextField("Address", text: $address)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Website", text: $website)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Restaurant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveRestaurant()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveRestaurant() {
        guard let householdId = viewModel.householdId else { return }

        let restaurant = Restaurant(
            householdId: householdId,
            name: name,
            cuisineType: cuisineType,
            address: address.isEmpty ? nil : address,
            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
            website: website.isEmpty ? nil : website,
            notes: notes.isEmpty ? nil : notes,
            isFavorite: isFavorite
        )

        Task {
            await viewModel.createRestaurant(restaurant)
            dismiss()
        }
    }
}

// MARK: - Edit Restaurant View

struct EditRestaurantView: View {
    @Environment(\.dismiss) private var dismiss
    let restaurant: Restaurant
    @ObservedObject var viewModel: RestaurantsViewModel

    @State private var name: String
    @State private var cuisineType: Restaurant.CuisineType
    @State private var address: String
    @State private var phoneNumber: String
    @State private var website: String
    @State private var notes: String
    @State private var isFavorite: Bool

    init(restaurant: Restaurant, viewModel: RestaurantsViewModel) {
        self.restaurant = restaurant
        self.viewModel = viewModel
        _name = State(initialValue: restaurant.name)
        _cuisineType = State(initialValue: restaurant.cuisineType)
        _address = State(initialValue: restaurant.address ?? "")
        _phoneNumber = State(initialValue: restaurant.phoneNumber ?? "")
        _website = State(initialValue: restaurant.website ?? "")
        _notes = State(initialValue: restaurant.notes ?? "")
        _isFavorite = State(initialValue: restaurant.isFavorite)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Restaurant Info") {
                    TextField("Name", text: $name)

                    Picker("Cuisine Type", selection: $cuisineType) {
                        ForEach(Restaurant.CuisineType.allCases, id: \.self) { cuisine in
                            Label(cuisine.displayName, systemImage: cuisine.iconName)
                                .tag(cuisine)
                        }
                    }

                    Toggle("Favorite", isOn: $isFavorite)
                }

                Section("Contact Info") {
                    TextField("Address", text: $address)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Website", text: $website)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Restaurant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        updateRestaurant()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func updateRestaurant() {
        var updated = restaurant
        updated.name = name
        updated.cuisineType = cuisineType
        updated.address = address.isEmpty ? nil : address
        updated.phoneNumber = phoneNumber.isEmpty ? nil : phoneNumber
        updated.website = website.isEmpty ? nil : website
        updated.notes = notes.isEmpty ? nil : notes
        updated.isFavorite = isFavorite

        Task {
            await viewModel.updateRestaurant(updated)
            dismiss()
        }
    }
}

#Preview {
    AddRestaurantView(viewModel: RestaurantsViewModel())
}
