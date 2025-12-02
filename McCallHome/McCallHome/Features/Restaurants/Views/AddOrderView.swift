//
//  AddOrderView.swift
//  McCallHome
//
//  Created by Claude on 12/1/25.
//

import SwiftUI

struct AddOrderView: View {
    @Environment(\.dismiss) private var dismiss
    let restaurant: Restaurant
    @ObservedObject var viewModel: RestaurantsViewModel

    @State private var selectedMemberId: UUID? = nil
    @State private var orderName = ""
    @State private var orderDate = Date()
    @State private var items: [RestaurantOrder.OrderItem] = []
    @State private var totalAmount = ""
    @State private var rating: Int = 0
    @State private var notes = ""

    // New item form
    @State private var newItemName = ""
    @State private var newItemPrice = ""
    @State private var newItemIsFavorite = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Person", selection: $selectedMemberId) {
                        Text("Unassigned").tag(nil as UUID?)
                        ForEach(viewModel.householdMembers) { member in
                            Text(member.name).tag(member.id as UUID?)
                        }
                    }

                    TextField("Order Name (e.g., Breakfast, Lunch Special)", text: $orderName)
                } header: {
                    Text("Who is this order for?")
                } footer: {
                    Text("Give your order a name to easily find it later.")
                }

                Section("Order Details") {
                    DatePicker("Date", selection: $orderDate, displayedComponents: .date)

                    HStack {
                        Text("Rating")
                        Spacer()
                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { star in
                                Button {
                                    rating = rating == star ? 0 : star
                                } label: {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .foregroundStyle(star <= rating ? .yellow : .secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    HStack {
                        Text("Total")
                        Spacer()
                        TextField("$0.00", text: $totalAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }

                Section("Add Item") {
                    TextField("Dish name", text: $newItemName)

                    HStack {
                        Text("Price")
                        Spacer()
                        TextField("$0.00", text: $newItemPrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    Toggle(isOn: $newItemIsFavorite) {
                        Label("Mark as Favorite", systemImage: "star")
                    }

                    Button("Add Item") {
                        addItem()
                    }
                    .disabled(newItemName.isEmpty)
                }

                if !items.isEmpty {
                    Section("Items (\(items.count))") {
                        ForEach(items) { item in
                            HStack {
                                if item.isFavorite {
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundStyle(.yellow)
                                }

                                Text(item.name)

                                Spacer()

                                if let price = item.price {
                                    Text(String(format: "$%.2f", price))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            items.remove(atOffsets: indexSet)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Notes about this order", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveOrder()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func addItem() {
        let price = Double(newItemPrice)

        let item = RestaurantOrder.OrderItem(
            name: newItemName,
            price: price,
            isFavorite: newItemIsFavorite
        )

        items.append(item)
        newItemName = ""
        newItemPrice = ""
        newItemIsFavorite = false
    }

    private func saveOrder() {
        guard let householdId = viewModel.householdId else { return }

        let order = RestaurantOrder(
            restaurantId: restaurant.id,
            householdId: householdId,
            householdMemberId: selectedMemberId,
            orderName: orderName.isEmpty ? nil : orderName,
            orderDate: orderDate,
            items: items,
            totalAmount: Double(totalAmount),
            rating: rating > 0 ? rating : nil,
            notes: notes.isEmpty ? nil : notes
        )

        Task {
            await viewModel.createOrder(order)
            dismiss()
        }
    }
}

#Preview {
    AddOrderView(
        restaurant: Restaurant(householdId: UUID(), name: "Test"),
        viewModel: RestaurantsViewModel()
    )
}
