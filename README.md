### 1. Short GitHub Description (About section)

Paste this in the **Description** field on the repository page:

```
Flutter Markdown & text reader with Text-to-Speech, multi-language translation, start-from-phrase, and voice customization.
```

---

### 2. Suggested Topics (tags)

```
flutter  markdown  tts  text-to-speech  translation  reader  markdown-reader  flutter-tts
```

---

### 3. Full README.md (replace the current one)

```markdown
# MD Reader TTS

A clean Flutter application for reading Markdown, plain text, and HTML files with high-quality Text-to-Speech, multi-language translation, and smart reading controls.



## Features

- **File Support**  
  Open `.md`, `.txt`, `.html`, and `.htm` files.

- **Text-to-Speech**  
  - Native device voices with preference for female voices  
  - Adjustable speech rate, pitch, and volume  
  - Voice selection in Settings

- **Smart Reading Controls**  
  - Start speaking from any phrase in the document  
  - Large Play / Stop floating action button  
  - Selectable text

- **Translation**  
  - Translate from any language to any language  
  - Auto-detect source language  
  - Translated text is shown on screen (you both see and hear it)  
  - One-tap restore to original text

- **Clipboard Support**  
  - Paste text directly from clipboard  
  - Copy current content to clipboard

## Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- Android Studio or VS Code with Flutter extension
- A physical device is recommended (TTS works best on real hardware)

### Installation

```bash
git clone https://github.com/Tebohotet/md_reader_tts.git
cd md_reader_tts
flutter pub get
flutter run
```

### Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_tts: ^4.1.0
  file_picker: ^9.0.0
  shared_preferences: ^2.3.0
  flutter_markdown: ^0.7.4
  translator: ^1.0.0
```

## How to Use

1. **Open a file** → Tap **Select File**
2. **Or paste text** → Use the paste icon
3. **Translate (optional)**  
   - Choose source language (or leave on Auto Detect)  
   - Choose target language  
   - Press **Translate**  
   - Press **Original** to restore the previous text
4. **Start from a specific place**  
   Type a unique word or sentence in the “Start speaking from this phrase…” field
5. **Speak** → Press the large purple Play button (turns red to stop)
6. **Customize voice** → Open Settings (gear icon)

## Project Structure

```
lib/
├── main.dart
├── home_screen.dart      # Main reading & translation UI
├── settings_screen.dart  # Voice customization
└── tts_service.dart      # TTS engine + saved preferences
```

## Notes

- TTS quality and available voices depend on the device (Android / iOS).
- Google Translate has a practical limit of ~4500–5000 characters per request. For long documents, use the “Start from phrase” feature.
- On some Android devices you may need additional language packs or Google TTS for better female voices.

## License

MIT License

---

Made with ❤️ using Flutter
```

---

### Quick actions for you

1. Go to your repository → click the gear icon next to **About** → paste the short description and topics.
2. Replace the content of `README.md` with the full version above.
3. Commit & push.

Would you like me to also generate a shorter version of the README or add badges (Flutter version, License, etc.)?