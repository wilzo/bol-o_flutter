import 'package:app_novo_mobile/Screens/DashboardScrenn.dart';
import 'package:app_novo_mobile/Services/user_provider.dart';
import 'package:app_novo_mobile/Services/PollProvider.dart';
import 'package:app_novo_mobile/Screens/LoginSceen.dart';
import 'package:app_novo_mobile/Screens/DashboardScrenn.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
 
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyBUOFeM1C0d2KVl5Q0X01BKvi3cpA2q1do",
        appId: "1:831544233967:web:1109101b4d6b5b45aff01a",
        messagingSenderId: "831544233967",
        projectId: "betif-5d8a9",
      ),
    );
    print("🔥 Firebase inicializado com sucesso!");
  } catch (e) {
    print("❌ Erro ao inicializar o Firebase: $e");
  }
  await Hive.initFlutter(); // Inicializa o Hive
  await Hive.openBox('myBox'); 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => PollProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Bet If',
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),
        initialRoute: "/login", // Definindo a rota inicial
        routes: {
          "/login": (context) => const LoginScreen(),
          
          "/dashboard": (context) => const DashboardScreen(),
        },
      ),
    );
  }
}
