# FaceMatch · DESIGN.md

**Design Token Spec for FaceMatch — Makeup Transfer AI App**
*Author: Hermes Agent · Version: 1.0.0 · Updated: 2026-06-24*

---

## 1. Product Identity

| Token | Value |
|-------|-------|
| `product.name` | FaceMatch |
| `product.name.cn` | 妆仿 |
| `product.tagline` | 看见你的妆，复制你的美 |
| `product.tagline.en` | See the look. Make it yours. |
| `product.platforms` | iOS 18.0+, Android 13.0+ |
| `product.framework` | Flutter 3.41+ |

## 2. Color Palette

### Primary — Rose Quartz
```yaml
colors:
  primary_50: '#FFF0F3'   # Lightest tint — backgrounds, badges
  primary_100: '#FFD6DE'  # Light tint — hover states, highlights
  primary_200: '#FFB3C1'  # Medium tint — secondary elements
  primary_300: '#FF8FA3'  # Main accent — CTAs, active state
  primary_400: '#FF4D6D'  # Strong accent — icons, links
  primary_500: '#E63946'  # Primary brand color — headers, primary buttons
  primary_600: '#C1121F'  # Dark — pressed states
  primary_700: '#A4131C'  # Darker — text on light bg
```

### Neutral — Warm Grey
```yaml
colors:
  neutral_50: '#FAF9F8'   # Page background
  neutral_100: '#F5F3F0'  # Card backgrounds, surfaces
  neutral_200: '#EDE8E4'  # Dividers, borders
  neutral_300: '#D6CFC9'  # Disabled states, placeholders
  neutral_400: '#A89F97'  # Secondary text
  neutral_500: '#7C736A'  # Body text
  neutral_600: '#5C534C'  # Headings
  neutral_700: '#2D2A27'  # Primary text (dark)
  neutral_800: '#1A1817'  # Darkest text
```

### Semantic
```yaml
colors:
  success: '#2D9B4E'
  warning: '#F4A635'
  error: '#DC3545'
  info: '#4A90D9'
```

### Gradient (Key Visual)
```yaml
gradients:
  hero_start: '#FF4D6D'    # Rose
  hero_end: '#FF8FA3'      # Light rose
  sunset_start: '#FF6B6B'  # Coral
  sunset_end: '#FFA07A'    # Salmon
```

## 3. Typography

```yaml
typography:
  font_family: 'Inter, -apple-system, system-ui, sans-serif'

  display_large:
    size: 36
    weight: 700  # Bold
    height: 1.2
    letter_spacing: -0.02

  display_medium:
    size: 28
    weight: 600  # SemiBold
    height: 1.25

  heading_large:
    size: 22
    weight: 600
    height: 1.3

  heading_medium:
    size: 18
    weight: 600
    height: 1.35

  body_large:
    size: 16
    weight: 400
    height: 1.5

  body_medium:
    size: 14
    weight: 400
    height: 1.5

  body_small:
    size: 12
    weight: 400
    height: 1.4

  label:
    size: 13
    weight: 500
    height: 1.2
    letter_spacing: 0.01
```

## 4. Spacing

```yaml
spacing:
  xs: 4
  sm: 8
  md: 12
  lg: 16
  xl: 24
  xxl: 32
  xxxl: 48
  page_horizontal: 20    # Page edge padding
  card_padding: 16
  section_gap: 32        # Between sections
  element_gap: 12        # Between related elements
```

## 5. Border Radius

```yaml
radius:
  sm: 8     # Buttons, chips
  md: 12    # Cards, containers
  lg: 16    # Modals, bottom sheets
  xl: 24    # Images, avatars
  full: 999 # Circular
```

## 6. Shadows

```yaml
shadows:
  card:
    blur: 8
    offset_x: 0
    offset_y: 2
    color: 'rgba(0,0,0,0.08)'

  raised:
    blur: 16
    offset_x: 0
    offset_y: 4
    color: 'rgba(0,0,0,0.12)'

  modal:
    blur: 24
    offset_x: 0
    offset_y: 8
    color: 'rgba(0,0,0,0.2)'
```

## 7. Iconography

