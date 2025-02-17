import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'CreatePollScreen.dart';
import 'UserProfileScreen.dart';
import 'DefineWinnerScreen.dart';
import 'VotePollScreen.dart';
import '../Services/user_provider.dart';
import 'RankingScreen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _listenToUserBalance();
  }

  void _listenToUserBalance() {
    final userProvider = context.read<UserProvider>();
    FirebaseFirestore.instance
        .collection('users')
        .doc(userProvider.userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        userProvider.updateBalance(snapshot['balance'] ?? 0);
      }
    });
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const UserProfileScreen()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _logout() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar Logout"),
        content: const Text("Você realmente deseja sair?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sair"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacementNamed(context, '/login');
      } catch (e) {
        print("Erro ao deslogar: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    "Saldo do Usuário: ${userProvider.balance} IFCOINS",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('polls')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                              child: Text("Nenhum bolão criado ainda."));
                        }

                        final polls = snapshot.data!.docs;
                        final userId = userProvider.userId;

                        final myPolls = polls
                            .where((poll) => poll['creatorId'] == userId)
                            .toList();
                        final otherPolls = polls
                            .where((poll) => poll['creatorId'] != userId)
                            .toList();

                        return ListView(
                          children: [
                            if (myPolls.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  "Seus Bolões",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              ...myPolls
                                  .map((poll) => _buildPollCard(poll, userId))
                                  .toList(),
                            ],
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                "Bolões Gerais",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            ...otherPolls
                                .map((poll) => _buildPollCard(poll, userId))
                                .toList(),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          : const Center(child: Text("Tela de Ranking")),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePollScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      // Barra de navegação inferior
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Índice do item ativo (Perfil)
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
          if (index == 1) {
            // Navegar para a tela de Dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const UserProfileScreen()),
            );
          } else if (index == 2) {
            // Navegar para a tela de Ranking
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const RankingScreen()),
            );
          }
        },
      ),
    );
  }

  Widget _buildPollCard(QueryDocumentSnapshot poll, String userId) {
  final options = List<String>.from(poll['options']);
  final votes = List<int>.from(poll['votes']);
  final votedUsers = List<dynamic>.from(poll['votedUsers'] ?? []);

  // Verifica se o usuário já apostou neste bolão
  final userBet = votedUsers.isNotEmpty
      ? votedUsers.firstWhere((vote) => vote['userId'] == userId,
          orElse: () => -1)
      : -1;
  final userBetAmount =
      userBet != -1 ? (userBet['valorApostado'] ?? 0.0) : 0.0;
  final potentialReturn =
      userBet != -1 ? (userBet['oddsAposta'] ?? 0.0) * userBetAmount : 0.0;

  final displayReturn = potentialReturn.isNaN ? 0.0 : potentialReturn;

  final isCreator = poll['creatorId'] == userId;

  return Card(
    elevation: 4,
    margin: const EdgeInsets.symmetric(vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            poll['question'],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text("Criado por: ${poll['creatorName'] ?? "Desconhecido"}"),
          const SizedBox(height: 8),
          ...options.map((option) {
            final index = options.indexOf(option);
            final percentage = votes.isEmpty
                ? 0
                : (votes[index] / votes.reduce((a, b) => a + b)) * 100;
            return Text("$option: ${percentage.toStringAsFixed(1)}%");
          }).toList(),
          if (userBet != -1) ...[
            const SizedBox(height: 8),
            Text("Você apostou: $userBetAmount IFCOINS"),
            Text(
                "Retorno potencial: ${displayReturn.toStringAsFixed(2)} IFCOINS"),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!isCreator && userBet == -1) ...[
                ElevatedButton(
                  onPressed: () async {
                    bool? updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VotePollScreen(poll: poll),
                      ),
                    );

                    if (updated == true) {
                      setState(() {});
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Votar no Bolão"),
                ),
              ],
              if (isCreator) ...[
                ElevatedButton(
                  onPressed: () => _defineWinner(context, poll),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Definir Vencedor"),
                ),
              ],
            ],
          ),
        ],
      ),
    ),
  );
}
  Future<void> _defineWinner(
      BuildContext context, QueryDocumentSnapshot poll) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final creatorId = poll['creatorId'];

    if (currentUserId != creatorId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Somente o criador do bolão pode definir o vencedor."),
        ),
      );
      return;
    }

    final winnerIndex = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DefineWinnerScreen(poll: poll),
      ),
    );

    if (winnerIndex != null) {
      await FirebaseFirestore.instance
          .collection('polls')
          .doc(poll.id)
          .delete();
    }
  }
}
