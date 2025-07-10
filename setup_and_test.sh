#!/bin/bash

echo "🏏 Cricket Highlights App - Setup and Test Script"
echo "=================================================="

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first:"
    echo "   https://docs.flutter.dev/get-started/install"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n 1)"

# Check Flutter doctor
echo "🔍 Running Flutter doctor..."
flutter doctor

# Create project directory
PROJECT_NAME="cricket_highlights_app"
if [ -d "$PROJECT_NAME" ]; then
    echo "📁 Project directory exists. Cleaning..."
    rm -rf $PROJECT_NAME
fi

echo "🆕 Creating new Flutter project..."
flutter create $PROJECT_NAME
cd $PROJECT_NAME

# Note: At this point, you would copy all the files from our CodeProject
echo "📋 Please copy all the code files from the v0 project to this directory"
echo "   - Replace lib/ folder contents"
echo "   - Replace pubspec.yaml"
echo "   - Add assets/ folder if needed"

read -p "Press Enter after copying the files..."

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Generate code (for Hive adapters)
echo "🔨 Generating code..."
flutter packages pub run build_runner build

# Check for connected devices
echo "📱 Checking for connected devices..."
flutter devices

# Ask user how they want to test
echo ""
echo "How would you like to test the app?"
echo "1. Run on connected device/emulator"
echo "2. Build APK for manual installation"
echo "3. Run on web browser (limited functionality)"
echo "4. All of the above"

read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        echo "🚀 Running on device/emulator..."
        flutter run
        ;;
    2)
        echo "🔨 Building APK..."
        flutter build apk --release
        echo "✅ APK built successfully!"
        echo "📍 Location: build/app/outputs/flutter-apk/app-release.apk"
        ;;
    3)
        echo "🌐 Running on web..."
        flutter run -d chrome
        ;;
    4)
        echo "🔨 Building APK..."
        flutter build apk --release
        echo "🌐 Building web..."
        flutter build web
        echo "🚀 Running on device..."
        flutter run
        ;;
    *)
        echo "❌ Invalid choice"
        ;;
esac

echo ""
echo "🎉 Setup complete!"
echo "📱 APK location (if built): build/app/outputs/flutter-apk/app-release.apk"
echo "🌐 Web build (if built): build/web/"
