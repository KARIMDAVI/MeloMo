#!/bin/bash

# MeloMo Build Test Script
echo "🔧 MeloMo Build Test"
echo "===================="

# Check file structure
echo "📁 Checking file structure..."
find MeloMo -name "*.swift" | wc -l | xargs echo "Swift files found:"

# Check for duplicate definitions
echo ""
echo "🔍 Checking for duplicate definitions..."
duplicates=$(find MeloMo -name "*.swift" -exec basename {} \; | sort | uniq -d)
if [ -z "$duplicates" ]; then
    echo "✅ No duplicate file names found"
else
    echo "❌ Duplicate files found:"
    echo "$duplicates"
fi

# Check for common import issues
echo ""
echo "🔍 Checking for import issues..."
echo "Checking GoogleSignIn imports..."
grep -r "import GoogleSignIn" MeloMo/ || echo "✅ No direct GoogleSignIn imports found"

echo "Checking conditional imports..."
grep -r "#if canImport(GoogleSignIn)" MeloMo/ && echo "✅ Conditional imports found"

# Check for missing dependencies
echo ""
echo "🔍 Checking for missing dependencies..."
echo "Checking Haptics usage..."
haptics_usage=$(grep -r "Haptics\." MeloMo/ | wc -l)
echo "Haptics methods used: $haptics_usage"

echo "Checking MusicController usage..."
music_usage=$(grep -r "MusicController" MeloMo/ | wc -l)
echo "MusicController references: $music_usage"

echo "Checking AuthManager usage..."
auth_usage=$(grep -r "AuthManager" MeloMo/ | wc -l)
echo "AuthManager references: $auth_usage"

# Check project structure
echo ""
echo "📋 Project Structure:"
echo "Core/: $(find MeloMo/Core -name "*.swift" 2>/dev/null | wc -l) files"
echo "Models/: $(find MeloMo/Models -name "*.swift" 2>/dev/null | wc -l) files"
echo "Managers/: $(find MeloMo/Managers -name "*.swift" 2>/dev/null | wc -l) files"
echo "Views/: $(find MeloMo/Views -name "*.swift" 2>/dev/null | wc -l) files"
echo "Components/: $(find MeloMo/Components -name "*.swift" 2>/dev/null | wc -l) files"
echo "Utilities/: $(find MeloMo/Utilities -name "*.swift" 2>/dev/null | wc -l) files"

echo ""
echo "✅ Build test complete!"
echo ""
echo "🎯 Next steps:"
echo "1. Open Xcode"
echo "2. Clean Build Folder (Cmd+Shift+K)"
echo "3. Build Project (Cmd+B)"
echo "4. Run on Simulator (Cmd+R)"


