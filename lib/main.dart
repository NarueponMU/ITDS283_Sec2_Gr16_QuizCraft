import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // สำหรับตั้งค่า Status Bar
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:quizcraft/features/auth/presentation/pages/loading_page.dart';

void main() async {
  // 1. เตรียมความพร้อมของ Widget
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. ตั้งค่า Status Bar ให้เป็นสีขาว (เนื่องจากแอปเราเป็นธีมสีเข้ม)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // ให้โปร่งใสเห็นสี Gradient
      statusBarIconBrightness: Brightness.light, // ไอคอนนาฬิกา/แบต เป็นสีขาว
    ),
  );

  try {
    // 3. เชื่อมต่อ Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // ถ้า Firebase พัง ให้ Log ไว้ดู (หรือจะจัดการ Error UI ที่นี่ก็ได้ครับ)
    debugPrint("🚨 Firebase Init Error: $e");
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuizCraft',
      debugShowCheckedModeBanner: false, // ปิดแถบ Debug สีแดงที่มุมขวา
      theme: ThemeData(
        fontFamily: 'SF-Pro',
        // ตั้งค่าสีพื้นฐานให้สอดคล้องกับแอป
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B6DF9),
          brightness: Brightness.light, 
        ),
        useMaterial3: true,
      ),
      home: const LoadingPage(), 
    );
  }
}