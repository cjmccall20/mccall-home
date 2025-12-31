# McCallHome - Household Management iOS App

## Overview
McCallHome is a SwiftUI iOS app for household management, focusing on meal planning, recipe management, grocery list generation, and household task coordination. It uses Supabase as the backend with PostgreSQL and Row Level Security (RLS) for multi-household support.

## Tech Stack
- **Frontend**: SwiftUI (iOS 17+)
- **Backend**: Supabase (PostgreSQL + Auth + Edge Functions)
- **Architecture**: MVVM with Services layer
- **Package Dependencies**:
  - Supabase Swift SDK
  - Google Sign-In

## Project Structure

```
McCallHome/
├── Config.swift                 # App configuration (Supabase URL, keys)
├── Secrets.swift               # Sensitive credentials (gitignored)
├── SupabaseClient.swift        # Supabase client singleton
├── MainTabView.swift           # Main tab navigation
├── McCallHomeApp.swift         # App entry point
│
├── Core/
│   ├── Extensions/
│   │   └── Date+Extensions.swift
│   ├── Managers/
│   │   └── AppearanceManager.swift  # Dark mode support
│   ├── Models/                  # Data models (Codable structs)
│   │   ├── User.swift
│   │   ├── Household.swift
│   │   ├── Recipe.swift
│   │   ├── MealPlanEntry.swift
│   │   ├── MealPlanTemplate.swift
│   │   ├── GroceryList.swift
│   │   ├── GroceryItem.swift
│   │   ├── Restaurant.swift
│   │   ├── HouseholdMember.swift
│   │   ├── HouseholdSettings.swift
│   │   ├── IngredientPreference.swift
│   │   ├── FoodLabel.swift
│   │   └── ...
│   └── Services/               # Data access layer
│       ├── AuthService.swift
│       ├── RecipeService.swift
│       ├── MealPlanService.swift
│       ├── GroceryService.swift
│       ├── MealPlanTemplateService.swift
│       └── ...
│
├── Features/
│   ├── Auth/                   # Login/Signup
│   ├── MealPlan/              # Meal planning
│   ├── Recipes/               # Recipe management
│   ├── Grocery/               # Grocery lists
│   ├── Restaurants/           # Restaurant & takeout
│   ├── Honeydew/              # Task management ("Honeydew list")
│   ├── Food/                  # Food tab container
│   ├── More/                  # Settings & preferences
│   └── Settings/              # Profile & household settings
│
└── supabase/
    ├── migrations/            # SQL migrations
    └── functions/             # Edge Functions
```

## Key Features

### 1. Meal Planning
- **Weekly calendar view** with days showing all meals
- **Meal types**: Breakfast, Lunch, Dinner, Snack
- **Meal options**:
  - Recipe (from recipe library)
  - Eat Out (restaurant selection with favorite orders)
  - Leftovers (with notes)
  - Simple ingredient (e.g., "Eggs", "Oatmeal")
- **Visual indicators**: Shows grocery status per meal
- **Servings override**: Adjust servings per meal
- **Assigned to**: Assign cooking to household member

### 2. Recipes
- **Recipe attributes**:
  - Title, description, image URL
  - Ingredients (name, quantity, unit, notes, optional flag)
  - Instructions (step-by-step)
  - Prep time, cook time
  - Base servings
  - Protein type (chicken, beef, pork, fish, vegetarian, etc.)
  - Dish category (main, side, dessert, etc.)
  - Meal category (breakfast, lunch, dinner, any)
  - Tags, source URL
- **Import from URL**: Paste recipe URL to auto-import
- **Ratings & Favorites**: Per-member ratings (1-5 stars)
- **Filtering**: By protein type, dish category, meal type

