import 'package:flutter/material.dart';
import 'ebook_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onStartQuiz;
  const HomePage({super.key, this.onStartQuiz});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 1. สร้างตัวแปรเก็บ Future ไว้เพื่อไม่ให้โหลดซ้ำซ้อน
  late Future<List<Map<String, dynamic>>> _progressFuture;

  @override
  void initState() {
    super.initState();
    // 2. โหลดข้อมูลแค่ครั้งเดียวตอนเปิดหน้า
    _progressFuture = _calculateProgress();
  }

  Future<List<Map<String, dynamic>>> _calculateProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    // ดึงข้อมูลวิชาและคะแนน
    final subjectsSnap = await FirebaseFirestore.instance.collection('subjects').get();
    final scoresSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('scores')
        .get();

    Map<String, int> completedSetsCount = {};
    for (var doc in scoresSnap.docs) {
      String subjectId = doc.id.split('_')[0];
      completedSetsCount[subjectId] = (completedSetsCount[subjectId] ?? 0) + 1;
    }

    List<Map<String, dynamic>> progressData = [];
    List<List<Color>> colors = [
      [const Color(0xFFF96D52), const Color(0xFFF4C873)],
      [const Color(0xFF8F70FF), const Color(0xFF56E0E0)],
      [const Color(0xFF1ED6B4), const Color(0xFF1CB5E0)],
      [const Color(0xFF7F00FF), const Color(0xFFE100FF)],
      [const Color(0xFFFF5E62), const Color(0xFFFF9966)], 
      [const Color(0xFF00C9FF), const Color(0xFF92FE9D)],
    ];

    int colorIndex = 0;
    for (var subj in subjectsSnap.docs) {
      String subjId = subj.id;
      String subjCode = subj['code'];
      String subjName = subj['name'] ?? '';

      int completed = completedSetsCount[subjId] ?? 0;
      double progress = completed / 4.0; 
      if (progress > 1.0) progress = 1.0; 

      progressData.add({
        'code': subjCode,
        'name': subjName,
        'progress': progress,
        'colors': colors[colorIndex % colors.length]
      });
      colorIndex++;
    }
    return progressData;
  }

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
            colors: [Color(0xFF003E99), Color(0xFF0053CC), Color(0xFF227CFF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Home', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')),
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseAuth.instance.currentUser != null 
                          ? FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots()
                          : null,
                      builder: (context, snapshot) {
                        String? photoUrl;
                        if (snapshot.hasData && snapshot.data!.exists) {
                          var userData = snapshot.data!.data() as Map<String, dynamic>;
                          photoUrl = userData['photoUrl']; 
                        }
                        return CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                          child: photoUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // SDG 4 Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: const Color(0xFFF2F5F8), borderRadius: BorderRadius.circular(20)),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('QuizCraft (DST Practice Platform)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'SF-Pro')),
                      SizedBox(height: 15),
                      Text('SDG 4: Quality Education', style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600, fontFamily: 'SF-Pro')),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Start Quiz Button
                GestureDetector(
                  onTap: widget.onStartQuiz,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(color: const Color(0xFFF2F5F8), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF1B6DF9), width: 3)),
                          child: const Icon(Icons.timer_outlined, size: 40, color: Color(0xFF1B6DF9)),
                        ),
                        const SizedBox(width: 20),
                        Container(height: 70, width: 2, color: const Color(0xFF1B6DF9)),
                        const SizedBox(width: 20),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Start Quiz', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1B6DF9), fontFamily: 'SF-Pro')),
                            SizedBox(height: 4),
                            Text('เริ่มทำแบบทดสอบ', style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600, fontFamily: 'SF-Pro')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text('Your Progress', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')),
                const SizedBox(height: 16),
                
                // Progress Section
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _progressFuture, // ใช้ตัวแปร Future ที่โหลดไว้แล้ว
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        height: 200,
                        decoration: BoxDecoration(color: const Color(0xFFF2F5F8), borderRadius: BorderRadius.circular(20)),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: const Color(0xFFF2F5F8), borderRadius: BorderRadius.circular(20)),
                        child: const Center(child: Text("ยังไม่มีข้อมูล", style: TextStyle(fontFamily: 'SF-Pro'))),
                      );
                    }

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: const Color(0xFFF2F5F8), borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        children: snapshot.data!.map((data) {
                          return _buildGradientProgressRow(
                            data['code'],
                            data['name'], 
                            data['progress'],
                            data['colors'],
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // E-Book Button
                const Text('Course', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EbookPage())),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(color: const Color(0xFFF2F5F8), borderRadius: BorderRadius.circular(20)),
                    child: const Column(
                      children: [
                        Icon(Icons.menu_book, size: 50, color: Colors.black87),
                        SizedBox(height: 12),
                        Text('E-Book', style: TextStyle(color: Color(0xFF1B6DF9), fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20), 
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientProgressRow(String code, String name, double progress, List<Color> gradientColors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(code, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B6DF9), fontFamily: 'SF-Pro')),
          const SizedBox(height: 2),
          Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54, fontFamily: 'SF-Pro'), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      height: 10,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer( // เพิ่ม Animation นิดๆ ให้หลอดขยับสวยๆ
                          duration: const Duration(milliseconds: 500),
                          width: constraints.maxWidth * progress, 
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: gradientColors), 
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87, fontFamily: 'SF-Pro')),
            ],
          ),
        ],
      ),
    );
  }
}