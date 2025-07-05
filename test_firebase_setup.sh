#!/bin/bash

echo "🔍 Testing Firebase Setup..."

# Check for Firebase configuration files
echo -e "\n📋 Checking configuration files:"
if [ -f "GoogleService-Info.plist" ]; then
    echo "✅ GoogleService-Info.plist found"
else
    echo "❌ GoogleService-Info.plist missing"
fi

if [ -f "Package.swift" ]; then
    echo "✅ Package.swift found"
    echo "   Dependencies:"
    grep -A5 "dependencies:" Package.swift | grep "package:" | sed 's/^/   /'
    if grep -q '"-ObjC"' Package.swift; then
        echo "   ✅ Has -ObjC linker flag"
    else
        echo "   ⚠️  Missing -ObjC linker flag"
    fi
else
    echo "❌ Package.swift missing"
fi

if [ -f "Podfile" ]; then
    echo "✅ Podfile found"
else
    echo "⚠️  Podfile found (alternative to SPM)"
fi

# Check Swift files
echo -e "\n📱 Checking Swift files:"
if [ -f "Sources/FlirtFrameApp.swift" ]; then
    echo "✅ FlirtFrameApp.swift found"
    if grep -q "@UIApplicationDelegateAdaptor" Sources/FlirtFrameApp.swift; then
        echo "   ✅ Uses UIApplicationDelegateAdaptor"
    else
        echo "   ⚠️  Missing UIApplicationDelegateAdaptor"
    fi
else
    echo "❌ FlirtFrameApp.swift missing"
fi

if [ -f "Sources/AppDelegate.swift" ]; then
    echo "✅ AppDelegate.swift found"
    if grep -q "FirebaseApp.configure()" Sources/AppDelegate.swift; then
        echo "   ✅ Calls FirebaseApp.configure()"
    else
        echo "   ⚠️  Missing FirebaseApp.configure()"
    fi
else
    echo "❌ AppDelegate.swift missing"
fi

if [ -f "Sources/Firebase/FirebaseManager.swift" ]; then
    echo "✅ FirebaseManager.swift found"
    if grep -q "import Firebase" Sources/Firebase/FirebaseManager.swift; then
        echo "   ⚠️  Direct Firebase imports detected"
    fi
else
    echo "❌ FirebaseManager.swift missing"
fi

# Test SPM resolution
echo -e "\n🔧 Testing Swift Package Manager:"
if command -v swift &> /dev/null; then
    echo "✅ Swift available"
    swift --version
    
    if [ -f "Package.swift" ]; then
        echo -e "\n📦 Resolving packages..."
        swift package resolve && echo "✅ Package resolution successful" || echo "❌ Package resolution failed"
    fi
else
    echo "❌ Swift not available (run on macOS)"
fi

# Check for duplicate @main
echo -e "\n🔍 Checking for duplicate @main:"
MAIN_COUNT=$(find Sources -name "*.swift" -exec grep -l "@main" {} \; | wc -l)
if [ "$MAIN_COUNT" -eq 1 ]; then
    echo "✅ Single @main found"
    find Sources -name "*.swift" -exec grep -l "@main" {} \; | sed 's/^/   /'
elif [ "$MAIN_COUNT" -eq 0 ]; then
    echo "❌ No @main found"
else
    echo "❌ Multiple @main found ($MAIN_COUNT):"
    find Sources -name "*.swift" -exec grep -l "@main" {} \; | sed 's/^/   /'
fi

echo -e "\n✨ Test complete!"