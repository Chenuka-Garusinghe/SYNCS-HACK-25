# Community Images Folder

## 📁 Where to Place Your Images

Place your community images in this folder: `assets/community/`

## 🖼️ Supported Image Formats
- **JPG/JPEG** (recommended for photos)
- **PNG** (good for graphics with transparency)
- **WebP** (modern, efficient format)

## 📝 How to Add New Images

1. **Place your image file** in this folder
2. **Update the code** in `lib/screens/community_page.dart`
3. **Add the image path** to the `_communityImages` list

## 🔧 Example Code Update

```dart
static const List<Map<String, dynamic>> _communityImages = [
  {
    'imagePath': 'assets/community/your_image.jpg',  // ← Update this path
    'title': 'Your Title',                           // ← Update this title
    'subtitle': 'Your description',                  // ← Update this subtitle
  },
  // ... more images
];
```

## 📱 Image Recommendations

- **Aspect Ratio**: 1:1 (square) works best for the grid
- **Resolution**: 400x400px minimum, 800x800px recommended
- **File Size**: Keep under 500KB for optimal performance
- **Content**: Community sustainability projects, eco-friendly initiatives, etc.

## 🚀 After Adding Images

1. Run `flutter pub get` to refresh assets
2. Restart your app to see the new images
3. Images will automatically fit in the grid layout

## 📂 Current Sample Images

The app currently expects these images (you can replace them):
- `eco_building.jpg` - Sustainable architecture
- `nature_progress.jpg` - Environmental progress
- `green_city.jpg` - Urban sustainability
- `community_garden.jpg` - Local food production
- `solar_installation.jpg` - Renewable energy
- `tree_planting.jpg` - Reforestation efforts
