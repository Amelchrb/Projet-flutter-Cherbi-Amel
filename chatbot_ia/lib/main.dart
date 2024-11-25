import 'package:flutter/material.dart';
import 'pages/chat_screen.dart'; // Importe la page de chat

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Désactive le badge de débogage
      title: 'Qwen Chatbot', // Titre de l'application

      // Thème clair
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.pink, // Couleur principale
          accentColor: Colors.green, // Couleur secondaire (deprecated)
          brightness: Brightness.light, // Mode clair
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black), // Texte par défaut en noir
        ),
      ),

      // Thème sombre
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.pink,
          accentColor: Colors.green,
          brightness: Brightness.dark, // Mode sombre
        ),
        textTheme: const TextTheme(
          bodyLarge:
              TextStyle(color: Colors.white), // Texte par défaut en blanc
        ),
      ),

      // Mode du thème (automatique)
      themeMode: ThemeMode.system, // Change automatiquement selon le système

      // Page principale
      home: ChatScreen(), // Définit ChatScreen comme écran principal
    );
  }
}
