import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../Services/user_provider.dart';

class VotePollScreen extends StatefulWidget {
  final DocumentSnapshot poll;

  const VotePollScreen({Key? key, required this.poll}) : super(key: key);

  @override
  _VotePollScreenState createState() => _VotePollScreenState();
}

class _VotePollScreenState extends State<VotePollScreen> {
  int? _selectedOptionIndex;
  double? _betAmount;
  bool _isVoting = false;
  int userBalance = 0;
  bool _hasVoted = false;

  @override
  void initState() {
    super.initState();
    _initializeUserBalance();
  }

  Future<void> _initializeUserBalance() async {
    try {
      final userProvider = context.read<UserProvider>();
      final userId = userProvider.userId;

      if (userId == null) {
        print("Erro: Usuário não autenticado.");
        return;
      }

      final pollDoc = await FirebaseFirestore.instance
          .collection('polls')
          .doc(widget.poll.id)
          .get();
      if (pollDoc.exists) {
        final votedUsers = (pollDoc.data()?.containsKey('votedUsers') ?? false)
            ? List<dynamic>.from(pollDoc['votedUsers'])
            : [];

        if (votedUsers.contains(userId)) {
          setState(() {
            _hasVoted = true;
          });
        }
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists && userDoc.data()!.containsKey('balance')) {
        setState(() {
          userBalance = (userDoc['balance'] as num).toInt();
        });
      }
    } catch (e) {
      print("Erro ao carregar dados do usuário: $e");
    }
  }

  Future<void> _submitVote({required String vote, required double value, required double oddsselecionada}) async {
  if (_selectedOptionIndex == null || _betAmount == null || _betAmount! <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Por favor, selecione uma opção e insira um valor válido para apostar."),
      ),
    );
    return;
  }

  if (_betAmount! > userBalance) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saldo insuficiente para realizar a aposta.")),
    );
    return;
  }

  if (_hasVoted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Você já votou nesta pesquisa.")),
    );
    return;
  }

  setState(() {
    _isVoting = true;
  });

  try {
    final userProvider = context.read<UserProvider>();
    final userId = userProvider.userId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro: Usuário não autenticado.")),
      );
      return;
    }

    // Atualizar votos e apostas
    final List<int> updatedVotes = List<int>.from(widget.poll['votes']);
    updatedVotes[_selectedOptionIndex!]++;

    final List<double> updatedBets = List<double>.from(widget.poll['bets']);
    updatedBets[_selectedOptionIndex!] += _betAmount!;

    // Usar as odds salvas no Firestore
    final List<double> odds = List<double>.from(widget.poll['odds']);

    // Atualizar o bolão no Firestore
    await FirebaseFirestore.instance.collection('polls').doc(widget.poll.id).update({
      'votes': updatedVotes,
      'bets': updatedBets,
      'votedUsers': FieldValue.arrayUnion([{'userId':userId, 'optionvoted':vote, 'valorApostado': value, 'oddsAposta': oddsselecionada} ]),
    });

    // Atualizar o saldo do usuário
    userBalance -= _betAmount!.toInt();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'balance': userBalance.toInt()});

    // Atualizar o saldo no UserProvider
    userProvider.updateBalance(userBalance.toDouble());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Voto e aposta registrados com sucesso!")),
    );

    Navigator.pop(context, true);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Ocorreu um erro ao registrar o voto.")),
    );
    print("Erro ao registrar voto: $e");
  } finally {
    setState(() {
      _isVoting = false;
    });
  }
}
  @override
  Widget build(BuildContext context) {
    final List<String> options = List<String>.from(widget.poll['options']);
    final List<double> odds = List<double>.from(widget.poll['odds']);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Votar no Bolão"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.poll['question'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              "Saldo disponível: $userBalance moedas",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      title: Text(options[index]),
                      subtitle: Text("Odd: ${odds[index].toStringAsFixed(2)}"),
                      leading: Radio<int>(
                        value: index,
                        groupValue: _selectedOptionIndex,
                        onChanged: (value) {
                          setState(() {
                            _selectedOptionIndex = value;
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            TextField(
              decoration: InputDecoration(
                labelText: "Valor da aposta",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _betAmount = double.tryParse(value) ?? 0.0;
                });
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isVoting || _hasVoted ? null :()=>{ 
                  _submitVote(vote: options[_selectedOptionIndex??-1], value: _betAmount??-1, oddsselecionada: odds[_selectedOptionIndex??-1]),
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isVoting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Confirmar Voto e Aposta"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}