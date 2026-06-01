import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode for the vertical video feed experience
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Transparent status bar over the dark background
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF09090B),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const ProviderScope(child: YouScoutApp()));
}

class YouScoutApp extends StatelessWidget {
  const YouScoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouScout',
      debugShowCheckedModeBanner: false,
      theme: darkTheme,
      // GoRouter will be added once app_router.dart is created
      home: const Scaffold(
        body: Center(
          child: Text(
            'YouScout',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Color(0xFF00D4FF),
            ),
          ),
        ),
      ),
    );
  }
}
