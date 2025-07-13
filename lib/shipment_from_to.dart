import 'package:flutter/material.dart';
import 'voice_service.dart';
import 'whisper_service.dart';
import 'package_details_page.dart';

class ShipmentPage extends StatefulWidget {
  @override
  _ShipmentPageState createState() => _ShipmentPageState();
}

class _ShipmentPageState extends State<ShipmentPage> {
  final fromController = TextEditingController();
  final toController = TextEditingController();

  final focusNodes = [
    FocusNode(),
    FocusNode(),
  ];

  int currentIndex = 0;
  final voiceService = VoiceService();

  bool isListening = false;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    voiceService.init();
  }

  void _moveToNextField() {
    if (currentIndex < focusNodes.length - 1) {
      currentIndex++;
      FocusScope.of(context).requestFocus(focusNodes[currentIndex]);
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  void _mapTranscription(String text) {
    text = text.toLowerCase().trim();

    if (text.contains("next")) {
      _moveToNextField();
      return;
    }

    if (text.contains("from")) {
      fromController.text = text.replaceFirst("from", "").trim();
      currentIndex = 0;
    } else if (text.contains("to")) {
      toController.text = text.replaceFirst("to", "").trim();
      currentIndex = 1;
    } else {
      if (currentIndex == 0) {
        fromController.text = text;
      } else {
        toController.text = text;
      }
    }
  }

  Future<void> _toggleVoiceInput() async {
    if (isListening) {
      await voiceService.stopLiveRecognition();
      setState(() => isListening = false);
    } else {
      setState(() {
        isListening = true;
        isProcessing = false;
      });

      await _startRecognitionLoop();
    }
  }

  Future<void> _startRecognitionLoop() async {
    while (isListening) {
      // Start recognition
      await voiceService.startLiveRecognition((text, confidence) async {
        if (!isListening) return;

        // Only show loader if Whisper fallback is needed
        if (confidence >= 0.7 && text.trim().isNotEmpty) {
          _mapTranscription(text);
        } else {
          setState(() => isProcessing = true); // Start loader
          final path = await voiceService.recordForWhisper();
          final transcription = await WhisperService.transcribe(path);
          _mapTranscription(transcription);
          setState(() => isProcessing = false); // Stop loader
        }
      });

      // Wait before looping again
      await Future.delayed(Duration(milliseconds: 500));
    }
  }

  void _goToNextPage() {
    if (fromController.text.isEmpty || toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PackageDetailsPage(
          from: fromController.text,
          to: toController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputFields = [
      {'label': 'Shipment From', 'controller': fromController},
      {'label': 'Shipment To', 'controller': toController},
    ];

    return Scaffold(
      appBar: AppBar(title: Text("Hybrid Voice Shipment")),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ...List.generate(inputFields.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: inputFields[i]['controller'] as TextEditingController,
                      focusNode: focusNodes[i],
                      onTap: () => currentIndex = i,
                      decoration: InputDecoration(
                        labelText: inputFields[i]['label'] as String,
                      ),
                    ),
                  );
                }),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _goToNextPage,
                  child: Text("Next"),
                ),
              ],
            ),
          ),
          if (isProcessing)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleVoiceInput,
        backgroundColor: isListening ? Colors.red : Colors.blue,
        child: Icon(isListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }
}
