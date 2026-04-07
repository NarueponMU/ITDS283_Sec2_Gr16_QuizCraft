import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quizcraft/features/auth/presentation/pages/sign_in_page.dart'; 

class LogoutPage extends StatelessWidget {
  const LogoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
                const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SF-Pro',
                  ),
                ),

                Column(
                  children: [
                    // เปลี่ยนไอคอนให้สื่อความหมายถึงการออกจากระบบมากขึ้น
                    const Icon(
                      Icons.logout_rounded, 
                      size: 140,
                      color: Color(0xFFFF5252), 
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Log out confirmation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SF-Pro',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Are you sure you want to log out?',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontFamily: 'SF-Pro',
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    // ปุ่ม LEAVE
                    Expanded(
                      child: InkWell( // เปลี่ยนเป็น InkWell เพื่อให้มีเอฟเฟกต์ตอนกด
                        onTap: () async {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const SignInPage()),
                              (Route<dynamic> route) => false,
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B30),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'LEAVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                fontFamily: 'SF-Pro',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // ปุ่ม CANCEL
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15), // ปรับสีให้ดูเป็นปุ่มรอง (Secondary)
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Center(
                            child: Text(
                              'CANCEL',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                fontFamily: 'SF-Pro',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}