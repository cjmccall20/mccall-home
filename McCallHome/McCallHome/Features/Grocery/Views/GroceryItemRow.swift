//
//  GroceryItemRow.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct GroceryItemRow: View {
    let item: GroceryItem
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                onToggle()
            } label: {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isChecked ? .green : .secondary)
            }
            .buttonStyle(.plain)

            // Item details
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                    .strikethrough(item.isChecked)
                    .foregroundStyle(item.isChecked ? .secondary : .primary)

                if let quantity = item.quantity {
                    HStack(spacing: 4) {
                        Text(formatQuantity(quantity))
                        if let unit = item.unit {
                            Text(unit)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
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
