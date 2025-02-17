import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PollData {
  String id;
  final String question;
  final List<String> options;
  final List<int> votes;
  final String creatorId;
  final String creatorName;
  final List<String> votedUsers;
  final List<double> odds;

  PollData({
    required this.id,
    required this.question,
    required this.options,
    required this.votes,
    required this.creatorId,
    required this.creatorName,
    required this.votedUsers,
    required this.odds,
  });

  factory PollData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PollData(
      id: doc.id,
      question: data['question'] as String,
      options: List<String>.from(data['options'] ?? []),
      votes: List<int>.from(data['votes'] ?? []),
      creatorId: data['creatorId'] as String,
      creatorName: data['creatorName'] ?? "Desconhecido",
      votedUsers: List<String>.from(data['votedUsers'] ?? []),
      odds: List<double>.from(data['odds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'votes': votes,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'votedUsers': votedUsers,
      'odds': odds,
    };
  }
}

class PollProvider with ChangeNotifier {
  List<PollData> _polls = [];
  bool _isLoading = false;

  List<PollData> get polls => _polls;
  bool get isLoading => _isLoading;

  Future<void> fetchPolls() async {
    _isLoading = true;
    notifyListeners();

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('polls')
          .orderBy('createdAt', descending: true)
          .get();

      _polls =
          querySnapshot.docs.map((doc) => PollData.fromFirestore(doc)).toList();
    } catch (e) {
      print("Erro ao buscar bolões: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> placeBet(
      String pollId, int optionIndex, String userId, double amount) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('polls').doc(pollId);
      final snapshot = await docRef.get();

      if (snapshot.exists) {
        List<int> votes = List<int>.from(snapshot['votes'] ?? []);
        List<String> votedUsers =
            List<String>.from(snapshot.data()?['votedUsers'] ?? []);
        List<double> bets = List<double>.from(
            snapshot.data()?['bets'] ?? List.filled(votes.length, 0.0));

        if (!votedUsers.contains(userId)) {
          votes[optionIndex]++;
          votedUsers.add(userId);
          bets[optionIndex] += amount;

          await docRef.update({
            'votes': votes,
            'votedUsers': votedUsers,
            'bets': bets,
          });

          await fetchPolls();
        } else {
          print("Usuário já votou nesse bolão.");
        }
      }
    } catch (e) {
      print("Erro ao atualizar votos: $e");
    }
  }

  Future<void> defineWinner(String pollId, int winningOptionIndex) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('polls').doc(pollId);
      final snapshot = await docRef.get();

      if (snapshot.exists) {
        List<int> votes = List<int>.from(snapshot['votes'] ?? []);
        List<double> bets = List<double>.from(
            snapshot.data()?['bets'] ?? List.filled(votes.length, 0.0));
        List<double> odds = List<double>.from(
            snapshot.data()?['odds'] ?? List.filled(votes.length, 1.0));
        List<String> votedUsers =
            List<String>.from(snapshot.data()?['votedUsers'] ?? []);

        double totalBetAmount = bets.reduce((a, b) => a + b);
        double winningBetAmount = bets[winningOptionIndex];

        for (var userId in votedUsers) {
          final userRef =
              FirebaseFirestore.instance.collection('users').doc(userId);
          final userSnapshot = await userRef.get();

          if (userSnapshot.exists) {
            double userBalance = userSnapshot['balance'] ?? 0.0;
            double userBet = bets[winningOptionIndex];

            if (userBet > 0) {
              double userReturn = (userBet / winningBetAmount) *
                  totalBetAmount *
                  odds[winningOptionIndex];
              await userRef.update({'balance': userBalance + userReturn});
            }
          }
        }

        await docRef.update({'winner': winningOptionIndex});
        await fetchPolls();
      }
    } catch (e) {
      print("Erro ao definir vencedor: $e");
    }
  }

  Future<void> updateVotes(
      String pollId, int optionIndex, String userId) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('polls').doc(pollId);
      final snapshot = await docRef.get();

      if (snapshot.exists) {
        List<int> votes = List<int>.from(snapshot['votes'] ?? []);
        List<String> votedUsers =
            List<String>.from(snapshot.data()?['votedUsers'] ?? []);

        if (!votedUsers.contains(userId)) {
          votes[optionIndex]++;
          votedUsers.add(userId);

          await docRef.update({
            'votes': votes,
            'votedUsers': votedUsers,
          });

          await fetchPolls();
        } else {
          print("Usuário já votou nesse bolão.");
        }
      }
    } catch (e) {
      print("Erro ao atualizar votos: $e");
    }
  }

  Future<void> updatePoll(
    String pollId,
    String question,
    List<String> options,
    List<int> votes,
    List<double> odds,
    List<String> votedUsers,
  ) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('polls').doc(pollId);

      await docRef.update({
        'question': question,
        'options': options,
        'votes': votes,
        'odds': odds,
        'votedUsers': votedUsers,
      });

      await fetchPolls();
    } catch (e) {
      print("Erro ao atualizar bolão: $e");
    }
  }

  Future<void> addPoll(
    String question,
    List<String> options,
    String creatorId,
    String creatorName,
    List<double> odds,
  ) async {
    try {
      final newPoll = PollData(
        id: '', // O Firestore irá gerar automaticamente o ID
        question: question,
        options: options,
        votes: List<int>.filled(options.length, 0),
        creatorId: creatorId,
        creatorName: creatorName,
        votedUsers: [],
        odds: odds,
      );

      final docRef = await FirebaseFirestore.instance
          .collection('polls')
          .add(newPoll.toMap());

      newPoll.id = docRef.id;

      _polls.insert(0, newPoll);
      notifyListeners();
    } catch (e) {
      print("Erro ao adicionar bolão: $e");
    }
  }
}