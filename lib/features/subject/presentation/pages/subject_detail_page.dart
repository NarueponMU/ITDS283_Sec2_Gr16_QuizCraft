import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔴 Import Firestore
import 'quiz_page.dart';

class SubjectDetailPage extends StatelessWidget {
  final String subjectId; // 🔴 เพิ่มตัวรับ ID ของวิชา
  final String title;

  const SubjectDetailPage({super.key, required this.subjectId, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontFamily: 'SF-Pro'),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                // Title ใหญ่ (ใช้ชื่อวิชาที่รับมา)
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'SF-Pro',
                  ),
                ),

                const SizedBox(height: 8),

                // Description (ปรับให้เป็นข้อความกว้างๆ ที่ใช้ได้ทุกวิชา)
                Text(
                  "Practice platform for $title. Complete all sets to master the subject.",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontFamily: 'SF-Pro',
                  ),
                ),

                const SizedBox(height: 20),

                // Progress Card (จำลองไว้ก่อน เดี๋ยวเราค่อยมาทำระบบคำนวณของจริงทีหลัง)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your Progress",
                        style: TextStyle(
                          color: Colors.black54,
                          fontFamily: 'SF-Pro',
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Complete 0/4 sets",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SF-Pro',
                        ),
                      ),
                      Text(
                        "Best Score : 0 %",
                        style: TextStyle(
                          color: Colors.green,
                          fontFamily: 'SF-Pro',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 🔴 ดึงชุดข้อสอบ (Sets) จาก Firebase
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('subjects')
                      .doc(subjectId)
                      .collection('sets')
                      .orderBy('id') // เรียงลำดับจาก set1, set2...
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(color: Colors.white),
                      ));
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text("เกิดข้อผิดพลาดในการโหลดข้อสอบ", style: TextStyle(color: Colors.white)));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("ยังไม่มีชุดข้อสอบสำหรับวิชานี้", style: TextStyle(color: Colors.white)));
                    }

                    // ดึงข้อมูล Sets ออกมาเป็น List
                    var sets = snapshot.data!.docs;

                    // ใช้ ListView.builder ซ้อนใน ListView ต้องใส่ shrinkWrap และ NeverScrollableScrollPhysics
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sets.length,
                      itemBuilder: (context, index) {
                        var setData = sets[index].data() as Map<String, dynamic>;
                        String setName = setData['name'] ?? 'Unknown Set';
                        int qCount = setData['questionCount'] ?? 0;
                        int timeLimit = setData['timeLimitMins'] ?? 0;
                        String setId = sets[index].id;

                        // โยนข้อมูลให้ Widget สร้างกล่อง
                        return _setItem(context, setName, qCount, timeLimit, setId);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔴 ปรับ _setItem ให้รับจำนวนข้อและเวลามาโชว์ด้วย
  Widget _setItem(BuildContext context, String title, int qCount, int time, String setId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'SF-Pro',
                  ),
                ),
                const SizedBox(height: 6),

                // จำนวนข้อ + เวลา
                Text(
                  "$qCount questions • $time mins",
                  style: const TextStyle(
                    color: Colors.blue,
                    fontFamily: 'SF-Pro',
                  ),
                ),
              ],
            ),
          ),

          // 🔹 BUTTON
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              // TODO: เดี๋ยวเราจะส่ง subjectId และ setId ไปให้หน้า QuizPage ต่อไป
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => QuizPage(
                  subjectId: subjectId, // ส่ง ID วิชาไป
                  setId: setId,         // ส่ง ID ชุดข้อสอบไป
                )),
              );
            },
            child: const Text("Start", style: TextStyle(fontFamily: 'SF-Pro')),
          ),
        ],
      ),
    );
  }
}