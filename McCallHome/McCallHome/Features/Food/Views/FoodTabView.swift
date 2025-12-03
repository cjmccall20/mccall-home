//
//  FoodTabView.swift
//  McCallHome
//
//  Created by Claude on 12/3/25.
//

import SwiftUI

/// Combined Food tab with segmented picker for Recipes, Meal Plan, and Grocery
struct FoodTabView: View {
    enum FoodSection: String, CaseIterable {
        case recipes = "Recipes"
        case mealPlan = "Meal Plan"
        case grocery = "Grocery"
    }

    @State private var selectedSection: FoodSection = .mealPlan

    var body: some View {
        VStack(spacing: 0) {
            // Section picker
            Picker("Section", selection: $selectedSection) {
                ForEach(FoodSection.allCases, id: \.self) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 4)

            // Content
            switch selectedSection {
            case .recipes:
                RecipeListView()
            case .mealPlan:
                MealPlanView()
            case .grocery:
                GroceryListView()
            }
        }
    }
}

#Preview {
    FoodTabView()
}
