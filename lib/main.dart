import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Full-screen immersive display for mobile
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const DeepSeaEchoApp());
}

class DeepSeaEchoApp extends StatelessWidget {
  const DeepSeaEchoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Deep-Sea Echo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FFC8),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF0A1218),
        ),
      ),
      home: const GameScreen(),
    );
  }
}
