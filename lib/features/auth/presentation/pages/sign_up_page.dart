import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false; 
  bool _isObscure = true; // 🌟 สำหรับซ่อน/แสดงรหัสผ่าน

  Future<void> _registerAccount() async {
    // 🔴 ปรับให้เช็คข้อมูลครบทุกช่อง
    if (_emailController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _nameController.text.isEmpty ||
        _studentIdController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields completely.',
        style: TextStyle(fontFamily: 'SF-Pro', fontSize: 16, fontWeight: FontWeight.bold))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // เก็บข้อมูลลง Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'studentId': _studentIdController.text.trim(),
        'phone': _phoneController.text.trim(),
        'photoUrl': null, // เผื่อไว้ใช้สำหรับระบบโปรไฟล์ในอนาคต
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!', 
          style: TextStyle(fontFamily: 'SF-Pro', fontWeight: FontWeight.bold)), 
          backgroundColor: Colors.green),
        );
        Navigator.pop(context); 
      }

    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred. Please try again.';
      if (e.code == 'weak-password') {
        message = 'The password must be at least 6 characters long.';
      } else if (e.code == 'email-already-in-use') {
        message = 'This email address is already in use.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔴 แก้ไขค่าสี Background ให้ถูกต้อง
    const Color bgColor = Color(0xFF003E99);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
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
                      onTap: () => Navigator.pop(context),
                      child: const Text('Login', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildTextField(_nameController, Icons.person_outline, 'Full Name', false),
                      const Divider(),
                      _buildTextField(_emailController, Icons.email_outlined, 'Email', false, inputType: TextInputType.emailAddress),
                      const Divider(),
                      _buildTextField(_studentIdController, Icons.badge_outlined, 'Student ID', false),
                      const Divider(),
                      _buildTextField(_phoneController, Icons.phone, 'Phone Number', false, inputType: TextInputType.phone),
                      const Divider(),
                      // ช่องรหัสผ่านพร้อมปุ่มเปิด/ปิดตา
                      TextField(
                        controller: _passwordController,
                        obscureText: _isObscure,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          hintText: 'Password',
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                            onPressed: () => setState(() => _isObscure = !_isObscure),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registerAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Register', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper สำหรับสร้างช่องกรอกข้อมูล
  Widget _buildTextField(TextEditingController controller, IconData icon, String hint, bool isPassword, {TextInputType inputType = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: inputType,
      textInputAction: TextInputAction.next, // 🌟 เพิ่มปุ่ม Next บนคีย์บอร์ด
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hint,
        border: InputBorder.none,
      ),
    );
  }
}