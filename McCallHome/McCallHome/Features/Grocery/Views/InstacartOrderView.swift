//
//  InstacartOrderView.swift
//  McCallHome
//
//  Created by Claude on 12/3/25.
//

import SwiftUI

/// Pre-order confirmation screen for sending grocery list to Instacart
struct InstacartOrderView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GroceryViewModel
    @State private var settings: HouseholdSettings?

    // Order configuration
    @State private var includeWeeklyStaples = true
    @State private var excludeNonInstacartStores = true
    @State private var excludeInPersonItems = true
    @State private var showMealExclusion = false
    @State private var excludedMealEntryIds: Set<UUID> = []

    // State
    @State private var isLoading = false
    @State private var error: String?
    @State private var instacartURL: URL?
    @State private var showingSafari = false

    private let instacartService = InstacartService.shared
    private let settingsService = HouseholdSettingsService.shared
    private let authService = AuthService.shared

    var body: some View {
        NavigationStack {
            Form {
                // Items summary
                Section {
                    HStack {
                        Text("Total Items")
                        Spacer()
                        Text("\(viewModel.uncheckedCount)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Items for Instacart")
                        Spacer()
                        Text("\(filteredItemCount)")
                            .foregroundStyle(.blue)
                            .fontWeight(.medium)
                    }

                    if excludedItemCount > 0 {
                        HStack {
                            Text("Excluded Items")
                            Spacer()
                            Text("\(excludedItemCount)")
                                .foregroundStyle(.orange)
                        }
                    }
                } header: {
                    Text("Order Summary")
                }

                // Configuration options
                Section {
                    Toggle("Include Weekly Staples", isOn: $includeWeeklyStaples)

                    Toggle("Exclude Non-Instacart Stores", isOn: $excludeNonInstacartStores)

                    Toggle("Exclude In-Person Items", isOn: $excludeInPersonItems)
                } header: {
                    Text("Options")
                } footer: {
                    Text("Items marked for Costco, Farmers Market, Trader Joe's, or 'in-person shopping' can be excluded from this order.")
                }

                // Excluded items preview
                if !excludedItems.isEmpty {
                    Section {
                        ForEach(excludedItems.prefix(5)) { item in
                            HStack {
                                Text(item.name)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                if let store = storeForItem(item) {
                                    Text(store.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                } else if isInPersonItem(item) {
                                    Text("In-Person")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                            }
                        }

                        if excludedItems.count > 5 {
                            Text("+ \(excludedItems.count - 5) more...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("Excluded from Order")
                    }
                }

                // Items to be ordered preview
                Section {
                    ForEach(filteredItems.prefix(10)) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            if let qty = item.quantity {
                                Text(formatQuantity(qty, unit: item.unit))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if filteredItems.count > 10 {
                        Text("+ \(filteredItems.count - 10) more items...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Items to Order")
                }

                // Warning section
                Section {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Review Your Cart")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text("Instacart will match items based on availability. Please review your cart before placing the order to ensure the correct products are selected.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Send to Instacart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await sendToInstacart()
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Send")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isLoading || filteredItems.isEmpty || !instacartService.isConfigured)
                }
            }
            .task {
                await loadSettings()
            }
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK") {
                    error = nil
                }
            } message: {
                if let error = error {
                    Text(error)
                }
            }
            .sheet(isPresented: $showingSafari) {
                if let url = instacartURL {
                    SafariView(url: url)
                }
            }
            .onChange(of: instacartURL) { _, newURL in
                if newURL != nil {
                    showingSafari = true
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Computed Properties

    private var uncheckedItems: [GroceryItem] {
        viewModel.items.filter { !$0.isChecked }
    }

    private var filteredItems: [GroceryItem] {
        var items = uncheckedItems

        // Filter out staples if not including them
        if !includeWeeklyStaples {
            items = items.filter { $0.source != .staple }
        }

        // Apply Instacart filters
        return instacartService.filterItemsForInstacart(
            items: items,
            preferences: viewModel.ingredientPreferences,
            excludeNonInstacart: excludeNonInstacartStores,
            excludeInPerson: excludeInPersonItems
        )
    }

    private var excludedItems: [GroceryItem] {
        let filtered = Set(filteredItems.map { $0.id })
        return uncheckedItems.filter { !filtered.contains($0.id) }
    }

    private var filteredItemCount: Int {
        filteredItems.count
    }

    private var excludedItemCount: Int {
        excludedItems.count
    }

    // MARK: - Helper Methods

    private func storeForItem(_ item: GroceryItem) -> Store? {
        let preference = viewModel.ingredientPreferences.first { pref in
            pref.canonicalName.lowercased() == item.name.lowercased() ||
            pref.displayName?.lowercased() == item.name.lowercased()
        }
        return preference?.preferredStore
    }

    private func isInPersonItem(_ item: GroceryItem) -> Bool {
        let preference = viewModel.ingredientPreferences.first { pref in
            pref.canonicalName.lowercased() == item.name.lowercased() ||
            pref.displayName?.lowercased() == item.name.lowercased()
        }
        return preference?.isInPerson ?? false
    }

    private func formatQuantity(_ qty: Double, unit: String?) -> String {
        let qtyStr = qty.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(qty))
            : String(format: "%.1f", qty)

        if let unit = unit, !unit.isEmpty {
            return "\(qtyStr) \(unit)"
        }
        return qtyStr
    }

    private func loadSettings() async {
        guard let householdId = authService.currentUser?.householdId else { return }

        do {
            settings = try await settingsService.fetchSettings(for: householdId)
            // Initialize toggles from settings
            if let settings = settings {
                excludeNonInstacartStores = settings.excludeNonInstacartStores
                excludeInPersonItems = settings.excludeInPersonItems
            }
        } catch {
            print("Failed to load settings: \(error)")
        }
    }

    private func sendToInstacart() async {
        guard !filteredItems.isEmpty else {
            error = "No items to send to Instacart"
            return
        }

        isLoading = true
        error = nil

        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            let title = "Groceries - \(dateFormatter.string(from: Date()))"

            let url = try await instacartService.createShoppingList(
                items: filteredItems,
                ingredientPreferences: viewModel.ingredientPreferences,
                title: title
            )

            instacartURL = url
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Safari View

import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

#Preview {
    InstacartOrderView(viewModel: GroceryViewModel())
}
