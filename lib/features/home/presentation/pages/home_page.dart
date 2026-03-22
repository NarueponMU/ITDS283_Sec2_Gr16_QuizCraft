import 'package:flutter/material.dart';
import 'ebook_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ลบ import 'package:quizcraft/features/subject/presentation/pages/subject_page.dart'; ออกได้เลยเพราะเราไม่ได้ใช้กดไปตรงๆ แล้วครับ

class HomePage extends StatelessWidget {
  // 1. เพิ่มตัวรับคำสั่งสลับหน้าจาก MainScreen
  final VoidCallback? onStartQuiz;

  const HomePage({super.key, this.onStartQuiz});

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
              Color(0xFF003E99), // สีเข้มสุดด้านบน
              Color(0xFF0053CC),
              Color(0xFF227CFF), // สีสว่างสุดด้านล่าง
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Home',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SF-Pro',
                      ),
                    ),
                    
                    // โค้ดดึงรูปโปรไฟล์มาแสดงที่หน้า Home
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseAuth.instance.currentUser != null 
                          ? FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots()
                          : null,
                      builder: (context, snapshot) {
                        String? photoUrl;
                        if (snapshot.hasData && snapshot.data!.exists) {
                          var userData = snapshot.data!.data() as Map<String, dynamic>;
                          photoUrl = userData['photoUrl']; // ดึงลิงก์รูป
                        }

                        return CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey[800],
                          // ถ้ามีรูปโชว์รูป ถ้าไม่มีโชว์ไอคอนสีขาว
                          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                          child: photoUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
                        );
                      },
                    ),
                    
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Info Card (ชื่อแอปและ SDG)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFF2F5F8,
                    ), // สีขาวอมเทานิดๆ ให้เหมือนดีไซน์
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QuizCraft (DST Practice Platform)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'SF-Pro',
                        ),
                      ),
                      SizedBox(height: 15),
                      Text(
                        'SDG 4: Quality Education',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SF-Pro',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 3. Start Quiz Button
                GestureDetector(
                  // 2. เปลี่ยนมาใช้คำสั่งที่รับมาจาก MainScreen เพื่อสั่งสลับแท็บ
                  onTap: onStartQuiz,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F5F8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        // ไอคอนจับเวลา
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF1B6DF9),
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.timer_outlined,
                            size: 40,
                            color: Color(0xFF1B6DF9),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // เส้นคั่นแนวตั้ง
                        Container(
                          height: 70,
                          width: 2,
                          color: const Color(0xFF1B6DF9),
                        ),
                        const SizedBox(width: 20),
                        // ข้อความ
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start Quiz',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B6DF9),
                                fontFamily: 'SF-Pro',
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'เริ่มทำแบบทดสอบ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'SF-Pro',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Your Progress Section
                const Text(
                  'Your Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SF-Pro',
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F5F8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _buildGradientProgressRow('Subject', 0.60, const [
                        Color(0xFFF96D52),
                        Color(0xFFF4C873),
                      ]),
                      _buildGradientProgressRow('Subject', 0.45, const [
                        Color(0xFF8F70FF),
                        Color(0xFF56E0E0),
                      ]),
                      _buildGradientProgressRow('Subject', 0.70, const [
                        Color(0xFF1ED6B4),
                        Color(0xFF1CB5E0),
                      ]),
                      _buildGradientProgressRow('Subject', 0.50, const [
                        Color(0xFF7F00FF),
                        Color(0xFFE100FF),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Course / E-Book Section
                const Text(
                  'Course',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SF-Pro',
                  ),
                ),
                const SizedBox(height: 16),

                GestureDetector(
                  onTap: () {
                    // นำทางไปหน้า E-Book
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EbookPage(),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F5F8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.menu_book, size: 50, color: Colors.black87),
                        SizedBox(height: 12),
                        Text(
                          'E-Book',
                          style: TextStyle(
                            color: Color(0xFF1B6DF9),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20), // เผื่อที่ว่างด้านล่างกันติดขอบจอ
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Custom Widget สำหรับสร้างหลอด Progress Bar แบบไล่สี (Gradient)
  Widget _buildGradientProgressRow(
    String subject,
    double progress,
    List<Color> gradientColors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B6DF9),
                    fontFamily: 'SF-Pro',
                  ),
                ),
                const SizedBox(height: 8),
                // ใช้ LayoutBuilder เพื่อให้รู้ขนาดความกว้างของหน้าจอ
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      height: 10,
                      width: constraints.maxWidth, // กว้างเต็มพื้นที่
                      decoration: BoxDecoration(
                        color: Colors.grey[400], // สีพื้นหลังหลอด (สีเทา)
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width:
                              constraints.maxWidth *
                              progress, // คำนวณความกว้างตามเปอร์เซ็นต์
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradientColors,
                            ), // ใส่ไล่สี
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'SF-Pro',
            ),
          ),
        ],
      ),
    );
  }
}