#!/bin/bash

echo "🏏 Cricket Highlights APK Download Script"
echo "========================================"

# Configuration
REPO_OWNER="YOUR_USERNAME"  # Replace with your GitHub username
REPO_NAME="cricket-highlights-app"
API_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME"

echo "📡 Fetching latest release information..."

# Get latest release info
LATEST_RELEASE=$(curl -s "$API_URL/releases/latest")

if [ $? -ne 0 ]; then
    echo "❌ Failed to fetch release information"
    echo "🔧 Please check:"
    echo "   - Repository name: $REPO_OWNER/$REPO_NAME"
    echo "   - Internet connection"
    echo "   - Repository is public"
    exit 1
fi

# Extract download URL
DOWNLOAD_URL=$(echo "$LATEST_RELEASE" | grep -o '"browser_download_url": "[^"]*\.apk"' | cut -d'"' -f4)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "❌ No APK found in latest release"
    echo "🔧 Possible solutions:"
    echo "   - Wait for GitHub Actions to complete"
    echo "   - Check if build was successful"
    echo "   - Try manual download from GitHub"
    exit 1
fi

# Extract version info
VERSION=$(echo "$LATEST_RELEASE" | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
RELEASE_NAME=$(echo "$LATEST_RELEASE" | grep -o '"name": "[^"]*"' | cut -d'"' -f4)

echo "✅ Found release: $RELEASE_NAME ($VERSION)"
echo "📥 Download URL: $DOWNLOAD_URL"

# Download APK
APK_FILENAME="cricket-highlights-$VERSION.apk"
echo "⬇️  Downloading APK..."

curl -L -o "$APK_FILENAME" "$DOWNLOAD_URL"

if [ $? -eq 0 ]; then
    echo "✅ APK downloaded successfully: $APK_FILENAME"
    echo "📱 File size: $(du -h "$APK_FILENAME" | cut -f1)"
    echo ""
    echo "📋 Installation Instructions:"
    echo "1. Transfer APK to your Android device"
    echo "2. Enable 'Install from Unknown Sources' in Android settings"
    echo "3. Tap the APK file to install"
    echo "4. Grant required permissions when prompted"
    echo ""
    echo "🎉 Enjoy your Cricket Highlights app!"
else
    echo "❌ Download failed"
    echo "🔧 Try downloading manually from:"
    echo "   https://github.com/$REPO_OWNER/$REPO_NAME/releases/latest"
fi
