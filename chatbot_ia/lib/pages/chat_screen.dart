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
  final List<Map<String, String>> _messages = [];
  final List<Map<String, dynamic>> _batchedMessages = [];
  final TextEditingController _controller = TextEditingController();
  User? currentUser;
  String? currentConversationId;
  bool _isLoading = false;
  late http.Client httpClient;

  @override
  void initState() {
    super.initState();
    httpClient = http.Client();
    _checkUser();
  }

  @override
  void dispose() {
    _saveMessagesBatch();
    httpClient.close();
    super.dispose();
  }

  void _checkUser() {
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    });
  }

  void _startNewConversation() async {
    await _saveMessagesBatch();
    setState(() {
      _messages.clear();
      currentConversationId = null;
    });
  }

  Future<void> _loadConversation(String conversationId) async {
    _saveMessagesBatch(); // Sauvegarde les messages en cours avant de charger une nouvelle conversation

    setState(() {
      _isLoading = true; // Active l'indicateur de chargement
      _messages.clear(); // Efface les messages affichés précédemment
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .where('userId', isEqualTo: currentUser?.uid)
          .orderBy('timestamp',
              descending: false) // Trie les messages par ordre chronologique
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _messages.addAll(querySnapshot.docs.map((doc) {
            final data = doc.data(); // Récupération des données du document
            return {
              'role': data['role'].toString(),
              'content': data['content'].toString(),
              'time': data.containsKey('generation_time')
                  ? data['generation_time'].toString()
                  : 'Temps inconnu', // Vérification du champ
            };
          }).toList());
          currentConversationId = conversationId; // Met à jour l'ID actif
        });
      } else {
        print("Aucun message trouvé pour cette conversation.");
      }
    } catch (e) {
      print('Erreur lors du chargement des messages : $e');
    } finally {
      setState(() {
        _isLoading = false; // Désactive l'indicateur de chargement
      });
    }
  }

  void _queueMessage(String role, String content, {String? generationTime}) {
    if (currentConversationId == null) return;

    // Ajoute une micro-différence pour les timestamps
    final now = DateTime.now().millisecondsSinceEpoch;
    final adjustedTimestamp = now + _batchedMessages.length;

    _batchedMessages.add({
      'conversationId': currentConversationId,
      'userId': currentUser?.uid,
      'role': role,
      'content': content,
      'timestamp': adjustedTimestamp,
      if (generationTime != null) 'generation_time': generationTime,
    });

    // Sauvegarde automatique si le batch atteint 5 messages
    if (_batchedMessages.length >= 5) {
      _saveMessagesBatch();
    }
  }

  Future<void> _saveMessagesBatch() async {
    if (_batchedMessages.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();

    for (var message in _batchedMessages) {
      final docRef = FirebaseFirestore.instance.collection('messages').doc();
      batch.set(docRef, message);
    }

    try {
      await batch.commit();
      _batchedMessages.clear();
    } catch (e) {
      print('Erreur lors de la sauvegarde : $e');
    }
  }

  Future<Map<String, String>> _sendMessageToAPI(String message) async {
    // Vérifie si une réponse existe dans le cache
    final cachedResponse = await _getCachedResponse(message);
    if (cachedResponse != null) {
      print('Réponse chargée depuis le cache');
      return cachedResponse;
    }

    // Appel API si aucune réponse n'est trouvée dans le cache
    final url = Uri.parse('http://127.0.0.1:5000/chat');
    try {
      final response = await httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botResponse = data['response'] ?? 'Erreur : réponse vide';
        final generationTime = data['generation_time'] ?? 'Temps inconnu';

        // Sauvegarde la réponse dans le cache
        await _cacheResponse(message, botResponse, generationTime);

        return {'response': botResponse, 'time': generationTime};
      } else {
        return {
          'response': 'Erreur API : ${response.statusCode}',
          'time': 'Temps inconnu'
        };
      }
    } catch (e) {
      return {'response': 'Erreur de connexion : $e', 'time': 'Temps inconnu'};
    }
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
        SnackBar(
          content: Text('Conversation supprimée avec succès.'),
          duration:
              Duration(seconds: 1), // Affiche le SnackBar pendant 2 secondes
        ),
      );
    } catch (e) {
      print('Erreur lors de la suppression : $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cacheResponse(
      String message, String response, String generationTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        message,
        jsonEncode({
          'response': response,
          'time': generationTime,
        }));
  }

  Future<Map<String, String>?> _getCachedResponse(String message) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(message);

    if (cachedData != null) {
      final decodedData = jsonDecode(cachedData);
      return {
        'response': decodedData['response'],
        'time': decodedData['time'],
      };
    }
    return null;
  }

  Future<void> _sendMessage(String message) async {
    if (message.isEmpty) return;

    if (currentConversationId == null) {
      final newConversationRef =
          FirebaseFirestore.instance.collection('history').doc();
      await newConversationRef.set({
        'userId': currentUser?.uid,
        'excerpt': message.split(' ').take(3).join(' '),
        'timestamp': DateTime.now(),
      });
      setState(() {
        currentConversationId = newConversationRef.id;
      });
    }

    _controller.clear();

    // 1. Ajouter immédiatement le message utilisateur à l'interface
    setState(() {
      _messages.add({
        'role': 'user',
        'content': message,
        'time': DateTime.now().toIso8601String(), // Heure locale
      });
    });

    // 2. Ajouter le message à la liste tampon
    _queueMessage('user', message);

    try {
      setState(() {
        _isLoading = true; // Active le CircularProgressIndicator pour le bot
      });

      // 3. Appel API pour récupérer la réponse
      final apiResult = await _sendMessageToAPI(message);

      // 4. Ajouter la réponse du bot à l'interface
      setState(() {
        _messages.add({
          'role': 'bot',
          'content': apiResult['response']!,
          'time': apiResult['time']!,
        });
      });

      // 5. Ajouter la réponse du bot à la liste tampon
      _queueMessage('bot', apiResult['response']!,
          generationTime: apiResult['time']);
      await _saveMessagesBatch(); // Sauvegarde des messages dans Firestore
    } finally {
      setState(() {
        _isLoading = false; // Désactive le CircularProgressIndicator
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
              _startNewConversation();
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
                final messageTime = _messages[index]['time'] ?? 'Temps inconnu';

                return Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Affiche le temps uniquement pour les messages du chatbot
                    if (!isUser)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          messageTime, // Temps du message
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    // Bulle de message
                    Row(
                      mainAxisAlignment: isUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
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
                              _messages[index]['content'] ?? 'Message vide',
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'Poppins',
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
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
