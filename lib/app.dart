import 'package:flutter/material.dart';
import 'pages/splash_screen.dart';
import 'core/route_observer.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B0A14),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1A1830),
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          iconColor: Colors.white70,
          textColor: Colors.white,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(fontSize: 15, height: 1.4),
          bodySmall: TextStyle(fontSize: 13, height: 1.3),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: Color(0xFF8B5CF6),
          inactiveTrackColor: Colors.white24,
          thumbColor: Color(0xFF8B5CF6),
        ),
        dividerTheme: const DividerThemeData(color: Colors.white12, space: 32),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF1E1B2D),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      home: const SplashScreen(),
      navigatorObservers: [routeObserver],
    );
  }
}
