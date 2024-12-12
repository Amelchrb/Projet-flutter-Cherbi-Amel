import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'firebase_options.dart'; // Import des options Firebase générées
import 'pages/chat_screen.dart'; // Page de chat
import 'pages/login_screen.dart'; // Page de connexion
import 'pages/register_screen.dart'; // Page d'inscription
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Initialise Flutter pour Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Configure Firebase
  );
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
          primarySwatch: Colors.pink,
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
        ),
      ),

      // Thème sombre
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.pink,
          brightness: Brightness.dark,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
        ),
      ),

      // Mode du thème (automatique)
      themeMode: ThemeMode.system,

      // Gestion des pages principales
      home:
          AuthStateHandler(), // Gère la redirection en fonction de l'état de connexion
      routes: {
        '/login': (context) => LoginScreen(),
        '/chat': (context) => ChatScreen(),
        '/register': (context) => RegisterScreen(),
      },
    );
  }
}

class AuthStateHandler extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Affiche un écran de chargement pendant l'attente
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // Si l'utilisateur est connecté, rediriger vers ChatScreen
          return ChatScreen();
        } else {
          // Sinon, rediriger vers LoginScreen
          return LoginScreen();
        }
      },
    );
  }
}
