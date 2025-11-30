# McCall Home 🏠

A household management iOS app for the McCall family.

## Features

- **Honeydew List**: Assign tasks to each other with due dates, priorities, and completion notifications
- **Recipe Database**: Store recipes manually or import from URLs
- **Meal Planning**: Weekly dinner planning with drag-and-drop
- **Grocery Lists**: Auto-generated from meal plans, organized by category
- **Offline Support**: Works at the grocery store with no signal

## Tech Stack

- **iOS**: SwiftUI, iOS 17+, SwiftData
- **Backend**: Supabase (PostgreSQL, Auth, Edge Functions, Realtime)
- **Recipe Scraping**: Firecrawl
- **Push Notifications**: APNs via Supabase

## Development Setup

### Prerequisites

1. Xcode 15+ (from App Store)
2. Apple Developer Account ($99/year)
3. Supabase account (free tier)
4. Node.js 18+ (for Supabase CLI)

### Environment Setup

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Fill in your credentials in `.env`

3. Install Supabase CLI:
   ```bash
   brew install supabase/tap/supabase
   ```

### Running the App

1. Open `ios/McCallHome.xcodeproj` in Xcode
2. Select your target device/simulator
3. Press Cmd+R to build and run

### Development Workflow

This project uses a structured session-based development approach:

1. **Start each session** by running `./init.sh`
2. **Check `claude-progress.txt`** for context from previous sessions
3. **Work on ONE feature** from `feature_list.json`
4. **Mark feature complete** when done
5. **Update progress file** before ending session
6. **Commit with descriptive message**

## Project Structure

```
mccall-home/
├── ios/                      # Xcode project
│   └── McCallHome/
│       ├── App/              # App entry point
│       ├── Features/         # Feature modules
│       │   ├── Auth/
│       │   ├── Honeydew/
│       │   ├── Recipes/
│       │   ├── MealPlan/
│       │   ├── GroceryList/
│       │   └── Settings/
│       ├── Core/
│       │   ├── Models/       # Data models
│       │   ├── Services/     # API clients
│       │   └── Persistence/  # SwiftData
│       └── Resources/
├── supabase/
│   ├── migrations/           # SQL schema
│   └── functions/            # Edge functions
├── init.sh                   # Dev environment setup
├── feature_list.json         # Feature tracking
└── claude-progress.txt       # Session notes
```

## Database Schema

See `supabase/migrations/` for the complete schema.

Key tables:
- `households` - Family unit
- `users` - Household members
- `tasks` - Honeydew items
- `recipes` - Recipe database
- `meal_plan` - Weekly dinner assignments
- `grocery_lists` - Generated shopping lists
- `grocery_items` - Individual items
- `pantry_staples` - Items to verify before shopping

## API Keys Required

- Supabase URL & Keys
- Firecrawl API Key (recipe scraping)
- Anthropic API Key (recipe text parsing)
- Apple Push Notification credentials

## License

Private project - not for distribution.
