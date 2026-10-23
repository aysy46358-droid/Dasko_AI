import 'package:flutter/material.dart';

import 'chat_screen.dart';

void main() {
  runApp(const DaskoApp());
}

class DaskoApp extends StatelessWidget {
  const DaskoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dasko AI',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8AB4F8),
          surface: Colors.black,
        ),
      ),
      home: const ChatScreen(),
    );
  }
}
