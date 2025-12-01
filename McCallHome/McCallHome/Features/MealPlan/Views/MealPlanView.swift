//
//  MealPlanView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct MealPlanView: View {
    @StateObject private var viewModel = MealPlanViewModel()
    @State private var selectedDate: Date?
    @State private var showRecipePicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Week navigation
                weekNavigationHeader

                Divider()

                // Week grid
                if viewModel.isLoading && viewModel.entries.isEmpty {
                    Spacer()
                    ProgressView("Loading meal plan...")
                    Spacer()
                } else {
                    ScrollView {
                        weekGrid
                            .padding()
                    }
                }
            }
            .navigationTitle("Meal Plan")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Today") {
                        viewModel.goToCurrentWeek()
                    }
                    .disabled(viewModel.currentWeekStart == Calendar.current.startOfWeek(for: Date()))
                }
            }
            .task {
                await viewModel.fetchMealPlan()
            }
            .refreshable {
                await viewModel.fetchMealPlan()
            }
            .sheet(isPresented: $showRecipePicker) {
                if let date = selectedDate {
                    RecipePickerView(viewModel: viewModel, date: date)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                }
            }
        }
    }

    private var weekNavigationHeader: some View {
        HStack {
            Button {
                viewModel.goToPreviousWeek()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Spacer()

            Text(viewModel.weekRangeText)
                .font(.headline)

            Spacer()

            Button {
                viewModel.goToNextWeek()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(.bar)
    }

    private var weekGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible())], spacing: 12) {
            ForEach(viewModel.weekDays, id: \.self) { date in
                DayPlanView(
                    date: date,
                    recipe: viewModel.recipe(for: date),
                    onTap: {
                        selectedDate = date
                        showRecipePicker = true
                    },
                    onRemove: {
                        Task {
                            await viewModel.removeFromPlan(date: date)
                        }
                    }
                )
            }
        }
    }
}

#Preview {
    MealPlanView()
}
