import 'package:flutter/material.dart';
import 'pages/chat_screen.dart'; // Importe la page de chat

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Désactive le badge de débogage
      title: 'Cherbi Chatbot', // Titre de l'application
      theme: ThemeData(
        primaryColor: Colors.pink, // Couleur principale
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.green, // Couleur d'accentuation
        ),
        brightness: Brightness.light, // Mode clair
      ),
      darkTheme: ThemeData(
        primaryColor: Colors.pink,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.green,
        ),
        brightness: Brightness.dark, // Mode sombrefvm
      ),
      themeMode: ThemeMode.system, // Change automatiquement selon le système
      home: ChatScreen(), // Définit ChatScreen comme l'écran principal
    );
  }
}
