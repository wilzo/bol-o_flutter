import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user['profileImageUrl']),
                    child: user['profileImageUrl'].isEmpty
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
        'name': data['name'] ?? 'Usuário Desconhecido',
        'profileImageUrl': data['profileImageUrl'] ?? '',
        'balance': data['balance'] ?? 0.0,
      };
    }).toList();
  }
}