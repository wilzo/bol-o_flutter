import 'dart:io';
import 'package:app_novo_mobile/Screens/DashboardScrenn.dart';
import 'package:app_novo_mobile/Screens/RankingScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../Services/user_provider.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  late Box _userProfileBox; // Caixa do Hive
  bool _isHiveInitialized = false; // Flag para verificar se o Hive foi inicializado

  @override
  void initState() {
    super.initState();
    _initializeHive().then((_) {
      // Após inicializar o Hive, carrega a imagem e os dados do usuário
      final userProvider = context.read<UserProvider>();
      userProvider.fetchUserData(); // Carrega os dados do usuário ao iniciar a tela

      // Carrega a imagem salva ao iniciar a tela
      _loadImage().then((image) {
        if (image != null) {
          setState(() {
            _profileImage = image;
          });
        }
      });
    });
  }

  // Método para inicializar o Hive e abrir a caixa
  Future<void> _initializeHive() async {
    await Hive.initFlutter(); // Inicializa o Hive
    _userProfileBox = await Hive.openBox('userProfileBox'); // Abre a caixa
    setState(() {
      _isHiveInitialized = true; // Marca o Hive como inicializado
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });

      // Salva a imagem localmente e armazena o caminho no Hive
      final imagePath = await _saveImageLocally(_profileImage!);
      if (imagePath != null) {
        _userProfileBox.put('profileImagePath', imagePath); // Salva o caminho no Hive
        final userProvider = context.read<UserProvider>();
        userProvider.updateProfileImage(imagePath); // Atualiza o caminho no provider
      }
    }
  }

  // Método para salvar a imagem localmente
  Future<String?> _saveImageLocally(File image) async {
    try {
      final directory = await getApplicationDocumentsDirectory(); // Obtém o diretório de documentos
      final imagePath = '${directory.path}/profile_image.jpg'; // Define o caminho do arquivo
      await image.copy(imagePath); // Copia a imagem para o diretório
      return imagePath;
    } catch (e) {
      print("Erro ao salvar a imagem localmente: $e");
      return null;
    }
  }

  // Método para carregar a imagem salva
  Future<File?> _loadImage() async {
    if (!_isHiveInitialized) return null; // Retorna null se o Hive não estiver inicializado

    final imagePath = _userProfileBox.get('profileImagePath'); // Obtém o caminho da imagem
    if (imagePath != null) {
      final file = File(imagePath);
      if (await file.exists()) { // Verifica se o arquivo existe
        return file;
      } else {
        print("Arquivo não encontrado: $imagePath");
        _userProfileBox.delete('profileImagePath'); // Remove o caminho inválido do Hive
      }
    }
    return null;
  }

  void _editUserInfo(BuildContext context) {
    final userProvider = context.read<UserProvider>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Perfil'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Campo para editar o nome
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const SizedBox(height: 20),

                // Botão para alterar a foto
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Fecha o diálogo atual
                    _showImagePicker(context); // Abre o seletor de imagem
                  },
                  child: const Text("Alterar Foto"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Fecha o diálogo
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                userProvider.updateUserName(_nameController.text); // Atualiza o nome
                Navigator.pop(context); // Fecha o diálogo
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tirar Foto'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Escolher da Galeria'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = FirebaseAuth.instance.currentUser; // Obtém o usuário logado

    if (userProvider.isLoading || !_isHiveInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil do Usuário"),
        backgroundColor: Colors.green.shade700,
      ),
      body: Column(
        children: [
          // Foto do usuário no centro da tela
          Expanded(
            child: Center(
              child: CircleAvatar(
                radius: 80,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!) // Usa a imagem local
                    : (userProvider.profileImageUrl.isNotEmpty
                        ? NetworkImage(userProvider.profileImageUrl)
                        : null),
                child: _profileImage == null && userProvider.profileImageUrl.isEmpty
                    ? const Icon(Icons.person, size: 80)
                    : null,
              ),
            ),
          ),

          // Lista de informações
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                ListTile(
                  title: const Text("Nome"),
                  subtitle: Text(
                    userProvider.name.isEmpty ? 'Nome do Usuário' : userProvider.name,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                ListTile(
                  title: const Text("E-mail"),
                  subtitle: Text(
                    user?.email ?? 'E-mail não disponível',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                ListTile(
                  title: const Text("Saldo"),
                  subtitle: Text(
                    "Saldo: ${userProvider.balance.toStringAsFixed(2)} moedas",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),

          // Botão para editar perfil
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: () => _editUserInfo(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade400,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text("Editar Perfil"),
            ),
          ),
        ],
      ),

      // Barra de navegação inferior
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Índice do item ativo (Perfil)
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
}