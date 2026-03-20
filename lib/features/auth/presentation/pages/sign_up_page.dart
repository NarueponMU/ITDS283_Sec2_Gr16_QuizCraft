import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 1. เปลี่ยนเป็น StatefulWidget
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // 2. สร้าง Controller เพื่อรับค่าจากช่องกรอกข้อมูลแต่ละช่อง
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false; // ตัวแปรสำหรับเช็คว่ากำลังโหลดอยู่ไหม

  // 3. ฟังก์ชันสำหรับสมัครสมาชิก
  Future<void> _registerAccount() async {
    // เช็คว่ากรอกข้อมูลช่องสำคัญครบไหม
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out the information completely.',
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
      // 3.1 สร้างบัญชีใน Firebase Auth (ใช้ Email + Password)
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 3.2 เอาข้อมูลที่เหลือไปเก็บใน Cloud Firestore (ฐานข้อมูล)
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'studentId': _studentIdController.text.trim(),
        'phone': _phoneController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(), // เก็บเวลาที่สมัคร
      });

      // ถ้าสมัครสำเร็จ ให้แสดงข้อความและเด้งกลับไปหน้า Login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!',
          style: TextStyle(
          fontFamily: 'SF-Pro',
          fontSize: 16,
          fontWeight: FontWeight.bold
          ),), 
          backgroundColor: Colors.green),
        );
        Navigator.pop(context); 
      }

    } on FirebaseAuthException catch (e) {
      // ดักจับ Error จาก Firebase และแปลเป็นภาษาไทย
      String message = 'An error occurred. Please try again.';
      if (e.code == 'weak-password') {
        message = 'The password must be at least 6 characters long.';
      } else if (e.code == 'email-already-in-use') {
        message = 'This email address has already been used.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      // ทำเสร็จแล้ว ไม่ว่าจะพังหรือสำเร็จ ก็ให้หยุดโหลด
      if (mounted) {
        setState(() {
          _isLoading = false; 
        });
      }
    }
  }

  @override
  void dispose() {
    // ทำลาย Controller ทิ้งเมื่อปิดหน้าจอเพื่อคืนหน่วยความจำ
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor = const Color.fromRGBO(0, 0, 138, 80);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Create account',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro'),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? ", style: TextStyle(color: Colors.white70, fontFamily: 'SF-Pro')),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); 
                    },
                    child: const Text('Login', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              
              // กล่องกรอกข้อมูลสีขาว
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController, // ผูก Controller
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline), hintText: 'Tom Hillson', border: InputBorder.none),
                    ),
                    const Divider(),
                    TextField(
                      controller: _emailController, // ผูก Controller
                      keyboardType: TextInputType.emailAddress, // ปรับคีย์บอร์ดให้พิมพ์อีเมลสะดวกขึ้น
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined), hintText: 'tomhillson@gmail.com', border: InputBorder.none),
                    ),
                    const Divider(),
                    TextField(
                      controller: _studentIdController, // ผูก Controller
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.badge_outlined), hintText: 'Student ID', border: InputBorder.none),
                    ),
                    const Divider(),
                    TextField(
                      controller: _phoneController, // ผูก Controller
                      keyboardType: TextInputType.phone, // ปรับคีย์บอร์ดเป็นตัวเลข
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.phone), hintText: '081-XXX-XXXX', border: InputBorder.none),
                    ),
                    const Divider(),
                    TextField(
                      controller: _passwordController, // ผูก Controller
                      obscureText: true,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_outline), hintText: 'Password', border: InputBorder.none),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // ปุ่ม Register
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // ถ้ากำลังโหลดอยู่ ให้ปุ่มกดไม่ได้ (null) ป้องกันคนกดเบิ้ล
                  onPressed: _isLoading ? null : _registerAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading 
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Register', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}