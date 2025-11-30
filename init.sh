#!/bin/bash
# McCall Home - Development Environment Initialization
# Run this at the start of each Claude Code session

set -e

echo "🏠 McCall Home - Initializing Development Environment"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "feature_list.json" ]; then
    echo -e "${RED}Error: Not in mccall-home project directory${NC}"
    echo "Please cd to the project root"
    exit 1
fi

echo -e "${GREEN}✓ Project directory confirmed${NC}"

# Check for Xcode project
if [ -d "ios/McCallHome.xcodeproj" ]; then
    echo -e "${GREEN}✓ Xcode project exists${NC}"
else
    echo -e "${YELLOW}⚠ Xcode project not found - needs creation${NC}"
fi

# Check for required environment variables
check_env() {
    if [ -z "${!1}" ]; then
        echo -e "${YELLOW}⚠ Missing: $1${NC}"
        return 1
    else
        echo -e "${GREEN}✓ $1 is set${NC}"
        return 0
    fi
}

echo ""
echo "Checking environment variables..."
check_env "SUPABASE_URL" || true
check_env "SUPABASE_ANON_KEY" || true

# Load from .env if exists
if [ -f ".env" ]; then
    echo ""
    echo "Loading .env file..."
    export $(cat .env | grep -v '^#' | xargs)
    echo -e "${GREEN}✓ Environment loaded from .env${NC}"
fi

# Show feature progress
echo ""
echo "Feature Progress:"
echo "-----------------"
if command -v jq &> /dev/null; then
    TOTAL=$(jq '.features | length' feature_list.json)
    COMPLETE=$(jq '[.features[] | select(.passes == true)] | length' feature_list.json)
    PERCENT=$((COMPLETE * 100 / TOTAL))
    echo "Completed: $COMPLETE / $TOTAL ($PERCENT%)"
    
    echo ""
    echo "Next incomplete features:"
    jq -r '.features[] | select(.passes == false) | "  - [\(.id)] \(.description)"' feature_list.json | head -5
else
    echo "Install jq for feature tracking: brew install jq"
fi

# Show last progress entry
echo ""
echo "Last Session Notes:"
echo "-------------------"
tail -20 claude-progress.txt 2>/dev/null || echo "No progress file yet"

echo ""
echo "=================================================="
echo -e "${GREEN}Ready for development!${NC}"
echo ""
echo "Quick commands:"
echo "  - Open Xcode: open ios/McCallHome.xcodeproj"
echo "  - Run iOS Simulator: (from Xcode, Cmd+R)"
echo "  - View progress: cat claude-progress.txt"
echo "  - View features: cat feature_list.json | jq '.features[] | select(.passes == false)'"
