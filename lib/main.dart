import 'package:flutter/material.dart';
import 'package:quizcraft/features/auth/presentation/pages/loading_page.dart';
import 'package:firebase_core/firebase_core.dart';// 1. Import Firebase
import 'package:firebase_auth/firebase_auth.dart'; 
import 'firebase_options.dart'; // 2. Import ไฟล์ตั้งค่าที่ flutterfire สร้างให้
import 'features/auth/presentation/pages/sign_in_page.dart';
import 'features/main/presentation/pages/main_screen.dart';

// 3. เปลี่ยน main เป็น Future และใส่ async
void main() async {
  // 4. สั่งให้ Flutter เตรียมตัวให้พร้อมก่อนรัน Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // 5. สั่งเชื่อมต่อ Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuizCraft',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SF-Pro',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B6DF9)),
        useMaterial3: true,
      ),
      home: const LoadingPage(), 
    );
  }
}
