import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart';
import 'package:translator/translator.dart';
import 'tts_service.dart';
import 'settings_screen.dart';
import 'dart:io';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TtsService _tts = TtsService();
  final GoogleTranslator _translator = GoogleTranslator();

  String? _fileName;
  String _content = "Select a file or paste text to begin...";
  String _originalContent = "";          // keeps the original so you can go back
  String _startFromPhrase = "";
  bool _isSpeaking = false;
  bool _isLoading = false;

  // Language selection
  String _fromLang = 'auto';              // auto-detect by default
  String _toLang = 'en';                 // default target = English

  // Common languages (you can add more)
  final Map<String, String> _languages = {
    'auto': 'Auto Detect',
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'zh-cn': 'Chinese (Simplified)',
    'zh-tw': 'Chinese (Traditional)',
    'ja': 'Japanese',
    'ko': 'Korean',
    'ar': 'Arabic',
    'hi': 'Hindi',
    'tr': 'Turkish',
    'nl': 'Dutch',
    'pl': 'Polish',
    'sv': 'Swedish',
    'uk': 'Ukrainian',
    'vi': 'Vietnamese',
    'th': 'Thai',
    'id': 'Indonesian',
  };

  // ─────────────────────────────────────────
  // FILE PICKER
  // ─────────────────────────────────────────
  Future<void> _pickFile() async {
    setState(() => _isLoading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md', 'txt', 'html', 'htm'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        String text = "Could not read content.";

        if (file.bytes != null && file.bytes!.isNotEmpty) {
          text = utf8.decode(file.bytes!);
        } else if (file.path != null) {
          text = await File(file.path!).readAsString(encoding: utf8);
        }

        setState(() {
          _fileName = file.name;
          _content = text;
          _originalContent = text;
          _startFromPhrase = "";
        });
      }
    } catch (e) {
      setState(() => _content = "Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────
  // COPY / PASTE
  // ─────────────────────────────────────────
  Future<void> _copyContent() async {
    await Clipboard.setData(ClipboardData(text: _content));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Content copied to clipboard")),
      );
    }
  }

  Future<void> _pasteContent() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _content = data.text!;
        _originalContent = data.text!;
        _fileName = "Pasted text";
        _startFromPhrase = "";
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Clipboard is empty")),
        );
      }
    }
  }

  // ─────────────────────────────────────────
  // TRANSLATE (and show the result on screen)
  // ─────────────────────────────────────────
  Future<void> _translateContent() async {
  if (_content.trim().isEmpty ||
      _content == "Select a file or paste text to begin...") {
    return;
  }

  setState(() => _isLoading = true);

  try {
    final translation = await _translator.translate(
      _content,
      from: _fromLang,   // ← always a String ('auto' or language code)
      to: _toLang,
    );

    setState(() {
      if (_originalContent.isEmpty) _originalContent = _content;
      _content = translation.text; // now visible on screen
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Translated: ${translation.sourceLanguage.name} → ${_languages[_toLang] ?? _toLang}",
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Translation failed: $e")),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
  void _restoreOriginal() {
    if (_originalContent.isNotEmpty) {
      setState(() {
        _content = _originalContent;
      });
    }
  }

  // ─────────────────────────────────────────
  // SPEAK
  // ─────────────────────────────────────────
  Future<void> _speakSelection() async {
    if (_content.trim().isEmpty) return;

    setState(() => _isSpeaking = true);

    try {
      String textToSpeak = _content;

      // Apply "start from" phrase
      if (_startFromPhrase.trim().isNotEmpty) {
        final lowerContent = textToSpeak.toLowerCase();
        final lowerPhrase = _startFromPhrase.toLowerCase().trim();
        final index = lowerContent.indexOf(lowerPhrase);

        if (index != -1) {
          textToSpeak = textToSpeak.substring(index);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Phrase \"$_startFromPhrase\" not found")),
            );
          }
          setState(() => _isSpeaking = false);
          return;
        }
      }

      await _tts.speak(textToSpeak);

      _tts.flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
    } catch (e) {
      print("Speak error: $e");
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  void _stopSpeaking() async {
    await _tts.stop();
    if (mounted) setState(() => _isSpeaking = false);
  }

  // ─────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.book),
            SizedBox(width: 8),
            Text('MD Reader'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen(tts: _tts)),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Top action buttons
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Select File'),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: "Paste from clipboard",
                  icon: const Icon(Icons.paste),
                  onPressed: _pasteContent,
                ),
                IconButton(
                  tooltip: "Copy content",
                  icon: const Icon(Icons.copy),
                  onPressed: _copyContent,
                ),
                const Spacer(),
                if (_fileName != null)
                  Flexible(
                    child: Text(
                      'Loaded: $_fileName',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Language selection row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _fromLang,
                    decoration: const InputDecoration(
                      labelText: "From",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _languages.entries.map((e) {
                      return DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _fromLang = v);
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward),
                ),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _toLang,
                    decoration: const InputDecoration(
                      labelText: "To",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _languages.entries
                        .where((e) => e.key != 'auto') // can't translate TO auto
                        .map((e) {
                      return DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _toLang = v);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Translate + Restore buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _translateContent,
                    icon: const Icon(Icons.translate),
                    label: const Text("Translate"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _originalContent.isEmpty ? null : _restoreOriginal,
                  icon: const Icon(Icons.undo),
                  label: const Text("Original"),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Start-from field
            TextField(
              decoration: InputDecoration(
                labelText: "Start speaking from this phrase…",
                hintText: "Type a unique word or sentence",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.play_circle_outline),
                suffixIcon: _startFromPhrase.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _startFromPhrase = ""),
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _startFromPhrase = v),
            ),

            const SizedBox(height: 12),

            // ── Content area (now shows the translation)
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Markdown(
                        data: _content,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(fontSize: 16, height: 1.6),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: _isSpeaking ? _stopSpeaking : _speakSelection,
        backgroundColor: _isSpeaking ? Colors.red : Colors.deepPurple,
        child: Icon(
          _isSpeaking ? Icons.stop : Icons.play_arrow,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }
}