import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'sign_in_page.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // เรียกฟังก์ชันตรวจสอบตอนเปิดหน้านี้ขึ้นมา
  }

  Future<void> _checkLoginStatus() async {
    // 1. รอ 3 วินาทีเพื่อให้โชว์หน้า Splash Screen สวยๆ
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return; 

    // 2. สั่งเคลียร์ Session เก่าทิ้งทันที (Refresh ใหม่)
    await FirebaseAuth.instance.signOut();

    // 3. บังคับเด้งไปหน้า SignIn เสมอ! (ไม่ต้องเช็คว่าใครล็อกอินค้างไว้)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignInPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // ปรับพื้นหลังให้เป็น Gradient ไล่สีสวยๆ เข้ากับธีมของแอป
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF003E99),
              Color(0xFF0053CC),
              Color(0xFF227CFF),
            ],
          ),
        ),
        child: Center(
          // ดึงรูป Logo จากโฟลเดอร์ assets มาแสดง
          child: Image.asset(
            'assets/images/logo.png',
            width: 300, // สามารถปรับเพิ่ม/ลดตัวเลขตรงนี้ เพื่อปรับขนาดโลโก้ได้เลยครับ
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}