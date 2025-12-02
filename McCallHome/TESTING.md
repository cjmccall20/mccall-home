# McCallHome App - Core Flows & Testing

## Core Flows

### 1. Authentication & Setup
- Dev mode initialization with test household
- User profile association with household

### 2. Recipe Management
- **Create manually**: Enter title, ingredients, steps → Save to DB
- **Import from URL**: Scrape URL → Preview → Select category/protein → Save
- **View/Edit/Delete**: CRUD operations on recipes
- **Filter/Search**: By protein type, search text

### 3. Meal Planning
- **View week**: Load entries for current week
- **Add recipe**: Select date/meal → Pick recipe → Set servings → Save entry
- **Add eat out**: Select date/meal → Enter location → Save entry
- **Add leftovers**: Select date/meal → Enter note → Save entry
- **Multiple dishes**: Add additional entries to same slot
- **Remove**: Delete entry from slot
- **Navigate**: Previous/next week

### 4. Grocery List Generation
- **Generate (this week)**: Fetch week's meal plan → Aggregate ingredients → Create list
- **Generate (custom range)**: Select dates → Fetch entries → Aggregate → Create list
- **Manual items**: Add items not from recipes
- **Check/uncheck**: Toggle purchased status
- **Clear**: Remove checked or all items

### 5. Honeydew Tasks
- Create task with title
- Toggle completion
- Delete task

### 6. Restaurant Database
- Add restaurant with details
- Add orders with items
- Track favorite dishes
- View order history

## Testing Approach

### A. Edge Function Testing (curl)
- Test scrape-recipe function directly

### B. Database Operations (SQL queries via Supabase)
- Verify table structures
- Test CRUD operations
- Check constraint validity

### C. Service Layer Testing (Swift)
- Unit tests for each service
- Integration tests for full flows
