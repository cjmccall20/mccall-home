# McCallHome App - Comprehensive Build Plan

## Overview
This document tracks the implementation of all features requested. Each section includes the feature, implementation details, and testing requirements.

## Current State (Dec 2, 2025)
- Basic app structure with Honeydew, Recipes, Meal Plan, Grocery, Restaurants
- Recipe scraper working with Claude API (but needs ingredient parsing improvements)
- Data decoding issues FIXED
- Household ID hardcoded as `00000000-0000-0000-0000-000000000001`

---

## PHASE 1: Database & Household Members

### 1.1 Household Members Table
- Create `household_members` table in Supabase
- Fields: id, household_id, name, email (optional), is_active, created_at
- Seed with Cooper and Ashlyn

### 1.2 HouseholdMember Model (Swift)
- Create model with proper decoding
- Create HouseholdMemberService

### 1.3 Household Members UI
- Add "Manage Household" in More/Settings tab
- List members, add new, edit, delete

### Testing 1:
- [ ] Can create household members via API
- [ ] Can fetch household members in app
- [ ] Can add/edit/remove members in UI

---

## PHASE 2: Honeydew Tasks Improvements

### 2.1 Task Assignment
- Update HoneydewTask model to use household_member_id instead of assigned_to UUID
- Update task creation UI to show member picker (Cooper, Ashlyn, Anyone)
- "Anyone" = null assignment

### 2.2 Default View = Incomplete Tasks
- Change default filter to show incomplete tasks

### 2.3 Completed Tasks View (Grouped by Day)
- "Done" filter shows tasks grouped by completion date
- Most recent day at top, scroll down for older days
- Section headers with date

### 2.4 Notification Times (Foundation)
- Store default notification preferences
- 8 AM EST daily email digest
- 5:30 PM EST push for outstanding
- 3 hours before for specific due times
- (Actual push/email implementation is Phase 2+)

### Testing 2:
- [ ] Can assign task to Cooper, Ashlyn, or Anyone
- [ ] Default view shows incomplete tasks
- [ ] Done view groups by completion day
- [ ] Member names display correctly on tasks

---

## PHASE 3: Recipe Improvements

### 3.1 Enhanced Scraper
- Improve Claude prompt to extract precise ingredients
- Format: {name, quantity (number), unit, notes}
- Ensure "1 1/2 pounds fresh cod" → {name: "fresh cod", quantity: 1.5, unit: "pounds"}

### 3.2 Recipe Edit Feature
- Add "Edit" option in recipe detail menu
- Open edit form with all fields editable
- Save changes to database

### 3.3 Recipe Notes Feature
- Add `notes` array field to recipes (or separate table)
- Each note: {text, created_at}
- UI to view/add notes on recipe detail

### Testing 3:
- [ ] Scrape fish & chips recipe - verify all ingredients with quantities
- [ ] Edit a recipe title - verify it saves
- [ ] Add a note to a recipe - verify it persists

---

## PHASE 4: Meal Planner Fixes

### 4.1 Search Bar at Top
- Move recipe search to top of add meal sheet

### 4.2 Fix Add Dish Bug
- Debug why adding dishes doesn't work
- Ensure meal plan entries save correctly

### 4.3 Meal Slot Interaction
- Tap on meal shows detail sheet
- Can see all dishes in that slot
- Can add more dishes from there

### Testing 4:
- [ ] Search bar is at top when adding meal
- [ ] Can add Fish & Chips to Dec 5 dinner
- [ ] Can add a side dish to same meal slot
- [ ] Tapping meal shows all dishes

---

## PHASE 5: Claude-Powered Grocery List

### 5.1 Grocery Generation Edge Function
- New edge function or enhance existing
- Input: All recipes for date range with servings
- Claude processes and returns smart grocery list

### 5.2 Smart Grocery Features
- Combine like items across recipes
- Convert to store quantities (cups → gallons)
- Proper categorization
- Separate pantry staples

### 5.3 Update Grocery UI
- Show Claude-generated list
- Staples in separate section (pantry check)

### Testing 5:
- [ ] Generate list for week with multiple recipes
- [ ] Milk from multiple recipes combines correctly
- [ ] Spices show as "pantry check" not specific amounts
- [ ] No garbage data (links, vote counts, etc.)

---

## PHASE 6: Restaurant Feature Complete

### 6.1 Add Restaurant UI
- Form to add new restaurant
- Fields: name, cuisine type, address, phone, website, notes, is_favorite

### 6.2 Restaurant Orders Redesign
- Orders tied to household_member_id
- Order has a "name" field (e.g., "Breakfast Order", "Lunch Order")
- Multiple named orders per person per restaurant

### 6.3 Restaurant Detail View
- Show restaurant info
- List orders grouped by household member
- Each member can have multiple named orders

### Testing 6:
- [ ] Can add Chick-fil-A restaurant
- [ ] Can add "Breakfast Order" for Cooper
- [ ] Can add "Lunch Order" for Cooper (separate)
- [ ] Can add orders for Ashlyn too
- [ ] Orders display correctly grouped by person

---

## PHASE 7: End-to-End Testing

### Full Flow Test:
1. Create household members (Cooper, Ashlyn) ✓ verify in DB
2. Scrape recipe: https://tastesbetterfromscratch.com/taco-soup/
3. Verify ingredients are clean with quantities
4. Add recipe to meal plan for Dec 5 dinner
5. Add a side dish to same meal
6. Generate grocery list for Dec 3-10
7. Verify grocery list is smart (combined, categorized, no garbage)
8. Create a Honeydew task assigned to Cooper
9. Complete the task, verify it shows in Done grouped by today
10. Add a restaurant (Chick-fil-A)
11. Add breakfast order for Cooper
12. Add lunch order for Ashlyn

---

## Implementation Order:
1. Phase 1 (Household Members) - Foundation for everything else
2. Phase 6 (Restaurants) - Uses household members
3. Phase 2 (Honeydew) - Uses household members
4. Phase 3 (Recipes) - Independent improvements
5. Phase 4 (Meal Planner) - Bug fixes
6. Phase 5 (Grocery) - Depends on clean recipe data
7. Phase 7 (E2E Testing) - Verify everything

---

## Files to Create/Modify:

### New Files:
- `HouseholdMember.swift` (model)
- `HouseholdMemberService.swift` (service)
- `HouseholdMembersView.swift` (UI)
- `EditRecipeView.swift` (UI)
- `supabase/functions/generate-grocery/index.ts` (edge function)

### Modified Files:
- `HoneydewTask.swift` - assignment field
- `HoneydewTasksView.swift` - assignment picker, done grouping
- `Recipe.swift` - notes field
- `RecipeDetailView.swift` - edit/notes buttons
- `scrape-recipe/index.ts` - better ingredient parsing
- `MealPlanView.swift` - search at top, add dish fix
- `Restaurant.swift` - verify structure
- `RestaurantOrder.swift` - add name field, member_id
- `RestaurantDetailView.swift` - grouped orders UI

### Database Migrations:
- `household_members` table
- `restaurant_orders.name` column
- `restaurant_orders.household_member_id` column

---

## Progress Tracking:
- [ ] Phase 1: Household Members
- [ ] Phase 2: Honeydew Improvements
- [ ] Phase 3: Recipe Improvements
- [ ] Phase 4: Meal Planner Fixes
- [ ] Phase 5: Smart Grocery List
- [ ] Phase 6: Restaurant Feature
- [ ] Phase 7: E2E Testing

Last Updated: Dec 2, 2025
