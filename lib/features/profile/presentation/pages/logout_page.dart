import 'package:flutter/material.dart';
//สำคัญ: Path ของหน้า SignInPage 
import 'package:quizcraft/features/auth/presentation/pages/sign_in_page.dart'; 
import 'package:firebase_auth/firebase_auth.dart';

class LogoutPage extends StatelessWidget {
  const LogoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // ให้ทะลุเห็นพื้นหลัง
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // กระจายบน-กลาง-ล่าง ให้สมดุล
              children: [
                // 1. ส่วนหัวข้อ
                const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SF-Pro',
                  ),
                ),

                // 2. ส่วนตรงกลาง (ลูกศร + ข้อความยืนยัน)
                const Column(
                  children: [
                    Icon(
                      Icons.arrow_forward,
                      size: 160,
                      color: Color(0xFFFF1100), // สีแดง
                    ),
                    SizedBox(height: 30),
                    Text(
                      'Log out confirmation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SF-Pro',
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Are you sure you wanna log out?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'SF-Pro',
                      ),
                    ),
                  ],
                ),

                // 3. ส่วนปุ่มกดด้านล่าง (Leave & Cancel)
                Row(
                  children: [
                    // 🔴 ปุ่ม LEAVE (สีแดง)
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          // 1. สั่งเตะผู้ใช้ออกจากระบบ Firebase 
                          await FirebaseAuth.instance.signOut();
                          
                          // 2. เด้งกลับไปหน้า SignIn และล้างประวัติหน้าจอทั้งหมด
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const SignInPage()),
                              (Route<dynamic> route) => false,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B30), // สีแดง
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'LEAVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                fontFamily: 'SF-Pro',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // 🔴 ปุ่ม CANCEL (สีน้ำเงินเข้ม)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // แค่กดปิดหน้านี้ (Pop) กลับไปหน้า Profile ก็พอครับ
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF003380), // สีน้ำเงินเข้ม
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'CANCEL',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
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