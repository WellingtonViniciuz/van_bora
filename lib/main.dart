import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/van_bora_app.dart';
import 'motorista/services/motorista_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDummyKeyForLocalTesting123456',
        appId: '1:1234567890:web:abcdef1234567890',
        messagingSenderId: '1234567890',
        projectId: 'vanbora-local-test',
      ),
    );
  } catch (e) {
    debugPrint('Aviso Firebase: $e');
  }

  final services = await MotoristaServices.create();
  runApp(VanBoraApp(services: services));
}
