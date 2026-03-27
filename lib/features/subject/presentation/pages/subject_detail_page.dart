import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'quiz_page.dart';

class SubjectDetailPage extends StatelessWidget {
  final String subjectId; 
  final String title;

  const SubjectDetailPage({super.key, required this.subjectId, required this.title});

  // ฟังก์ชันสำหรับรีเซ็ตความคืบหน้า (แบบ Hard Reset ล้างยันประวัติ)
  Future<void> _resetProgress(BuildContext context) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Reset Progress", style: TextStyle(fontFamily: 'SF-Pro', fontWeight: FontWeight.bold)),
        content: const Text("Do you want to reset all progress and history for this subject to start over 100%?", style: TextStyle(fontFamily: 'SF-Pro')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontFamily: 'SF-Pro'))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Reset", style: TextStyle(color: Colors.white, fontFamily: 'SF-Pro', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final db = FirebaseFirestore.instance;
    final batch = db.batch(); // ใช้ Batch เพื่อสั่งลบทีเดียวพร้อมกัน

    try {
      // 🌟 1. ตามลบข้อมูลคะแนน (Scores)
      final scoresRef = db.collection('users').doc(user.uid).collection('scores');
      final scoresSnap = await scoresRef.get();
      for (var doc in scoresSnap.docs) {
        if (doc.id.startsWith('${subjectId}_')) { // ลบเฉพาะวิชานี้
          batch.delete(doc.reference);
        }
      }

      // 🌟 2. ตามลบข้อมูลประวัติ (History) ที่ทำให้กราฟใน Analysis ค้าง
      final historyRef = db.collection('users').doc(user.uid).collection('history');
      final historySnap = await historyRef.where('subjectId', isEqualTo: subjectId).get();
      for (var doc in historySnap.docs) {
        batch.delete(doc.reference);
      }

      // สั่งประหาร! (ลบทั้งหมดในรวดเดียว)
      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("This course data has been successfully cleared.", style: TextStyle(fontFamily: 'SF-Pro')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred: $e")),
        );
      }
    }
  }

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
          centerTitle: true, //บังคับให้อยู่ตรงกลางเสมอ
          iconTheme: const IconThemeData(color: Colors.white),
          //ใส่ FittedBox ครอบ Text เพื่อให้มันย่อขนาดตัวเองอัตโนมัติถ้าชื่อวิชายาวไป
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontFamily: 'SF-Pro', fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'Reset Progress',
              onPressed: () => _resetProgress(context), 
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                // Title ใหญ่ 
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

                // Description 
                Text(
                  "Practice platform for $title. Complete all sets to master the subject.",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontFamily: 'SF-Pro',
                  ),
                ),

                const SizedBox(height: 20),

                // Progress Card (เชื่อม Firebase ของจริง)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseAuth.instance.currentUser != null
                      ? FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .collection('scores')
                          .snapshots()
                      : null,
                  builder: (context, snapshot) {
                    int completedSets = 0;
                    int sumBestScores = 0;

                    if (snapshot.hasData) {
                      for (var doc in snapshot.data!.docs) {
                        if (doc.id.startsWith('${subjectId}_')) {
                          completedSets++;
                          var data = doc.data() as Map<String, dynamic>;
                          sumBestScores += (data['bestScore'] ?? 0) as int;
                        }
                      }
                    }

                    double bestScorePercent = 0;
                    if (completedSets > 0) {
                      bestScorePercent = (sumBestScores / (completedSets * 20.0)) * 100;
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Your Progress",
                            style: TextStyle(
                              color: Colors.black54,
                              fontFamily: 'SF-Pro',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Complete $completedSets/4 sets",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'SF-Pro',
                            ),
                          ),
                          Text(
                            "Overall Score : ${bestScorePercent.toStringAsFixed(0)} %",
                            style: const TextStyle(
                              color: Colors.green,
                              fontFamily: 'SF-Pro',
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // ดึงชุดข้อสอบ (Sets) จาก Firebase
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('subjects')
                      .doc(subjectId)
                      .collection('sets')
                      .orderBy('id') 
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(color: Colors.white),
                      ));
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text("An error occurred while loading the exam.", style: TextStyle(color: Colors.white)));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No exam sets available for this subject.", style: TextStyle(color: Colors.white)));
                    }

                    var sets = snapshot.data!.docs;

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
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => QuizPage(
                  subjectId: subjectId, 
                  setId: setId,         
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