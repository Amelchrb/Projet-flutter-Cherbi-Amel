import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, String>> _messages =
      []; // Messages de la conversation actuelle
  final List<String> _conversationHistory = []; // Historique des conversations
  final TextEditingController _controller = TextEditingController();
  bool isLoggedIn = false; // État de connexion de l'utilisateur

  // Fonction pour envoyer un message
  void _sendMessage(String message) {
    if (message.isEmpty) return;

    setState(() {
      _messages.add(
          {'role': 'user', 'content': message}); // Message de l'utilisateur
      _messages.add({
        'role': 'bot',
        'content': 'Réponse de l’IA...'
      }); // Réponse simulée de l'IA
    });
    _controller.clear();
  }

  // Fonction pour débuter une nouvelle conversation
  void _startNewConversation() {
    if (_messages.isNotEmpty) {
      // Sauvegarde le premier message de la conversation actuelle dans l'historique
      String firstMessage = _messages.firstWhere(
        (message) => message['role'] == 'user',
        orElse: () => {'content': ''},
      )['content']!;
      if (firstMessage.isNotEmpty) {
        // Ajoute un extrait des 3 premiers mots
        String excerpt = firstMessage.split(' ').take(3).join(' ');
        setState(() {
          _conversationHistory.add(excerpt);
        });
      }
    }
    // Réinitialise la conversation actuelle
    setState(() {
      _messages.clear();
    });
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
      backgroundColor: const Color(0xFFF5F5DC), // Beige clair
      appBar: AppBar(
        title: const Text(
          'Chat avec Cherbi',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 20),
        ),
        backgroundColor: Colors.pink,
        actions: [
          IconButton(
            icon: const Icon(Icons.add,
                color: Colors
                    .white), // Icône pour démarrer une nouvelle conversation
            onPressed: _startNewConversation,
          ),
          IconButton(
            icon: Icon(
              Icons.power_settings_new,
              color: isLoggedIn ? Colors.green : Colors.red,
            ),
            onPressed: _toggleLogin,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.pink),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat, size: 50, color: Colors.white),
                  const SizedBox(height: 10),
                  const Text(
                    'Historique des conversations',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            ..._conversationHistory.map((conversation) => ListTile(
                  title: Text(
                    conversation,
                    style:
                        const TextStyle(color: Colors.white), // Texte en blanc
                  ),
                  leading: const Icon(Icons.history, color: Colors.pink),
                )),
          ],
        ),
      ),
      body: Column(
        children: [
          // Liste des messages
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final isUser = _messages[index]['role'] == 'user';

                return Row(
                  mainAxisAlignment:
                      isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo pour les réponses de l'IA
                    if (!isUser)
                      Padding(
                        padding: const EdgeInsets.only(left: 10, right: 5),
                        child: CircleAvatar(
                          backgroundImage:
                              AssetImage('assets/images/Icon-192.png'),
                          radius: 20,
                        ),
                      ),
                    Flexible(
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: isUser
                              ? Colors.pink.shade300
                              : Colors.green.shade200,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(isUser ? 15 : 0),
                            topRight: Radius.circular(isUser ? 0 : 15),
                            bottomLeft: const Radius.circular(15),
                            bottomRight: const Radius.circular(15),
                          ),
                        ),
                        child: Text(
                          _messages[index]['content'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'Comic Sans MS',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Champ de saisie
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade300,
                      hintText: "Écrivez votre message...",
                      hintStyle: const TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.pink),
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
