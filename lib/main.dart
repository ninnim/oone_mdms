import 'package:flutter/material.dart';
import 'presentation/themes/app_theme.dart';
import 'presentation/screens/main_layout.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MDMS Clone',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const MainLayout(),
    );
  }
}
