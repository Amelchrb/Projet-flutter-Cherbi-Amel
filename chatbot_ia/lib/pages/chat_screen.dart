import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore pour la gestion des données
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth pour la gestion des utilisateurs
import 'package:http/http.dart' as http; // HTTP pour appeler l'API Flask
import 'dart:convert'; // Pour décoder les réponses JSON
import 'package:shared_preferences/shared_preferences.dart'; // Pour la mise en cache
import 'login_screen.dart'; // Import de la page de connexion

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, String>> _messages = []; // Liste des messages affichés
  final List<Map<String, dynamic>> _batchedMessages =
      []; // Liste tampon pour le Batch Writing
  final TextEditingController _controller = TextEditingController();
  User? currentUser;
  String? currentConversationId; // Conversation active
  bool _isLoading = false; // Pour afficher un état de chargement
  late http.Client httpClient; // Client HTTP pour Keep-Alive

  @override
  void initState() {
    super.initState();
    httpClient = http.Client(); // Initialisation du client HTTP
    _checkUser();
  }

  @override
  void dispose() {
    _saveMessagesBatch(); // Sauvegarde les messages en lot avant de quitter
    httpClient.close(); // Fermeture du client HTTP
    super.dispose();
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

  void _startNewConversation() async {
    // Sauvegarder les messages restants dans le batch
    await _saveMessagesBatch(); // Sauvegarde les messages en lot

    // Réinitialiser l'état
    setState(() {
      _messages.clear(); // Vide les messages affichés
      currentConversationId = null; // Réinitialise l'ID de la conversation
    });
  }

  // Charger les messages d'une conversation avec pagination
  Future<void> _loadConversation(String conversationId) async {
    _saveMessagesBatch(); // Sauvegarde les messages restants avant de charger une nouvelle conversation

    setState(() {
      _isLoading = true;
      _messages.clear();
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .where('userId', isEqualTo: currentUser?.uid)
          .orderBy('timestamp')
          .limit(50)
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

  // Ajouter un message à la liste tampon pour écriture en lot
  void _queueMessage(String role, String content) {
    if (currentConversationId == null) return;

    _batchedMessages.add({
      'conversationId': currentConversationId,
      'userId': currentUser?.uid,
      'role': role,
      'content': content,
      'timestamp': DateTime.now(),
    });

    // Log : Afficher la taille du batch après ajout
    print(
        'Message ajouté au batch. Taille actuelle du batch : ${_batchedMessages.length}');

    // Sauvegarde automatique si le batch atteint 5 messages
    if (_batchedMessages.length >= 6) {
      _saveMessagesBatch();
    }
  }

  // Sauvegarder les messages en lot dans Firestore
  Future<void> _saveMessagesBatch() async {
    if (_batchedMessages.isEmpty)
      return; // Si aucun message à sauvegarder, ne rien faire

    final batch = FirebaseFirestore.instance.batch();

    for (var message in _batchedMessages) {
      final docRef = FirebaseFirestore.instance.collection('messages').doc();
      batch.set(docRef, message);
    }

    try {
      await batch
          .commit(); // Sauvegarder tous les messages en une seule opération
      _batchedMessages.clear(); // Vider la liste tampon après la sauvegarde
    } catch (e) {
      print('Erreur lors de l\'écriture en lot : $e');
    }
  }

  // Appeler l'API Flask pour obtenir une réponse
  Future<String> _sendMessageToAPI(String message) async {
    final url = Uri.parse('http://10.21.35.155:5000/chat');
    try {
      // Vérifier le cache avant d'envoyer la requête
      final cachedResponse = await _getCachedResponse(message);
      if (cachedResponse != null) {
        return cachedResponse; // Retourner la réponse en cache
      }

      final response = await httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botResponse = data['response'] ?? 'Erreur : réponse vide.';
        await _cacheResponse(
            message, botResponse); // Mise en cache de la réponse
        return botResponse;
      } else {
        return 'Erreur API : ${response.statusCode}';
      }
    } catch (e) {
      return 'Erreur de connexion à l’API : $e';
    }
  }

  // Sauvegarder un message en cache
  Future<void> _cacheResponse(String message, String response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(message, response);
  }

  // Récupérer une réponse du cache
  Future<String?> _getCachedResponse(String message) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(message);
  }

  // Fonction pour envoyer un message
  Future<void> _sendMessage(String message) async {
    if (message.isEmpty) return;

    // Créer une nouvelle conversation si aucune n'est active
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

    // Efface immédiatement le champ de saisie
    _controller.clear();

    // Ajouter le message utilisateur dans l'interface
    setState(() {
      _messages.add({'role': 'user', 'content': message});
      _isLoading = true; // Activer l'état de chargement
    });

    // Ajouter le message utilisateur dans la liste tampon
    _queueMessage('user', message);

    // Appeler l'API Flask pour obtenir une réponse
    final botResponse = await _sendMessageToAPI(message);

    // Ajouter la réponse du bot dans l'interface
    setState(() {
      _messages.add({'role': 'bot', 'content': botResponse});
      _isLoading = false; // Désactiver l'état de chargement
    });

    // Ajouter la réponse du bot dans la liste tampon
    _queueMessage('bot', botResponse);
  }

  // Supprimer une conversation
  Future<void> _deleteConversation(String conversationId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Supprimer tous les messages liés à cette conversation
      final messagesRef = FirebaseFirestore.instance.collection('messages');
      final messagesSnapshot = await messagesRef
          .where('conversationId', isEqualTo: conversationId)
          .get();

      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Supprimer la conversation elle-même
      await FirebaseFirestore.instance
          .collection('history')
          .doc(conversationId)
          .delete();

      // Réinitialiser l'état si la conversation active est supprimée
      if (currentConversationId == conversationId) {
        setState(() {
          currentConversationId = null;
          _messages.clear();
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversation supprimée avec succès.')),
      );
    } catch (e) {
      print('Erreur lors de la suppression : $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E3),
      appBar: AppBar(
        title: const Text(
          'Chat avec Qwen',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 20),
        ),
        backgroundColor: Colors.pink,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              _startNewConversation(); // Appel de la méthode
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              _redirectToLogin();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('history')
              .where('userId',
                  isEqualTo: currentUser?.uid) // Vérifie l'utilisateur actuel
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
                  decoration: const BoxDecoration(color: Colors.pink),
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
                    tileColor: isActive ? Colors.pink.shade100 : null,
                    title: Text(
                      doc['excerpt'],
                      style: TextStyle(
                        color: isActive ? Colors.pink : Colors.white,
                      ),
                    ),
                    leading: const Icon(Icons.history, color: Colors.pink),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteConversation(doc.id),
                    ),
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
                  children: [
                    if (!isUser)
                      const CircleAvatar(
                        backgroundImage:
                            AssetImage('assets/images/Icon-192.png'),
                        radius: 20,
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
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          _messages[index]['content'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'Poppins',
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
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade500,
                      hintText: "Écrivez votre message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
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
