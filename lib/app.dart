import 'package:flutter/material.dart';
import 'screens/root_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'movie_diary_app',
      debugShowCheckedModeBanner: false,
      home: RootScreen(),
    );
  }
}
