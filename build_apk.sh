#!/bin/bash

echo "🏏 Cricket Highlights App - APK Builder"
echo "======================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed!"
    echo "Please install Flutter from: https://docs.flutter.dev/get-started/install"
    exit 1
fi

print_success "Flutter found: $(flutter --version | head -n 1)"

# Check Flutter doctor
print_status "Running Flutter doctor..."
flutter doctor

# Check if we're in a Flutter project
if [ ! -f "pubspec.yaml" ]; then
    print_error "Not in a Flutter project directory!"
    echo "Please run this script from the root of your Flutter project."
    exit 1
fi

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean

# Get dependencies
print_status "Getting dependencies..."
flutter pub get

# Generate code (for Hive adapters)
print_status "Generating code..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Build APK variants
print_status "Building APK variants..."

# Debug APK
print_status "Building debug APK..."
flutter build apk --debug
if [ $? -eq 0 ]; then
    print_success "Debug APK built successfully!"
else
    print_error "Debug APK build failed!"
fi

# Release APK
print_status "Building release APK..."
flutter build apk --release
if [ $? -eq 0 ]; then
    print_success "Release APK built successfully!"
else
    print_error "Release APK build failed!"
    exit 1
fi

# Profile APK
print_status "Building profile APK..."
flutter build apk --profile
if [ $? -eq 0 ]; then
    print_success "Profile APK built successfully!"
else
    print_warning "Profile APK build failed (optional)"
fi

# Create output directory
OUTPUT_DIR="apk_output"
mkdir -p $OUTPUT_DIR

# Copy APKs to output directory
print_status "Copying APKs to output directory..."

if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    cp build/app/outputs/flutter-apk/app-release.apk $OUTPUT_DIR/cricket-highlights-release.apk
    print_success "Release APK copied to $OUTPUT_DIR/cricket-highlights-release.apk"
fi

if [ -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
    cp build/app/outputs/flutter-apk/app-debug.apk $OUTPUT_DIR/cricket-highlights-debug.apk
    print_success "Debug APK copied to $OUTPUT_DIR/cricket-highlights-debug.apk"
fi

if [ -f "build/app/outputs/flutter-apk/app-profile.apk" ]; then
    cp build/app/outputs/flutter-apk/app-profile.apk $OUTPUT_DIR/cricket-highlights-profile.apk
    print_success "Profile APK copied to $OUTPUT_DIR/cricket-highlights-profile.apk"
fi

# Get APK info
print_status "APK Information:"
echo "=================="

for apk in $OUTPUT_DIR/*.apk; do
    if [ -f "$apk" ]; then
        echo "📱 $(basename $apk)"
        echo "   Size: $(du -h $apk | cut -f1)"
        echo "   Path: $apk"
        echo ""
    fi
done

# Create installation instructions
cat > $OUTPUT_DIR/INSTALL_INSTRUCTIONS.md << 'EOF'
# Cricket Highlights App - Installation Instructions

## 🏏 About
AI-powered cricket highlight detection app that works offline.

## 📱 Installation Steps

### For Android:
1. **Download APK**: Choose the appropriate APK file:
   - `cricket-highlights-release.apk` - Recommended for regular use
   - `cricket-highlights-debug.apk` - For debugging (larger file)
   - `cricket-highlights-profile.apk` - For performance testing

2. **Enable Unknown Sources**:
   - Go to Settings > Security (or Privacy)
   - Enable "Install from Unknown Sources" or "Allow from this source"

3. **Install APK**:
   - Open the downloaded APK file
   - Follow installation prompts
   - Grant required permissions

4. **Grant Permissions**:
   - Storage: Required for video file access
   - Camera: Required for video recording (optional)

## 🔧 Requirements
- Android 7.0 (API level 24) or higher
- 3GB+ RAM recommended
- 2GB+ free storage space
- ARM64 processor recommended for best performance

## 🚀 First Run
1. Open the app
2. Go to Settings and download AI models (recommended)
3. Upload a cricket video to test
4. Analyze the video to detect highlights

## 🎯 Testing
- Try with cricket videos containing:
  - Clear audio (bat hits, crowd noise)
  - Visible celebrations
  - Scoreboard changes
  - Duration: 2-30 minutes optimal

## 🐛 Troubleshooting
- **App won't install**: Check Android version and storage space
- **App crashes**: Ensure device has sufficient RAM
- **Analysis fails**: Download AI models in Settings
- **Video upload fails**: Check storage permissions

## 📞 Support
For issues, please check the GitHub repository or create an issue.
EOF

print_success "Installation instructions created: $OUTPUT_DIR/INSTALL_INSTRUCTIONS.md"

# Create QR code for easy download (if qrencode is available)
if command -v qrencode &> /dev/null; then
    print_status "Generating QR code for GitHub releases..."
    echo "https://github.com/YOUR_USERNAME/cricket-highlights-app/releases/latest" | qrencode -t UTF8
fi

echo ""
echo "🎉 APK Build Complete!"
echo "======================"
echo "📍 APK Location: $OUTPUT_DIR/"
echo "📋 Next Steps:"
echo "   1. Test the APK on your Android device"
echo "   2. Upload to your GitHub repository"
echo "   3. Create a release with the APK attached"
echo ""
echo "🚀 To deploy via GitHub Actions:"
echo "   git add ."
echo "   git commit -m 'Add APK build workflow'"
echo "   git push origin main"
echo ""
echo "The APK will be automatically built and available in:"
echo "   - GitHub Actions artifacts"
echo "   - GitHub releases (if on main branch)"
