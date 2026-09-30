import 'package:flutter/material.dart';
import 'tts_service.dart';

class SettingsScreen extends StatefulWidget {
  final TtsService tts;
  const SettingsScreen({super.key, required this.tts});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<dynamic> _voices = [];
  String? _selectedVoice;

  @override
  void initState() {
    super.initState();
    _loadVoices();
  }

  Future<void> _loadVoices() async {
    try {
      final voices = await widget.tts.flutterTts.getVoices;
      setState(() => _voices = voices);
      print("Loaded ${_voices.length} voices");
    } catch (e) {
      print("Could not load voices: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text("Select Voice", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              isExpanded: true,
              hint: const Text("Choose a voice (look for female names)"),
              value: _selectedVoice,
              items: _voices.map<DropdownMenuItem<String>>((voice) {
                final name = (voice['name'] ?? 'Unknown').toString();
                final locale = (voice['locale'] ?? '').toString();
                return DropdownMenuItem<String>(
                  value: name,
                  child: Text("$name ($locale)"),
                );
              }).toList(),
              // Inside onChanged of the DropdownButton
              onChanged: (value) async {
                if (value == null) return;

                
                setState(() => _selectedVoice = value);

                final voice = _voices.firstWhere(
                  (v) => (v['name'] ?? '') == value,
                  orElse: () => <String, dynamic>{},
                );

                if (voice.isNotEmpty) {
                  final name = voice['name'].toString();
                  final locale = (voice['locale'] ?? 'en-US').toString();

                  // Use the new method that stores both name + locale
                  await widget.tts.setVoice(name, locale);
                  print("Voice changed to: $name ($locale)");
                }
              },
            ),

            const SizedBox(height: 30),
            const Text("Volume", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Slider(
              value: widget.tts.volume,
              min: 0,
              max: 1,
              divisions: 20,
              label: (widget.tts.volume * 100).round().toString() + "%",
              onChanged: (v) async {
                await widget.tts.setVolume(v);
                setState(() {});
              },
            ),

            const Text("Speed", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Slider(
              value: widget.tts.rate,
              min: 0,
              max: 1,
              divisions: 20,
              onChanged: (v) async {
                await widget.tts.setRate(v);
                setState(() {});
              },
            ),

            const Text("Pitch (Higher = More Female)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Slider(
              value: widget.tts.pitch,
              min: 0.5,
              max: 2.0,
              divisions: 30,
              onChanged: (v) async {
                await widget.tts.setPitch(v);
                setState(() {});
              },
            ),

            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.volume_up),
              label: const Text("Test Voice"),
              onPressed: () => widget.tts.speak("Hello, this is a test of the selected voice and settings."),
            ),
          ],
        ),
      ),
    );
  }
}