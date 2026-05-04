

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'services/music_service.dart';
import 'services/shake_detector_service.dart';
import 'pages/splash_screen.dart';
import 'utils/route_observer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

 
  MusicService.init();

  ShakeDetectorService.instance.start();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
  
    return WithForegroundTask(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.black,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.grey,
          ),
        ),
        home: const SplashScreen(),
        navigatorObservers: [routeObserver],
      ),
    );
  }
}
