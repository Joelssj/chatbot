import 'package:flutter/material.dart';
import 'Pages/home_screen.dart';  // Pantalla principal (Home)
import 'Pages/chat_screen.dart';  // Pantalla del chatbot (Chat)

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatbot App',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),        // Ruta para la pantalla de inicio
        '/chat': (context) => ChatScreen(),    // Ruta para la pantalla del chatbot
      },
    );
  }
}
