//
//  MainTabView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        TabView {
            HoneydewListView()
                .tabItem {
                    Label("Honeydew", systemImage: "checklist")
                }

            RecipeListView()
                .tabItem {
                    Label("Recipes", systemImage: "book")
                }

            MealPlanView()
                .tabItem {
                    Label("Meal Plan", systemImage: "calendar")
                }

            GroceryListView()
                .tabItem {
                    Label("Grocery", systemImage: "cart")
                }

            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle")
                }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
}
