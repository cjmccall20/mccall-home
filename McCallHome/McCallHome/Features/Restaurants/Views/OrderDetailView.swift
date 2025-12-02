//
//  OrderDetailView.swift
//  McCallHome
//
//  Created by Claude on 12/1/25.
//

import SwiftUI

struct OrderDetailView: View {
    let order: RestaurantOrder
    let restaurant: Restaurant
    @ObservedObject var viewModel: RestaurantsViewModel
    @State private var showEditOrder = false

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Date")
                    Spacer()
                    Text(order.orderDate.formatted(date: .long, time: .omitted))
                        .foregroundStyle(.secondary)
                }

                if let rating = order.rating {
                    HStack {
                        Text("Rating")
                        Spacer()
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundStyle(star <= rating ? .yellow : .secondary)
                            }
                        }
                    }
                }

                if let total = order.totalAmount {
                    HStack {
                        Text("Total")
                        Spacer()
                        Text(String(format: "$%.2f", total))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !order.items.isEmpty {
                Section("Items Ordered") {
                    ForEach(order.items) { item in
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

                        if let notes = item.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if let notes = order.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(restaurant.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showEditOrder = true
                }
            }
        }
        .sheet(isPresented: $showEditOrder) {
            EditOrderView(order: order, restaurant: restaurant, viewModel: viewModel)
        }
    }
}

// MARK: - Edit Order View

struct EditOrderView: View {
    @Environment(\.dismiss) private var dismiss
    let order: RestaurantOrder
    let restaurant: Restaurant
    @ObservedObject var viewModel: RestaurantsViewModel

    @State private var orderDate: Date
    @State private var items: [RestaurantOrder.OrderItem]
    @State private var totalAmount: String
    @State private var rating: Int
    @State private var notes: String

    // New item form
    @State private var newItemName = ""
    @State private var newItemPrice = ""
    @State private var newItemIsFavorite = false

    init(order: RestaurantOrder, restaurant: Restaurant, viewModel: RestaurantsViewModel) {
        self.order = order
        self.restaurant = restaurant
        self.viewModel = viewModel
        _orderDate = State(initialValue: order.orderDate)
        _items = State(initialValue: order.items)
        _totalAmount = State(initialValue: order.totalAmount.map { String(format: "%.2f", $0) } ?? "")
        _rating = State(initialValue: order.rating ?? 0)
        _notes = State(initialValue: order.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
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
            .navigationTitle("Edit Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        updateOrder()
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

    private func updateOrder() {
        var updated = order
        updated.orderDate = orderDate
        updated.items = items
        updated.totalAmount = Double(totalAmount)
        updated.rating = rating > 0 ? rating : nil
        updated.notes = notes.isEmpty ? nil : notes

        Task {
            await viewModel.updateOrder(updated)
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        OrderDetailView(
            order: RestaurantOrder(
                restaurantId: UUID(),
                householdId: UUID(),
                items: [
                    .init(name: "Pasta", price: 15.99, isFavorite: true),
                    .init(name: "Salad", price: 8.99)
                ],
                totalAmount: 24.98,
                rating: 4
            ),
            restaurant: Restaurant(householdId: UUID(), name: "Test"),
            viewModel: RestaurantsViewModel()
        )
    }
}
