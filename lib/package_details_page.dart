import 'package:flutter/material.dart';
import 'voice_service.dart';
import 'whisper_service.dart';

class PackageDetailsPage extends StatefulWidget {
  final String from;
  final String to;

  const PackageDetailsPage({
    Key? key,
    required this.from,
    required this.to,
  }) : super(key: key);

  @override
  State<PackageDetailsPage> createState() => _PackageDetailsPageState();
}

class _PackageDetailsPageState extends State<PackageDetailsPage> {
  final weightController = TextEditingController();
  final packageTypeController = TextEditingController();

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

    if (text.contains("weight")) {
      weightController.text = text.replaceFirst("weight", "").trim();
      currentIndex = 0;
    } else if (text.contains("package type")) {
      packageTypeController.text = text.replaceFirst("package type", "").trim();
      currentIndex = 1;
    } else {
      // fallback to current field
      if (currentIndex == 0) {
        weightController.text = text;
      } else {
        packageTypeController.text = text;
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

      await voiceService.startLiveRecognition((text, confidence) async {
        setState(() => isProcessing = true);

        if (confidence >= 0.7) {
          _mapTranscription(text);
        } else {
          final path = await voiceService.recordForWhisper();
          final transcription = await WhisperService.transcribe(path);
          _mapTranscription(transcription);
        }

        setState(() {
          isProcessing = false;
          isListening = false;
        });
      });
    }
  }

  void _submitForm() {
    if (weightController.text.isEmpty || packageTypeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    // Submit logic here or show success
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Shipment Created"),
        content: Text(
            "From: ${widget.from}\nTo: ${widget.to}\nWeight: ${weightController.text}\nPackage Type: ${packageTypeController.text}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputFields = [
      {'label': 'Weight', 'controller': weightController},
      {'label': 'Package Type', 'controller': packageTypeController},
    ];

    return Scaffold(
      appBar: AppBar(title: Text("Package Details")),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("From: ${widget.from}", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("To: ${widget.to}", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
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
                  onPressed: _submitForm,
                  child: Text("Submit"),
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
