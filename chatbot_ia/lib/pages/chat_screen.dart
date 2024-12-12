import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore pour la gestion des données
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth pour la gestion des utilisateurs
import 'package:http/http.dart' as http; // HTTP pour appeler l'API Flask
import 'dart:convert'; // Pour décoder les réponses JSON
import 'login_screen.dart'; // Import de la page de connexion

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  User? currentUser;
  String? currentConversationId; // Conversation active
  bool _isLoading = false; // Pour afficher un état de chargement

  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  // Vérifier si un utilisateur est connecté
  void _checkUser() {
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _redirectToLogin();
    }
  }

  // Rediriger vers la page de connexion
  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    });
  }

  // Charger les messages d'une conversation
  Future<void> _loadConversation(String conversationId) async {
    setState(() {
      _isLoading = true;
      _messages.clear(); // Effacer les messages actuels
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .orderBy('timestamp')
          .get();

      setState(() {
        for (var doc in querySnapshot.docs) {
          _messages.add({
            'role': doc['role'],
            'content': doc['content'],
          });
        }
        currentConversationId = conversationId;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement de la conversation : $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fonction pour appeler l'API Flask
  Future<String> _sendMessageToAPI(String message) async {
    final url = Uri.parse('http://10.21.35.155:5000/chat');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'Erreur : réponse vide.';
      } else {
        return 'Erreur API : ${response.statusCode}';
      }
    } catch (e) {
      return 'Erreur de connexion à l’API : $e';
    }
  }

  // Fonction pour envoyer un message
  void _sendMessage(String message) async {
    if (message.isEmpty) return;

    // Créer une nouvelle conversation dans l'historique si aucune conversation active
    if (currentConversationId == null) {
      final excerpt = message.split(' ').take(3).join(' ');
      final newConversationRef =
          FirebaseFirestore.instance.collection('history').doc();

      try {
        await newConversationRef.set({
          'userId': currentUser?.uid,
          'excerpt': excerpt,
          'timestamp': DateTime.now(),
        });

        setState(() {
          currentConversationId = newConversationRef.id;
        });
      } catch (e) {
        print('Erreur lors de la création de la conversation : $e');
        return;
      }
    }

    // Efface immédiatement le champ de saisie pour une meilleure expérience utilisateur
    _controller.clear();

    // Ajouter le message utilisateur dans l'interface
    setState(() {
      _messages.add({'role': 'user', 'content': message});
      _isLoading = true; // Activer l'état de chargement
    });

    // Appeler l'API Flask pour obtenir la réponse
    final botResponse = await _sendMessageToAPI(message);

    // Ajouter la réponse de l'IA dans l'interface
    setState(() {
      _messages.add({'role': 'bot', 'content': botResponse});
      _isLoading = false; // Désactiver l'état de chargement
    });

    // Sauvegarder les messages dans Firestore
    try {
      await _saveMessage('user', message);
      await _saveMessage('bot', botResponse);
    } catch (e) {
      print('Erreur lors de la sauvegarde du message : $e');
    }
  }

  // Sauvegarder les messages dans Firestore
  Future<void> _saveMessage(String role, String content) async {
    if (currentConversationId == null) return;

    await FirebaseFirestore.instance.collection('messages').add({
      'conversationId': currentConversationId,
      'userId': currentUser?.uid,
      'role': role,
      'content': content,
      'timestamp': DateTime.now(),
    });
  }

  // Réinitialiser les messages sans créer de nouvelle ligne dans l'historique
  void _startNewConversation() {
    setState(() {
      _messages.clear();
      currentConversationId = null;
    });
  }

  // Gestion de la déconnexion
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    _redirectToLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC), // Beige clair
      appBar: AppBar(
        title: const Text(
          'Chat avec Qwen',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 20),
        ),
        backgroundColor: Colors.pink,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _startNewConversation,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      drawer: Drawer(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('history')
              .where('userId', isEqualTo: currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final history = snapshot.data!.docs;

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: Colors.pink),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.chat, size: 50, color: Colors.white),
                      SizedBox(height: 10),
                      Text(
                        'Historique des conversations',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                ...history.map((doc) {
                  final isActive = doc.id == currentConversationId;

                  return ListTile(
                    tileColor: isActive
                        ? Colors.pink.shade100 // Couleur pour la ligne active
                        : null,
                    title: Text(
                      doc['excerpt'],
                      style: TextStyle(
                        color: isActive ? Colors.pink : Colors.black,
                      ),
                    ),
                    leading: const Icon(Icons.history, color: Colors.pink),
                    onTap: () => _loadConversation(doc.id),
                  );
                }).toList(),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
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
          if (_isLoading) const CircularProgressIndicator(),
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
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade400,
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
