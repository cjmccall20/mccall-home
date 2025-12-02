//
//  DayPlanView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct DayPlanView: View {
    let date: Date
    @ObservedObject var viewModel: MealPlanViewModel
    let onEmptySlotTap: (MealPlanEntry.MealType) -> Void
    let onFilledSlotTap: (MealPlanEntry.MealType) -> Void
    let onAddDishTap: (MealPlanEntry.MealType) -> Void
    let onRemove: (MealPlanEntry) -> Void

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
            }

            // Meal slots
            VStack(spacing: 6) {
                ForEach(MealPlanEntry.MealType.allCases, id: \.self) { mealType in
                    mealSlotView(for: mealType)
                }
            }
        }
        .padding(12)
        .background(isToday ? .blue.opacity(0.05) : Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isToday ? .blue.opacity(0.3) : Color(.separator).opacity(0.3), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func mealSlotView(for mealType: MealPlanEntry.MealType) -> some View {
        let slotEntries = viewModel.entries(for: date, mealType: mealType)

        VStack(spacing: 4) {
            if slotEntries.isEmpty {
                // Empty slot - tap to add
                HStack(spacing: 8) {
                    Image(systemName: mealType.iconName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 16)

                    Button {
                        onEmptySlotTap(mealType)
                    } label: {
                        HStack {
                            Text(mealType.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Image(systemName: "plus")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                // Has entries - tap to view detail
                ForEach(Array(slotEntries.enumerated()), id: \.element.id) { index, entry in
                    HStack(spacing: 8) {
                        // Only show meal icon on first entry
                        if index == 0 {
                            Image(systemName: mealType.iconName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 16)
                        } else {
                            // Indent subsequent entries
                            Color.clear.frame(width: 16)
                        }

                        Button {
                            onFilledSlotTap(mealType)
                        } label: {
                            HStack {
                                entryContentView(for: entry)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)

                        // Cooking assignment button (tap to cycle)
                        assignmentButton(for: entry)

                        Button {
                            onRemove(entry)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(mealType.backgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                // Add more button when there are already entries
                HStack(spacing: 8) {
                    Color.clear.frame(width: 16)

                    Button {
                        onAddDishTap(mealType)
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                                .font(.caption2)
                            Text("Add dish")
                                .font(.caption2)
                            Spacer()
                        }
                        .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
    }

    @ViewBuilder
    private func assignmentButton(for entry: MealPlanEntry) -> some View {
        let member = viewModel.assignedMember(for: entry)

        Button {
            Task {
                await viewModel.cycleAssignment(for: entry)
            }
        } label: {
            if let member = member {
                // Show member initial in colored circle
                Text(member.initial)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(colorForMember(member))
                    .clipShape(Circle())
            } else {
                // Show unassigned icon
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    // Generate consistent color for member based on their ID
    private func colorForMember(_ member: HouseholdMember) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .teal]
        let index = abs(member.id.hashValue) % colors.count
        return colors[index]
    }

    @ViewBuilder
    private func entryContentView(for entry: MealPlanEntry) -> some View {
        if entry.isEatOut {
            Image(systemName: "fork.knife")
                .font(.caption)
                .foregroundStyle(.orange)
            Text(entry.eatOutLocation ?? "Eat Out")
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(1)
        } else if entry.isLeftovers {
            Image(systemName: "takeoutbag.and.cup.and.straw")
                .font(.caption)
                .foregroundStyle(.green)
            Text(entry.leftoversNote ?? "Leftovers")
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(1)
        } else if let recipe = viewModel.recipe(for: entry) {
            // Show dish category icon for recipes
            Image(systemName: recipe.dishCategory.iconName)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(recipe.title)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(1)

            if let servings = entry.servingsOverride {
                Text("(\(servings))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - MealType Extensions

extension MealPlanEntry.MealType {
    var iconName: String {
        switch self {
        case .breakfast: return "sunrise"
        case .lunch: return "sun.max"
        case .dinner: return "moon.stars"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .breakfast: return .orange.opacity(0.1)
        case .lunch: return .yellow.opacity(0.1)
        case .dinner: return .blue.opacity(0.1)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        DayPlanView(
            date: Date(),
            viewModel: MealPlanViewModel(),
            onEmptySlotTap: { _ in },
            onFilledSlotTap: { _ in },
            onAddDishTap: { _ in },
            onRemove: { _ in }
        )

        DayPlanView(
            date: Date().adding(days: 1),
            viewModel: MealPlanViewModel(),
            onEmptySlotTap: { _ in },
            onFilledSlotTap: { _ in },
            onAddDishTap: { _ in },
            onRemove: { _ in }
        )
    }
    .padding()
}
