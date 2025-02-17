import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DefineWinnerScreen extends StatelessWidget {
  final DocumentSnapshot poll;

  const DefineWinnerScreen({Key? key, required this.poll}) : super(key: key);

  Future<void> _defineWinner(BuildContext context, String winnerIndex) async {
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

    try {
      final options = List<String>.from(poll['options']);
      final odds = List<double>.from(poll['odds']);

      // Referência para a subcoleção de apostas
      final votes = poll['votedUsers'];

      for (var betDoc in votes) {
        try {
          final String userId = betDoc['userId'];
          final String opcaoEscolhida = betDoc['optionvoted'];
          final double valorApostado = betDoc['valorApostado'];
          final double odd = betDoc['oddsAposta'];

          if (opcaoEscolhida == winnerIndex) {
            final double retorno = valorApostado * odd;

            final userDocRef =
                FirebaseFirestore.instance.collection('users').doc(userId);
            final userDoc = await userDocRef.get();

            if (userDoc.exists) {
              final double saldoAtual = (userDoc['balance'] ?? 0.0) as double;
              final double novoSaldo = saldoAtual + retorno;

              await userDocRef.update({'balance': novoSaldo});

              debugPrint(
                  "Saldo do usuário $userId atualizado: +$retorno (Total: $novoSaldo)");
            } else {
              debugPrint("Usuário $userId não encontrado!");
            }
          }
        } catch (e) {
          debugPrint("Erro ao processar a aposta ${betDoc}: $e");
        }
      }

      // Excluir bolão após processar
      await poll.reference.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Vencedor definido: '${winnerIndex}'. Bolão excluído."),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao definir vencedor: $e")),
      );
      debugPrint("Erro crítico: $e");
    }
  }

  Future<double> _getUserBalance() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          return (userDoc['balance'] ?? 0.0) as double;
        }
      } catch (e) {
        debugPrint("Erro ao carregar saldo do usuário: $e");
      }
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final options = List<String>.from(poll['options'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Definir Vencedor"),
        backgroundColor: Colors.red,
      ),
      body: FutureBuilder<double>(
        future: _getUserBalance(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar saldo'));
          }

          final userBalance = snapshot.data ?? 0.0;

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Saldo Atual: $userBalance moedas',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              for (var i = 0; i < options.length; i++)
                Card(
                  elevation: 2,
                  margin:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: Text(options[i]),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        try {
                          await _defineWinner(context, options[i]);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text("Erro ao definir vencedor: $e")),
                          );
                        } finally {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text("Selecionar"),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
