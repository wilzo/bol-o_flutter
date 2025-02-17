import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../Services/PollProvider.dart';
import '../Services/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePollScreen extends StatefulWidget {
  final DocumentSnapshot? poll;

  const CreatePollScreen({Key? key, this.poll}) : super(key: key);

  @override
  _CreatePollScreenState createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  late TextEditingController _questionController;
  late List<TextEditingController> _optionsControllers;
  late List<TextEditingController> _oddsControllers;

  @override
  void initState() {
    super.initState();

    _questionController = TextEditingController(
      text: widget.poll?.get('question') ?? '',
    );

    _optionsControllers = widget.poll != null
        ? (widget.poll!.get('options') as List<dynamic>)
            .map((option) => TextEditingController(text: option.toString()))
            .toList()
        : [TextEditingController(), TextEditingController()];

    _oddsControllers = widget.poll != null
        ? (widget.poll!.get('odds') as List<dynamic>)
            .map((odd) => TextEditingController(text: odd.toString()))
            .toList()
        : [TextEditingController(), TextEditingController()];
  }

  void _addOption() {
    setState(() {
      _optionsControllers.add(TextEditingController());
      _oddsControllers.add(TextEditingController());
    });
  }

  Future<void> _createPoll() async {
    final question = _questionController.text.trim();
    final options = _optionsControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    final odds = _oddsControllers
        .map((controller) => double.tryParse(controller.text.trim()) ?? 1.0)
        .toList();

    if (question.isEmpty || options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos obrigatórios.")),
      );
      return;
    }

    final userProvider = context.read<UserProvider>();
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuário não autenticado.")),
      );
      return;
    }

    try {
      // Obter o nome do usuário criador
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final creatorName = userDoc['name'] ?? "Desconhecido"; // Substitua 'name' pelo campo correto

      Map<String, dynamic> pollData = {
        'question': question,
        'options': options,
        'votes': List<int>.filled(options.length, 0),
        'bets': List<double>.filled(options.length, 0.0),
        'odds': odds,
        'createdAt': DateTime.now().toIso8601String(),
        'creatorId': userId,
        'creatorName': creatorName, // Adicionado o campo creatorName
        'votedUsers': [],
      };

      await FirebaseFirestore.instance.collection('polls').add(pollData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bolão criado com sucesso!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao criar bolão: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.poll == null ? "Criar Novo Bolão" : "Editar Bolão"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Saldo Atual: ${userProvider.balance} moedas",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: _questionController,
                decoration: InputDecoration(
                  labelText: "Pergunta do Bolão",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Alternativas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ..._optionsControllers.map((controller) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              hintText: "Alternativa",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: _oddsControllers[_optionsControllers.indexOf(controller)],
                            decoration: InputDecoration(
                              hintText: "ODDS",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _addOption,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Adicionar Alternativa"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _createPoll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(widget.poll == null ? "Criar Bolão" : "Salvar Alterações"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}