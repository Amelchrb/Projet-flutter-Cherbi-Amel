import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Liste des messages (historique de la session)
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool isLoggedIn = false; // État de connexion de l'utilisateur

  // Fonction pour envoyer un message
  void _sendMessage(String message) {
    if (message.isEmpty) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'content': message
      }); // Ajoute le message utilisateur
      _messages.add({
        'role': 'bot',
        'content': 'Réponse de l’IA...'
      }); // Simulation de réponse IA
    });
    _controller.clear();
  }

  // Fonction pour changer l'état de connexion
  void _toggleLogin() {
    setState(() {
      isLoggedIn = !isLoggedIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barre d'application en haut
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png', // Le logo
              height: 40,
            ),
            SizedBox(width: 10),
            Text("Chat avec Cherbi"),
          ],
        ),
        backgroundColor: Colors.pink,
        actions: [
          IconButton(
            icon: Icon(
              Icons.power_settings_new, // Icône de démarrage
              color: isLoggedIn ? Colors.green : Colors.red,
            ),
            onPressed: _toggleLogin,
          ),
        ],
      ),
      // Historique des conversations dans un Drawer
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.pink),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png', // Le logo
                    height: 60,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Historique des conversations',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            ..._messages
                .map((message) => ListTile(
                      title: Text(
                        message['content'] ?? '',
                        style: TextStyle(color: Colors.black),
                      ),
                      leading: Icon(
                        message['role'] == 'user'
                            ? Icons.person
                            : Icons.smart_toy, // Icône utilisateur ou bot
                        color: message['role'] == 'user'
                            ? Colors.pink
                            : Colors.green,
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
      // Corps principal de la page
      body: Column(
        children: [
          // Liste des messages
          Expanded(
            child: ListView.builder(
              reverse: true, // Affiche les messages les plus récents en bas
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final isUser = _messages[index]['role'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          isUser ? Colors.pink.shade100 : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _messages[index]['content'] ?? '',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          // Champ de saisie
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Écrivez votre message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.pink),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
