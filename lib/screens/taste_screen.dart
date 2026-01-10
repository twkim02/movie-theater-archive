import 'package:flutter/material.dart';

class TasteScreen extends StatelessWidget {
  const TasteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('취향')),
      body: const Center(child: Text('취향 화면')),
    );
  }
}
