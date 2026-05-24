import 'package:flutter/material.dart';

void main() {
  runApp(const FoodieBeeApp());
}

class FoodieBeeApp extends StatelessWidget {
  const FoodieBeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Foodie Bee',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Foodie Bee'),
        ),
      ),
    );
  }
}
