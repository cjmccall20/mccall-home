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

    // Temporary exclusions for this order only
    @State private var manuallyExcludedIds: Set<UUID> = []
    @State private var manuallyIncludedIds: Set<UUID> = []  // Items moved back from excluded

    // Temporary quantity overrides (just for this order)
    @State private var quantityOverrides: [UUID: (quantity: Double, unit: String?)] = [:]

    // State
    @State private var isLoading = false
    @State private var error: String?
    @State private var instacartURL: URL?
    @State private var showingSafari = false
    @State private var showHelp = false
    @State private var showCancelConfirmation = false
    @State private var itemToEdit: GroceryItem?

    private let instacartService = InstacartService.shared
    private let settingsService = HouseholdSettingsService.shared
    private let authService = AuthService.shared

    var body: some View {
        NavigationStack {
            List {
                // Help section
                Section {
                    Button {
                        withAnimation {
                            showHelp.toggle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                            Text("How this works")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: showHelp ? "chevron.up" : "chevron.down")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }

                    if showHelp {
                        VStack(alignment: .leading, spacing: 8) {
                            helpRow(icon: "hand.tap", color: .blue, text: "Tap items to edit quantities for this order")
                            helpRow(icon: "arrow.right", color: .orange, text: "Swipe left/right to move items between sections")
                            helpRow(icon: "checkmark.circle", color: .green, text: "Only 'Items to Order' will be sent to Instacart")
                            helpRow(icon: "xmark.circle", color: .secondary, text: "Excluded items won't be checked off your list")
                            helpRow(icon: "arrow.clockwise", color: .purple, text: "All changes are temporary - just for this order")
                        }
                        .font(.caption)
                        .padding(.vertical, 4)
                    }
                }

                // Order summary
                Section {
                    HStack {
                        Text("Items to Order")
                        Spacer()
                        Text("\(itemsToOrder.count)")
                            .foregroundStyle(.blue)
                            .fontWeight(.medium)
                    }

                    HStack {
                        Text("Excluded")
                        Spacer()
                        Text("\(excludedFromOrder.count)")
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text("Summary")
                }

                // Configuration options
                Section {
                    Toggle("Include Weekly Staples", isOn: $includeWeeklyStaples)
                    Toggle("Exclude Non-Instacart Stores", isOn: $excludeNonInstacartStores)
                    Toggle("Exclude In-Person Items", isOn: $excludeInPersonItems)
                } header: {
                    Text("Options")
                }

                // Items to order (full list, no limit)
                Section {
                    if itemsToOrder.isEmpty {
                        Text("No items to order")
                            .foregroundStyle(.secondary)
                            .italic()
                    } else {
                        ForEach(itemsToOrder) { item in
                            itemRow(item)
                                .swipeActions(edge: .trailing) {
                                    Button {
                                        excludeItem(item)
                                    } label: {
                                        Label("Exclude", systemImage: "xmark.circle")
                                    }
                                    .tint(.orange)
                                }
                        }
                    }
                } header: {
                    HStack {
                        Text("Items to Order")
                        Spacer()
                        Text("\(itemsToOrder.count)")
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    if !itemsToOrder.isEmpty {
                        Text("Swipe left to exclude items from this order")
                    }
                }

                // Excluded from order (full list)
                if !excludedFromOrder.isEmpty {
                    Section {
                        ForEach(excludedFromOrder) { item in
                            excludedItemRow(item)
                                .swipeActions(edge: .leading) {
                                    Button {
                                        includeItem(item)
                                    } label: {
                                        Label("Include", systemImage: "plus.circle")
                                    }
                                    .tint(.blue)
                                }
                        }
                    } header: {
                        HStack {
                            Text("Excluded from Order")
                            Spacer()
                            Text("\(excludedFromOrder.count)")
                                .foregroundStyle(.secondary)
                        }
                    } footer: {
                        Text("Swipe right to add items to this order. These items won't be checked off after ordering.")
                    }
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

                            Text("Instacart will match items based on availability. Please review your cart before placing the order.")
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
                        if hasManualChanges {
                            showCancelConfirmation = true
                        } else {
                            dismiss()
                        }
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
                    .disabled(isLoading || itemsToOrder.isEmpty || !instacartService.isConfigured)
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
            .confirmationDialog(
                "Discard Changes?",
                isPresented: $showCancelConfirmation,
                titleVisibility: .visible
            ) {
                Button("Discard Changes", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("You have made changes to this order. If you cancel now, you'll need to redo any manual adjustments.")
            }
            .sheet(item: $itemToEdit) { item in
                QuantityEditSheet(
                    item: item,
                    currentQuantity: quantityOverrides[item.id]?.quantity ?? item.quantity ?? 1,
                    currentUnit: quantityOverrides[item.id]?.unit ?? item.unit,
                    onSave: { newQuantity, newUnit in
                        quantityOverrides[item.id] = (quantity: newQuantity, unit: newUnit)
                        itemToEdit = nil
                    }
                )
                .presentationDetents([.height(280)])
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - View Builders

    private func helpRow(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 16)
            Text(text)
                .foregroundStyle(.secondary)
        }
    }

    private func itemRow(_ item: GroceryItem) -> some View {
        let override = quantityOverrides[item.id]
        let displayQty = override?.quantity ?? item.quantity
        let displayUnit = override?.unit ?? item.unit
        let hasOverride = override != nil

        return Button {
            itemToEdit = item
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .foregroundStyle(.primary)
                    if let qty = displayQty {
                        HStack(spacing: 4) {
                            Text(formatQuantity(qty, unit: displayUnit))
                                .font(.caption)
                                .foregroundStyle(hasOverride ? .blue : .secondary)
                            if hasOverride {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
                Spacer()
                if item.source == .staple {
                    Text("Staple")
                        .font(.caption2)
                        .foregroundStyle(.purple)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.1))
                        .clipShape(Capsule())
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }

    private func excludedItemRow(_ item: GroceryItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .foregroundStyle(.secondary)
                if let qty = item.quantity {
                    Text(formatQuantity(qty, unit: item.unit))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            exclusionReason(for: item)
        }
    }

    @ViewBuilder
    private func exclusionReason(for item: GroceryItem) -> some View {
        if manuallyExcludedIds.contains(item.id) {
            Text("Manual")
                .font(.caption2)
                .foregroundStyle(.orange)
        } else if let store = storeForItem(item), !store.isOnInstacart {
            Text(store.displayName)
                .font(.caption2)
                .foregroundStyle(.orange)
        } else if isInPersonItem(item) {
            Text("In-Person")
                .font(.caption2)
                .foregroundStyle(.orange)
        } else if item.source == .staple && !includeWeeklyStaples {
            Text("Staple")
                .font(.caption2)
                .foregroundStyle(.purple)
        }
    }

    // MARK: - Computed Properties

    /// Whether any manual changes have been made to this order
    private var hasManualChanges: Bool {
        !manuallyExcludedIds.isEmpty || !manuallyIncludedIds.isEmpty || !quantityOverrides.isEmpty
    }

    private var uncheckedItems: [GroceryItem] {
        viewModel.items.filter { !$0.isChecked }
    }

    /// Items that will be sent to Instacart
    private var itemsToOrder: [GroceryItem] {
        var items = uncheckedItems

        // Filter out staples if not including them
        if !includeWeeklyStaples {
            items = items.filter { $0.source != .staple }
        }

        // Apply Instacart filters (stores, in-person)
        items = instacartService.filterItemsForInstacart(
            items: items,
            preferences: viewModel.ingredientPreferences,
            excludeNonInstacart: excludeNonInstacartStores,
            excludeInPerson: excludeInPersonItems
        )

        // Remove manually excluded items
        items = items.filter { !manuallyExcludedIds.contains($0.id) }

        // Add back manually included items (unless they're staples and staples are off)
        let manuallyIncluded = uncheckedItems.filter { manuallyIncludedIds.contains($0.id) }
        for item in manuallyIncluded {
            if !items.contains(where: { $0.id == item.id }) {
                // Only add if not already there and passes staple check
                if includeWeeklyStaples || item.source != .staple {
                    items.append(item)
                }
            }
        }

        return items.sorted { $0.name < $1.name }
    }

    /// Items excluded from the order
    private var excludedFromOrder: [GroceryItem] {
        let orderedIds = Set(itemsToOrder.map { $0.id })
        return uncheckedItems
            .filter { !orderedIds.contains($0.id) }
            .sorted { $0.name < $1.name }
    }

    /// Items to order with quantity overrides applied
    private var itemsToOrderWithOverrides: [GroceryItem] {
        itemsToOrder.map { item in
            if let override = quantityOverrides[item.id] {
                var modifiedItem = item
                modifiedItem.quantity = override.quantity
                modifiedItem.unit = override.unit
                return modifiedItem
            }
            return item
        }
    }

    // MARK: - Actions

    private func excludeItem(_ item: GroceryItem) {
        manuallyExcludedIds.insert(item.id)
        manuallyIncludedIds.remove(item.id)
    }

    private func includeItem(_ item: GroceryItem) {
        manuallyIncludedIds.insert(item.id)
        manuallyExcludedIds.remove(item.id)
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
        guard !itemsToOrder.isEmpty else {
            error = "No items to send to Instacart"
            return
        }

        isLoading = true
        error = nil

        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            let title = "Groceries - \(dateFormatter.string(from: Date()))"

            // Use items with quantity overrides applied
            let url = try await instacartService.createShoppingList(
                items: itemsToOrderWithOverrides,
                ingredientPreferences: viewModel.ingredientPreferences,
                title: title
            )

            // Only check off items that were actually sent (not excluded)
            let sentItemIds = Set(itemsToOrder.map { $0.id })
            for item in viewModel.items where sentItemIds.contains(item.id) && !item.isChecked {
                try await viewModel.groceryService.toggleItem(item)
            }

            // Refresh the list
            await viewModel.fetchCurrentList()

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

// MARK: - Quantity Edit Sheet

struct QuantityEditSheet: View {
    let item: GroceryItem
    let currentQuantity: Double
    let currentUnit: String?
    let onSave: (Double, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var quantity: Double
    @State private var unit: String

    init(item: GroceryItem, currentQuantity: Double, currentUnit: String?, onSave: @escaping (Double, String?) -> Void) {
        self.item = item
        self.currentQuantity = currentQuantity
        self.currentUnit = currentUnit
        self.onSave = onSave
        self._quantity = State(initialValue: currentQuantity)
        self._unit = State(initialValue: currentUnit ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(item.name)
                        .font(.headline)
                } header: {
                    Text("Item")
                }

                Section {
                    HStack {
                        Text("Quantity")
                        Spacer()
                        HStack(spacing: 12) {
                            Button {
                                if quantity > 1 {
                                    quantity -= 1
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(quantity > 1 ? .blue : .gray)
                            }
                            .disabled(quantity <= 1)

                            Text(formatQuantity(quantity))
                                .font(.title3)
                                .fontWeight(.medium)
                                .frame(minWidth: 40)

                            Button {
                                quantity += 1
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    HStack {
                        Text("Unit")
                        Spacer()
                        TextField("e.g., lbs, oz, dozen", text: $unit)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Quantity for this order")
                } footer: {
                    Text("This change only applies to this Instacart order and won't affect your grocery list.")
                }
            }
            .navigationTitle("Edit Quantity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(quantity, unit.isEmpty ? nil : unit)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func formatQuantity(_ qty: Double) -> String {
        qty.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(qty))
            : String(format: "%.1f", qty)
    }
}

#Preview {
    InstacartOrderView(viewModel: GroceryViewModel())
}
