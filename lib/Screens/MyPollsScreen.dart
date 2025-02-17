import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../Services/user_provider.dart';

class MyPollScreen extends StatelessWidget {
  const MyPollScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final userId = userProvider.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Meus Bolões"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('polls')
            .where('creatorId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Você ainda não criou nenhum bolão."));
          }

          final myPolls = snapshot.data!.docs;

          return ListView.builder(
            itemCount: myPolls.length,
            itemBuilder: (context, index) {
              final poll = myPolls[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(poll['question']),
                  subtitle: Text("Criado em: ${poll['createdAt'].toDate()}"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
