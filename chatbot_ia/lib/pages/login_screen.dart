import 'package:flutter/material.dart';
import 'register_screen.dart'; // Import de la page d'inscription
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth pour la connexion

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // Fonction pour envoyer un email de réinitialisation de mot de passe
  void _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez entrer un e-mail valide.")),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email de réinitialisation envoyé.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : ${e.toString()}")),
      );
    }
  }

  // Fonction pour se connecter avec e-mail et mot de passe
  void _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connexion réussie !')),
      );

      // Redirection vers la page de chat
      Navigator.pushReplacementNamed(context, '/chat');
    } catch (e) {
      _handleAuthError(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fonction pour se connecter anonymement
  void _loginAnonymously() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInAnonymously();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connexion anonyme réussie !')),
      );

      // Redirection vers la page de chat
      Navigator.pushReplacementNamed(context, '/chat');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleAuthError(Object e) {
    String errorMessage;

    switch (e.runtimeType) {
      case FirebaseAuthException:
        final authException = e as FirebaseAuthException;
        switch (authException.code) {
          case 'user-not-found':
            errorMessage = "Aucun utilisateur trouvé avec cet e-mail.";
            break;
          case 'wrong-password':
            errorMessage = "Mot de passe incorrect.";
            break;
          case 'invalid-email':
            errorMessage = "Adresse e-mail invalide.";
            break;
          default:
            errorMessage = "Erreur inconnue : ${authException.message}";
        }
        break;
      default:
        errorMessage = "Une erreur inattendue s'est produite : ${e.toString()}";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC), // Beige clair
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            CircleAvatar(
              backgroundImage: AssetImage('assets/images/Icon-192.png'),
              radius: 50,
            ),
            const SizedBox(height: 20),
            const Text(
              'Connexion',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            // Champ pour l'e-mail
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: "Entrez votre e-mail",
                filled: true,
                fillColor: Colors.grey.shade400,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            // Champ pour le mot de passe
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Entrez votre mot de passe",
                filled: true,
                fillColor: Colors.grey.shade400,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Bouton pour réinitialiser le mot de passe
            TextButton(
              onPressed: _resetPassword,
              child: const Text(
                "Mot de passe oublié ?",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            // Bouton de connexion
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Se connecter',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
            const SizedBox(height: 20),
            // Bouton de connexion anonyme
            ElevatedButton(
              onPressed: _isLoading ? null : _loginAnonymously,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade600,
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Connexion anonyme',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const Spacer(),
            // Bouton d'inscription en bas de la page
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                );
              },
              child: const Text(
                "Pas encore inscrit ? Créez un compte",
                style: TextStyle(
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
