import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class VoiceService {
  late stt.SpeechToText _speechToText;
  late FlutterSoundRecorder _recorder;

  bool isSpeechAvailable = false;

  Future<void> init() async {
    _speechToText = stt.SpeechToText();
    _recorder = FlutterSoundRecorder();

    isSpeechAvailable = await _speechToText.initialize();
    await _recorder.openRecorder();
  }

  Future<void> startLiveRecognition(Function(String text, double confidence) onResult) async {
    if (!isSpeechAvailable) return;

    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          final text = result.recognizedWords;
          final confidence = result.confidence;
          onResult(text, confidence);
        }
      },
      listenMode: stt.ListenMode.confirmation,
      partialResults: false,
      localeId: "en_US",
    );
  }

  Future<void> stopLiveRecognition() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
  }

  Future<String> recordForWhisper() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/whisper_audio.wav';

    await _recorder.startRecorder(
      toFile: path,
      codec: Codec.pcm16WAV,
      sampleRate: 16000,
      numChannels: 1,
    );

    await Future.delayed(Duration(seconds: 4)); // Whisper-style fixed length
    await _recorder.stopRecorder();

    return path;
  }
}
