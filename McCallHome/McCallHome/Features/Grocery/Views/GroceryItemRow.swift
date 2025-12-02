//
//  GroceryItemRow.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct GroceryItemRow: View {
    let item: GroceryItem
    var ingredientPreference: IngredientPreference?
    let onToggle: () -> Void
    let onDelete: () -> Void

    /// Display name - uses preference display name if available, otherwise item name
    var displayName: String {
        ingredientPreference?.displayName ?? item.name
    }

    /// Whether this item should be selected in person
    var isInPerson: Bool {
        ingredientPreference?.isInPerson ?? false
    }

    /// Preferred store for this item
    var preferredStore: Store? {
        ingredientPreference?.preferredStore
    }

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox or Store icon
            Button {
                onToggle()
            } label: {
                if item.isChecked {
                    // Always show checkmark when checked
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                } else if let store = preferredStore {
                    // Show store icon when unchecked and has store preference
                    StoreIconView(store: store, size: 26)
                } else {
                    // Regular unchecked circle
                    Image(systemName: "circle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            // Item details
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.body)
                    .strikethrough(item.isChecked)
                    .foregroundStyle(item.isChecked ? .secondary : .primary)

                HStack(spacing: 4) {
                    if let quantity = item.quantity {
                        Text(formatQuantity(quantity))
                        if let unit = item.unit {
                            Text(unit)
                        }
                    }

                    // Show in-person indicator
                    if isInPerson && !item.isChecked {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Delete button
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.subheadline)
                    .foregroundStyle(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            isInPerson && !item.isChecked
                ? Color.orange.opacity(0.08)
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func formatQuantity(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}

#Preview {
    VStack {
        GroceryItemRow(
            item: GroceryItem(
                id: UUID(),
                groceryListId: UUID(),
                name: "Chicken breast",
                quantity: 2,
                unit: "lbs",
                category: .meat,
                isChecked: false,
                sortOrder: 0,
                createdAt: Date()
            ),
            onToggle: {},
            onDelete: {}
        )

        GroceryItemRow(
            item: GroceryItem(
                id: UUID(),
                groceryListId: UUID(),
                name: "Milk",
                quantity: 1,
                unit: "gallon",
                category: .dairy,
                isChecked: true,
                sortOrder: 1,
                createdAt: Date()
            ),
            onToggle: {},
            onDelete: {}
        )
    }
    .padding()
}
