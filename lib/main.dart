import 'package:flutter/material.dart';
import 'package:test_project/shipment_from_to.dart';
import 'package:test_project/voice_service.dart';

VoiceService voiceService = VoiceService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await voiceService.init(); // Ensure recorder is initialized
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shipment Voice Entry',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ShipmentPage(), // ✅ This loads your shipment UI
    );
  }
}
