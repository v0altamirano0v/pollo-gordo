import 'package:flutter/material.dart';
import 'screens.dart';

void main() => runApp(const PolloGordoApp());

class PolloGordoApp extends StatelessWidget {
  const PolloGordoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'El Pollo Gordo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD84315)),
      ),
      home: const LoginScreen(),
    );
  }
}
