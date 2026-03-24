import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔴 Import Firestore
import 'subject_detail_page.dart';

class SubjectPage extends StatelessWidget {
  const SubjectPage({super.key});

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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Subject',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SF-Pro',
                  ),
                ),

                const SizedBox(height: 24),

                // 🔍 SEARCH (เหมือนเดิม)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      icon: Icon(Icons.search, color: Colors.white),
                      hintText: "Search subject...",
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 🔴 ใช้ StreamBuilder เพื่อดึงข้อมูลจาก Firebase มาแสดงแบบ Real-time
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('subjects').snapshots(),
                    builder: (context, snapshot) {
                      // ถ้ากำลังโหลดข้อมูล
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      }
                      
                      // ถ้าเกิดข้อผิดพลาด
                      if (snapshot.hasError) {
                        return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล', style: TextStyle(color: Colors.white)));
                      }

                      // ถ้าไม่มีข้อมูลเลย
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('ไม่พบรายวิชา', style: TextStyle(color: Colors.white, fontSize: 18)));
                      }

                      // ดึงรายการข้อมูล (Documents) มาใส่ในตัวแปร
                      final subjects = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: subjects.length,
                        itemBuilder: (context, index) {
                          // ดึงข้อมูลแต่ละวิชาออกมา
                          var subjectData = subjects[index].data() as Map<String, dynamic>;
                          String id = subjects[index].id;
                          String code = subjectData['code'] ?? '';
                          String name = subjectData['name'] ?? 'Unknown Subject';
                          String difficulty = subjectData['difficulty'] ?? 'Medium';

                          return _subjectItem(context, id, code, name, difficulty);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔴 ฟังก์ชันเลือก ICON ตามรหัสวิชา (Code)
  IconData _getIcon(String code) {
    switch (code) {
      case "ITDS120": // Programming
        return Icons.computer;
      case "ITDS124": // Math
        return Icons.functions;
      case "ITDS191": // Ethics
        return Icons.balance; // รูปตราชั่งความยุติธรรม
      case "ITDS231": // Network
        return Icons.wifi;
      case "ITDS261": // Software Eng
        return Icons.developer_mode;
      case "ITDS271": // Security
        return Icons.security;
      default:
        return Icons.book;
    }
  }

  // 🔴 ปรับ _subjectItem ให้รับข้อมูลจาก Firebase
  Widget _subjectItem(BuildContext context, String id, String code, String name, String difficulty) {
    
    // ตั้งค่าสีตัวหนังสือระดับความยาก
    Color diffColor;
    if (difficulty == 'Hard') {
      diffColor = Colors.red;
    } else if (difficulty == 'Medium') {
      diffColor = Colors.orange;
    } else {
      diffColor = Colors.green;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        // 🔴 ตอนนี้ส่งแค่ชื่อวิชาไปก่อน (เดี๋ยวเราค่อยไปปรับ SubjectDetailPage ให้รับ ID วิชาด้วย)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubjectDetailPage(
              subjectId: id, //เพิ่มการส่ง id ไปด้วย
              title: name,
            ), 
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // 🔹 ICON
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIcon(code),
                size: 30,
                color: Colors.black,
              ),
            ),

            const SizedBox(width: 16),

            // 🔹 TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16, // ปรับเล็กลงนิดนึง เผื่อชื่อวิชายาว
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2, //  บังคับให้ชื่อวิชาขึ้นบรรทัดใหม่ได้สูงสุด 2 บรรทัด
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    difficulty,
                    style: TextStyle(
                      color: diffColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // BUTTON ขวา
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubjectDetailPage(
                      subjectId: id, //เพิ่มการส่ง id ไปด้วย
                      title: name,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward),
              ),
            ),
          ],
        ),
      ),
    );
  }
}