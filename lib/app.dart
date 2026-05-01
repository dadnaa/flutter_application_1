import 'package:flutter/material.dart';
import 'pages/splash_screen.dart';
import 'core/route_observer.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      navigatorObservers: [routeObserver],
    );
  }
}