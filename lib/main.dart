import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/auth_gate.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enforce portrait or allow rotation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const SbpdclOcrApp());
}

class SbpdclOcrApp extends StatelessWidget {
  const SbpdclOcrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SBPDCL Meter OCR & Consumer Lookup',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}