- **System**: Cupertino icons (iOS) / Material icons (Android)
- **Style**: Outlined, 24dp, stroke 1.5
- **Custom icons** (from SF Symbols / Material):
  - `facematch_camera` → camera.fill / photo_camera
  - `facematch_gallery` → photo.on.rectangle / photo_library
  - `facematch_swap` → arrow.triangle.2.circlepath / swap_horiz
  - `facematch_heart` → heart.fill / favorite
  - `facematch_share` → square.and.arrow.up / share
  - `facematch_history` → clock.arrow.circlepath / history

## 8. Screen Architecture

```
/                          → SplashScreen (brand intro)
/home                     → HomeScreen (two image pickers + CTA)
/results                  → ResultScreen (before/after slider + share)
/analysis                 → AnalysisScreen (makeup breakdown)
/history                  → HistoryScreen (past matches list)
/settings                 → SettingsScreen (subscription, preferences)
```

## 9. Component Library

### ImageSlot
```
Props: label, imagePath?, onTap, isLoading, size
Used for: both reference and selfie selection
States: empty (dashed border + icon), loading (shimmer), filled (preview)
```

### ComparisonSlider
```
Props: beforeImage, afterImage, initialPosition: 0.5
Gesture: horizontal drag reveals before/underneath
Controls: reset button, labels overlay
```

### MakeupBreakdown
```
Props: analysis (Map<String, String>)
Displays: categorized makeup features in expandable cards
Categories: 底妆, 眼妆, 眉妆, 腮红, 唇妆, 修容
```

### ActionButton
```
Props: label, icon?, onTap, variant (primary/secondary/ghost), isLoading
Size: large (full-width, 56px), medium (compact, 44px)
States: default, pressed, loading (spinner), disabled
```

## 10. Interaction Design

### Image Selection Flow
```
1. Tap image slot → bottom sheet: [Camera] [Gallery]
2. Camera opens natively / Gallery opens picker
3. Image loads → AspectFit crop preview
4. Both slots filled → "开始仿妆" CTA activates (pulse animation)
```

### Results View
```
Default: Show "after" image full-width
Gesture: Drag slider left → reveals "before" (original selfie)
Button: "保存" saves composite to gallery
Button: "分享" → system share sheet
Button: "重新选图" → back to home
```

### Loading States
```
Generate trigger → Full-screen overlay with gradient pulse + "正在分析妆容..."
Polling progress → Step indicators (分析中 → 迁移中 → 生成中 → 完成)
Error → Toast message + retry button
```

## 11. Motion

```yaml
motion:
  duration_fast: 200ms    # Button press, hover
  duration_normal: 350ms  # Screen transitions
  duration_slow: 500ms    # Image loading, reveal animations
  easing: 'cubic-bezier(0.2, 0.0, 0.2, 1.0)'  # Material standard

  transitions:
    page_forward: 'slide_left'   # Next screen
    page_back: 'slide_right'     # Previous screen
    modal: 'scale_up'            # Bottom sheet / dialog
    image_load: 'fade_in'        # Placeholder → loaded image
```

## 12. API Contract

```yaml
endpoints:
  analyze_makeup:
    method: POST
    path: /api/v1/analyze
    input: { reference_image: file }
    output: { makeup_analysis: { base: str, eyes: str, brows: str, blush: str, lips: str, contour: str } }

  transfer_makeup:
    method: POST
    path: /api/v1/transfer
    input: { reference_image: file, target_image: file }
    output: { result_url: str, analysis: { ... } }

  get_history:
    method: GET
    path: /api/v1/history
    output: { items: [{ id, created_at, result_thumbnail, reference_thumbnail }] }
```

## 13. Asset Requirements

```yaml
assets:
  app_icon: 'assets/icon/app_icon.png'          # 1024x1024
  splash_logo: 'assets/images/splash_logo.png'   # 400x400
  empty_state: 'assets/images/empty_state.png'   # 300x300
  tutorial_1_4: 'assets/images/tutorial_%d.png'  # Tutorial step images
  onboarding_1_3: 'assets/images/onboarding_%d.png'
```

## 14. Accessibility

```yaml
accessibility:
  min_tap_target: 44pt     # All interactive elements
  contrast_ratio: 4.5:1     # AA standard for text
  semantic_labels: true     # All images get alt text
  reduce_motion: true       # Respects iOS accessibility setting
  dynamic_type: true        # Respects font size setting
```
