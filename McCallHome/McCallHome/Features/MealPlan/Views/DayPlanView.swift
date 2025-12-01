//
//  DayPlanView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct DayPlanView: View {
    let date: Date
    let recipe: Recipe?
    let onTap: () -> Void
    let onRemove: () -> Void

    var isToday: Bool {
        date.isToday
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Day header
            HStack {
                Text(date.shortWeekdayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isToday ? .blue : .secondary)

                Text("\(date.dayOfMonth)")
                    .font(.headline)
                    .foregroundStyle(isToday ? .blue : .primary)

                Spacer()

                if recipe != nil {
                    Button {
                        onRemove()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Recipe content
            Button {
                onTap()
            } label: {
                Group {
                    if let recipe = recipe {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recipe.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            if let prepTime = recipe.prepTime, let cookTime = recipe.cookTime {
                                Text("\(prepTime + cookTime)m")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        VStack {
                            Image(systemName: "plus")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                            Text("Add")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(isToday ? .blue.opacity(0.05) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isToday ? .blue.opacity(0.3) : .clear, lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        DayPlanView(
            date: Date(),
            recipe: Recipe(
                id: UUID(),
                householdId: UUID(),
                title: "Chicken Parmesan with Spaghetti",
                sourceUrl: nil,
                sourceType: .manual,
                baseServings: 4,
                ingredients: [],
                steps: [],
                tags: nil,
                prepTime: 20,
                cookTime: 30,
                notes: nil,
                createdAt: Date(),
                updatedAt: Date()
            ),
            onTap: {},
            onRemove: {}
        )

        DayPlanView(
            date: Date().adding(days: 1),
            recipe: nil,
            onTap: {},
            onRemove: {}
        )
    }
    .padding()
}
