# Onboarding animations (Lottie)

The onboarding screen (`lib/screens/onboarding_screen.dart`) renders a Lottie
animation as the centerpiece of each page, and **automatically falls back** to a
hand-built Flutter animation when the matching `.json` file is missing. So the
app already looks good with zero extra files — dropping real Lottie assets in
here just upgrades the visuals.

## Expected files

Place these JSON files in this folder (exact names matter — they are referenced
in `onboarding_screen.dart`):

| File                | Page              | Suggested animation                |
| ------------------- | ----------------- | ---------------------------------- |
| `coffee_pour.json`  | Welcome           | Coffee being poured into a mug     |
| `scan.json`         | Scan & order      | QR code / phone scanning           |
| `track.json`        | Track every sip   | Order progress / radar / delivery  |
| `follow.json`       | Follow & save     | Heart / bell / loyalty             |

## Where to get them

### Option A — LottieFiles (free library, recommended)

1. Go to <https://lottiefiles.com> and create a free account.
2. Search for e.g. **"coffee pour"**, **"qr scan"**, **"order tracking"**,
   **"like heart"**. Filter by *Free* license.
3. Open an animation you like and click **Download → Lottie JSON**.
4. Rename the downloaded file to the name from the table above and drop it in
   this folder.

Good starting searches:
- Coffee pour: <https://lottiefiles.com/search?q=coffee%20pour>
- QR scan: <https://lottiefiles.com/search?q=qr%20scan>
- Order tracking: <https://lottiefiles.com/search?q=order%20tracking>

### Option B — Generate one with AI

- **LottieFiles AI** (<https://lottiefiles.com/ai>) — describe the animation in
  text ("hot coffee being poured into a white mug, steam rising") and export the
  JSON.
- Design in **Figma** + the **LottieFiles Figma plugin**, or animate in **Adobe
  After Effects** and export with the **Bodymovin** plugin.

## Wiring (already done)

The screen already loads them — no code change needed once the files are here:

```dart
Lottie.asset(
  'assets/animations/coffee_pour.json',
  fit: BoxFit.contain,
  errorBuilder: (context, error, stack) => fallbackArt, // native fallback
)
```

The folder is registered in `pubspec.yaml` under `flutter > assets`, so any file
added here is bundled automatically. After adding files, run `flutter pub get`
and do a full restart (not just hot reload) so the new assets are picked up.

> Tip: prefer **network-free** local JSON for offline-first behaviour. If you
> ever want a remote animation instead, swap `Lottie.asset(...)` for
> `Lottie.network('https://...json', errorBuilder: ...)`.
