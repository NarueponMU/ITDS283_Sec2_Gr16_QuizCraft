import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 1. Import Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // 2. Import Firestore
import 'edit_profile_page.dart';
import 'logout_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 3. ดึงตัวตนของคนที่ล็อกอินอยู่ ณ ปัจจุบัน
    final currentUser = FirebaseAuth.instance.currentUser;

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // 1. หัวข้อ Profile
                const Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SF-Pro',
                  ),
                ),
                const SizedBox(height: 30),

                // 2. รูปโปรไฟล์พร้อมวงกลมเล็กๆ ด้านล่าง
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4), // เส้นขอบสีขาวบางๆ
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey,
                        backgroundImage: AssetImage('assets/images/Toy.jpg'), // ถ้ารูปไม่ขึ้น อย่าลืมเช็ค Path ใน pubspec.yaml นะครับ
                      ),
                    ),
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const SizedBox(width: 5, height: 5), // จุดวงกลมเล็กๆ
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 4. แทนที่ "Tom Hillson" ด้วย FutureBuilder เพื่อดึงข้อมูลจริง
                if (currentUser != null)
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get(),
                    builder: (context, snapshot) {
                      // ระหว่างรอโหลดข้อมูลจาก Firebase ให้หมุนติ้วๆ สีขาวไปก่อน
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }
                      
                      // ถ้าโหลดพัง หรือหาข้อมูลไม่เจอ ให้แสดงค่า Default
                      if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                        return const Text('User Not Found', style: TextStyle(color: Colors.white));
                      }

                      // ถอดรหัสข้อมูลที่ได้มาจาก Firestore
                      var userData = snapshot.data!.data() as Map<String, dynamic>;
                      String fullName = userData['fullName'] ?? 'Unknown User';
                      String email = userData['email'] ?? currentUser.email ?? 'No Email';
                      String studentId = userData['studentId'] ?? '';

                      return Column(
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'SF-Pro',
                            ),
                          ),
                          Text(
                            email,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontFamily: 'SF-Pro',
                            ),
                          ),
                          if (studentId.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'ID: $studentId',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                                fontFamily: 'SF-Pro',
                              ),
                            ),
                          ]
                        ],
                      );
                    },
                  )
                else
                  const Text('Guest', style: TextStyle(color: Colors.white, fontSize: 28)), // กรณีไม่ได้ล็อกอิน

                const SizedBox(height: 50),

                // 4. รายการเมนู
                _buildProfileMenu(
                  icon: Icons.settings_outlined,
                  title: 'Edit Profile',
                  showArrow: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfilePage()),
                    );
                  },
                ),
                const SizedBox(height: 30),

                _buildAccountSecurity(), // เมนูพิเศษที่มี Progress Bar
                
                const SizedBox(height: 30),

                _buildProfileMenu(
                  icon: Icons.logout,
                  title: 'Logout',
                  showArrow: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LogoutPage()),
                    );
                  },
                ),
                
                const SizedBox(height: 100), // เผื่อที่ให้ Bottom Nav
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget สำหรับเมนูทั่วไป
  Widget _buildProfileMenu({
    required IconData icon,
    required String title,
    required bool showArrow,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF-Pro',
              ),
            ),
          ),
          if (showArrow)
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18),
        ],
      ),
    );
  }

  // Widget สำหรับเมนู Account Security ที่มี Progress Bar
  Widget _buildAccountSecurity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.white, size: 32),
            const SizedBox(width: 20),
            const Text(
              'Account Security',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF-Pro',
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.only(left: 52), // ให้ตรงกับตัวอักษรด้านบน
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const LinearProgressIndicator(
                  value: 0.8, // 80%
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Excellent',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontFamily: 'SF-Pro',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}