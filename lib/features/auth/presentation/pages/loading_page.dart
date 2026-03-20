import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 1. Import Firebase Auth
import 'sign_in_page.dart';
import '../../../main/presentation/pages/main_screen.dart'; // 2. Import หน้า MainScreen

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

  // ฟังก์ชันหน่วงเวลา 2 วินาที แล้วเช็คสถานะล็อกอิน
  Future<void> _checkLoginStatus() async {
    // 1. รอ 2 วินาทีเพื่อให้โชว์หน้า Splash Screen สวยๆ
    await Future.delayed(const Duration(seconds: 2));

    // ป้องกัน Error กรณีที่หน้าจอถูกปิดไปก่อนที่เวลาจะครบ
    if (!mounted) return; 

    // 2. เช็คว่ามีใครล็อกอินค้างไว้ไหม
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // ถ้ามีคนล็อกอินอยู่ ไปหน้า MainScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      // ถ้าไม่มีคนล็อกอิน ไปหน้า SignInPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignInPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.blueAccent, // สีพื้นหลังอ้างอิงจาก Prototype
      body: Center(
        child: Text(
          'Quiz Craft',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}