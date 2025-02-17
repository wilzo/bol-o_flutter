import 'dart:io';
import 'package:app_novo_mobile/Screens/DashboardScrenn.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'UserProfileScreen.dart'; // Importe a tela de Perfil

class RankingScreen extends StatelessWidget {
  const RankingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ranking de Usuários"),
        backgroundColor: Colors.green.shade700,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchRankingData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Erro ao carregar ranking: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Nenhum usuário encontrado."));
          }

          final rankingData = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: rankingData.length,
            itemBuilder: (context, index) {
              final user = rankingData[index];
              return FutureBuilder<File?>(
                future: _loadUserProfileImage(user['userId']),
                builder: (context, imageSnapshot) {
                  final profileImage = imageSnapshot.data;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: profileImage != null
                            ? FileImage(profileImage)
                            : null,
                        child: profileImage == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(user['name']),
                      trailing: Text(
                        "${user['balance']} moedas",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text("Posição ${index + 1}"),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      // Barra de navegação inferior
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Índice do item ativo (Ranking)
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Bolões',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Ranking',
          ),
        ],
        onTap: (index) {
          // Navegação entre as telas
          if (index == 0) {
            // Navegar para a tela de Dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          } else if (index == 1) {
            // Navegar para a tela de Perfil
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const UserProfileScreen()),
            );
          }
          // Se o índice for 2 (Ranking), não faz nada, pois já está na tela de Ranking
        },
      ),
    );
  }

  // Método para buscar os dados dos usuários ordenados por saldo
  Future<List<Map<String, dynamic>>> _fetchRankingData() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .orderBy('balance', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'userId': doc.id,
        'name': data['name'] ?? 'Usuário Desconhecido',
        'balance': data['balance'] ?? 0.0,
      };
    }).toList();
  }

  // Método para carregar a imagem do perfil do usuário
  Future<File?> _loadUserProfileImage(String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/profile_image_$userId.jpg';
      final file = File(imagePath);
      if (await file.exists()) {
        return file;
      }
    } catch (e) {
      print("Erro ao carregar imagem do perfil: $e");
    }
    return null;
  }
}