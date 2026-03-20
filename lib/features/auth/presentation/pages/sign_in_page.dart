import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth เข้ามา
import 'sign_up_page.dart';
import '../../../main/presentation/pages/main_screen.dart'; // เช็ค Path ตรงนี้ให้ตรงกับของคุณด้วยนะครับ

// 1. เปลี่ยนจาก StatelessWidget เป็น StatefulWidget เพื่อให้ปุ่มมีสถานะโหลดหมุนๆ ได้
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  // 2. สร้าง Controller เพื่อรับค่าจากช่องกรอก
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false; // ตัวแปรสำหรับเช็คว่ากำลังโหลดคุยกับ Firebase อยู่ไหม

  // 3. ฟังก์ชันสำหรับเข้าสู่ระบบ
  Future<void> _loginAccount() async {
    // ป้องกันคนกดปุ่มรัวๆ โดยที่ยังไม่ได้พิมพ์อะไร
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address and password completely.',
        style: TextStyle(
          fontFamily: 'SF-Pro',
          fontSize: 16,
          fontWeight: FontWeight.bold
          ),)),
      );
      return;
    }

    setState(() {
      _isLoading = true; // เริ่มแสดงตัวโหลด
    });

    try {
      // 3.1 ส่งอีเมลและรหัสผ่านไปเช็คกับ Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 3.2 ถ้ารหัสผ่านถูก จะรันมาถึงบรรทัดนี้ ให้เด้งไปหน้า MainScreen ทันที
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }

    } on FirebaseAuthException catch (e) {
      // ดักจับ Error กรณีอีเมลผิดหรือรหัสผิด แล้วบอกผู้ใช้เป็นภาษาไทย
      String message = 'An error occurred. Please try again.';
      // ข้อสังเกต: Firebase รุ่นใหม่ๆ มักจะรวม Error อีเมลผิด/รหัสผิด เป็น 'invalid-credential' เพื่อความปลอดภัยจากการเดารหัส
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'The email address or password is incorrect.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      // ไม่ว่าจะสำเร็จหรือพัง ก็ต้องสั่งให้หยุดหมุนโหลด
      if (mounted) {
        setState(() {
          _isLoading = false; 
        });
      }
    }
  }

  @override
  void dispose() {
    // ทำลายทิ้งเพื่อคืนหน่วยความจำเมื่อปิดหน้าจอ
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor = const Color.fromRGBO(0, 0, 138, 80);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Sign in to your\nAccount',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SF-Pro'
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.white70, fontFamily: 'SF-Pro'),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SF-Pro'
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // ช่องกรอกข้อมูล
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController, // ผูก Controller รับอีเมล
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: 'Email',
                        border: InputBorder.none,
                      ),
                    ),
                    const Divider(),
                    TextField(
                      controller: _passwordController, // ผูก Controller รับรหัสผ่าน
                      obscureText: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.lock_outline),
                        hintText: 'Password',
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // ถ้ากำลังโหลดอยู่ ให้ล็อกปุ่มไว้ (null)
                  onPressed: _isLoading ? null : _loginAccount, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  // ถ้าโหลดอยู่ ให้โชว์ไอคอนหมุนๆ แทนข้อความ Log in
                  child: _isLoading 
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Log in',
                          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro'),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}