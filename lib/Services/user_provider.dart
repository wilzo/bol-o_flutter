import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider with ChangeNotifier {
  String _userId = "";
  double _balance = 0.0;
  String _name = '';
  String _bio = '';
  String _profileImageUrl = '';
  String _location = '';
  bool _isLoading = true;
  bool _isDataLoaded = false;

  // Getters
  String get userId => _userId;
  double get balance => _balance;
  bool get isLoading => _isLoading;
  String get name => _name;
  String get bio => _bio;
  String get profileImageUrl => _profileImageUrl;
  String get location => _location;

  // Método para definir o userId após o login
  void setUserId(String userId) {
    if (_userId != userId) {
      _userId = userId;
      _isDataLoaded = false; // Reseta o estado de carregamento
      notifyListeners();
      fetchUserData(); // Carrega os dados do usuário após definir o userId
    }
  }

  // Método para buscar os dados do usuário no Firestore
  Future<void> fetchUserData() async {
    if (_userId.isEmpty || _isDataLoaded) return; // Evita carregamento duplicado

    _isLoading = true;
    notifyListeners();

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_userId).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        _name = data['name'] ?? 'Usuário';
        _bio = data['bio'] ?? '';
        _profileImageUrl = data['profileImageUrl'] ?? '';
        _location = data['location'] ?? '';
        _balance = (data['balance'] as num).toDouble();
      } else {
        // Cria o usuário com valores iniciais
        await FirebaseFirestore.instance.collection('users').doc(_userId).set({
          'balance': 1000.0,
          'name': _name,
          'bio': _bio,
          'profileImageUrl': _profileImageUrl,
          'location': _location,
        });
        _balance = 1000.0;
      }
      _isDataLoaded = true; // Marca os dados como carregados
    } catch (e) {
      print("Erro ao buscar dados do usuário: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para atualizar o nome do usuário
  Future<void> updateUserName(String name) async {
    if (_userId.isEmpty || name.isEmpty) return;

    try {
      _name = name;
      await FirebaseFirestore.instance.collection('users').doc(_userId).update({'name': name});
      notifyListeners();
    } catch (e) {
      print("Erro ao atualizar o nome do usuário: $e");
    }
  }

  // Método para atualizar a bio do usuário
  Future<void> updateBio(String bio) async {
    if (_userId.isEmpty) return;

    try {
      _bio = bio;
      await FirebaseFirestore.instance.collection('users').doc(_userId).update({'bio': bio});
      notifyListeners();
    } catch (e) {
      print("Erro ao atualizar a bio do usuário: $e");
    }
  }

  // Método para atualizar a imagem de perfil do usuário
  Future<void> updateProfileImage(String imageUrl) async {
    if (_userId.isEmpty) return;

    try {
      _profileImageUrl = imageUrl;
      await FirebaseFirestore.instance.collection('users').doc(_userId).update({'profileImageUrl': imageUrl});
      notifyListeners();
    } catch (e) {
      print("Erro ao atualizar a imagem de perfil: $e");
    }
  }

  // Método para atualizar o saldo do usuário
  Future<void> updateBalance(double newBalance) async {
    if (_userId.isEmpty) return;

    try {
      _balance = newBalance;
      await FirebaseFirestore.instance.collection('users').doc(_userId).update({'balance': newBalance});
      notifyListeners();
    } catch (e) {
      print("Erro ao atualizar o saldo do usuário: $e");
    }
  }

  // Método para atualizar a localização do usuário
  Future<void> updateLocation(String location) async {
    if (_userId.isEmpty) return;

    try {
      _location = location;
      await FirebaseFirestore.instance.collection('users').doc(_userId).update({'location': location});
      notifyListeners();
    } catch (e) {
      print("Erro ao atualizar a localização: $e");
    }
  }
}