### 3. Grocery Lists
- **Smart generation**: AI-powered ingredient aggregation
- **Sources**: Meal plan recipes, manual additions, pantry staples
- **Categories**: Produce, dairy, meat, bakery, frozen, pantry, etc.
- **Item attributes**:
  - Name, quantity, unit
  - Store preference (Costco, Trader Joe's, etc.)
  - Checked status
  - Notes
- **List completion**: Mark shopping done, tracks history
- **Instacart integration** (planned): Send items to Instacart

### 4. Meal Plan Templates ("Saved Weeks")
- **Save current week as template**: Capture a week's meal plan
- **Apply template to any week**: Quick meal planning
- **Template builder**: Create templates from scratch
- **Day 1-7 generic format**: Not tied to specific dates

### 5. Restaurants & Takeout
- **Restaurant library**: Save favorite restaurants
- **Favorite orders**: Per-restaurant saved orders
- **Assign to meal**: Select restaurant + order for eat-out meals

### 6. Household Management
- **Household members**: Track family members (not app users)
- **Owner designation**: Household owner
- **Invitations**: Invite others to join household
- **Settings**:
  - Week start day (Sunday/Monday)
  - Grocery shopping day
  - Morning email preferences
  - Dark mode

### 7. Ingredient Preferences
- **Per-ingredient customization**:
  - Display name / brand
  - Preferred store
  - Food labels (organic, grass-fed, wild-caught, kosher, etc.)
  - Custom labels
  - In-person shopping flag
  - House staple / pantry staple flags

### 8. Honeydew Tasks
- Household task list (separate from meal planning)
- Task assignment to members
- Recurrence options

## Data Models

### MealPlanEntry
```swift
struct MealPlanEntry: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    var recipeId: UUID?
    var scheduledDate: Date
    var mealType: MealType  // breakfast, lunch, dinner, snack
    var servingsOverride: Int?
    var isEatOut: Bool
    var eatOutLocation: String?
    var restaurantId: UUID?
    var orderIds: [UUID]
    var isLeftovers: Bool
    var leftoversNote: String?
    var isIngredientOnly: Bool
    var ingredientName: String?
    var ingredientQuantity: String?
    var assignedTo: UUID?
    var hasIngredients: Bool      // User already has ingredients
    var shoppedAt: Date?          // When shopped for

    var needsGroceries: Bool {    // Computed: needs to be included in grocery list
        !isEatOut && !isLeftovers && !hasIngredients && shoppedAt == nil
    }
}
```

### Recipe
```swift
struct Recipe: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    var title: String
    var description: String?
    var ingredients: [Ingredient]
    var instructions: [String]
    var prepTimeMinutes: Int?
    var cookTimeMinutes: Int?
    var baseServings: Int
    var imageUrl: String?
    var sourceUrl: String?
    var tags: [String]
    var proteinType: ProteinType
    var dishCategory: DishCategory
    var mealCategory: MealCategory
}
```

### MealPlanTemplate
```swift
struct MealPlanTemplate: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    var name: String
    var entries: [TemplateEntry]  // Day 0-6, meal type, recipe/restaurant/etc
    var isRotating: Bool
    var rotationOrder: Int?
    var notes: String?
}
```

## UI Structure

### Main Tabs
1. **Honeydew** - Task list
2. **Food** - Segmented control with:
   - Recipes
   - Meal Plan
   - Grocery
3. **More** - Settings, ingredients, saved weeks, feedback

### Meal Plan View
- Week header with navigation arrows
- 7-day grid showing each day
- Each day shows meals grouped by type
- Tap meal slot to add/edit
- Menu button for: Save Week, Load Saved Week, etc.

### Recipe List View
- Search bar
- Filter pills (protein type, dish category)
- Recipe cards with image, title, time, ratings
- Tap to view detail

### Grocery List View
- Category sections (expandable)
- Items with checkbox, name, quantity
- Swipe actions for edit/delete
- Generate button with date range picker
- Complete shopping button

## Authentication Flow
1. **Dev Mode** (`Config.skipAuthForDevelopment = true`):
   - Auto signs in with dev credentials
   - Creates user profile if doesn't exist
   - Enables RLS with real auth session

2. **Production Mode**:
   - Email/password auth via Supabase
   - Sign up creates household + user profile
   - Deep link support for invitations

## Row Level Security (RLS)
All tables have RLS policies:
- Users can only access data for their household
- Policies check `auth.uid()` against users table
- Example policy:
```sql
CREATE POLICY "Users can view their household recipes"
    ON recipes FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));
```

## Key Services

### GroceryService
- `generateSmartGroceryList()` - AI-powered generation
- `generateFromMealPlan()` - Fallback generation
- `onlyUnshoppedMeals` parameter - Skip already-shopped meals
- Preserves manual items and checked items on regeneration

### MealPlanService
- `fetchMealPlan(for:weekStart:)` - Get week's entries
- `addRecipeToMealPlan()` - Add recipe entry
- `updateEntry()` / `removeFromPlan()` - Modify entries

### MealPlanTemplateService
- `saveCurrentWeekAsTemplate()` - Save week as template
- `applyTemplate(to:weekStart:)` - Apply template to week
- `createTemplate()` / `updateTemplate()` / `deleteTemplate()`

## Current Development Issues

1. **RLS/Auth**: Dev sign-in may fail if credentials incorrect
   - Workaround: Disable RLS on tables for dev

2. **Grocery generation**: Now respects `needsGroceries` flag
   - `onlyUnshoppedMeals` parameter controls behavior

## Supabase Tables
- `users` - App users (linked to Supabase Auth)
- `households` - Households
- `household_members` - Non-app-user family members
- `household_settings` - Household preferences
- `recipes` - Recipe library
- `meal_plan_entries` - Scheduled meals
- `meal_plan_templates` - Saved week templates
- `grocery_lists` - Grocery lists
- `grocery_items` - Items in grocery lists
- `restaurants` - Saved restaurants
- `restaurant_orders` - Saved orders
- `ingredient_preferences` - Per-ingredient customization
- `recipe_ratings` - Per-member recipe ratings
- `tasks` - Honeydew tasks
- `household_invitations` - Pending invitations
- `feedback` - User feedback

## Edge Functions
- `generate-grocery-list` - AI-powered ingredient aggregation
- `send-feedback-email` - Email feedback to developers

## Future Features (Planned)
- Instacart integration for ordering
- Google Calendar sync
- Push notifications
- Rotating meal plan schedules
- Recipe import improvements
