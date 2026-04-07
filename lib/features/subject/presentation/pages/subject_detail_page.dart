import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'quiz_page.dart';

class SubjectDetailPage extends StatelessWidget {
  final String subjectId; 
  final String title;

  const SubjectDetailPage({super.key, required this.subjectId, required this.title});

  Future<void> _resetProgress(BuildContext context) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Reset Progress", style: TextStyle(fontFamily: 'SF-Pro', fontWeight: FontWeight.bold)),
        content: const Text("Do you want to reset all progress for this subject?", style: TextStyle(fontFamily: 'SF-Pro')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Reset", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final db = FirebaseFirestore.instance;
    final batch = db.batch();

    try {
      // 1. ลบ Scores
      final scoresSnap = await db.collection('users').doc(user.uid).collection('scores').get();
      for (var doc in scoresSnap.docs) {
        if (doc.id.startsWith('${subjectId}_')) batch.delete(doc.reference);
      }

      // 2. ลบ History
      final historySnap = await db.collection('users').doc(user.uid).collection('history')
          .where('subjectId', isEqualTo: subjectId).get();
      
      //หมายเหตุ: หากประวัติเกิน 500 รายการ Batch จะ Error (สำหรับโปรเจกต์นี้ถือว่าอนุโลมได้)
      for (var doc in historySnap.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data cleared successfully"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF003E99), Color(0xFF0053CC), Color(0xFF227CFF)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(title, style: const TextStyle(color: Colors.white, fontFamily: 'SF-Pro', fontWeight: FontWeight.w600)),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => _resetProgress(context)),
          ],
        ),
        body: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            // ดึงข้อมูลวิชาเพื่อเอาจำนวนข้อสอบทั้งหมดมาคำนวณเปอร์เซ็นต์ที่ถูกต้อง
            stream: FirebaseFirestore.instance.collection('subjects').doc(subjectId).collection('sets').snapshots(),
            builder: (context, setsSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseAuth.instance.currentUser != null
                    ? FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).collection('scores').snapshots()
                    : null,
                builder: (context, scoresSnapshot) {
                  int completedSets = 0;
                  int userTotalScore = 0;
                  int possibleTotalScore = 0;

                  if (setsSnapshot.hasData && scoresSnapshot.hasData) {
                    var allSets = setsSnapshot.data!.docs;
                    var userScores = scoresSnapshot.data!.docs;

                    for (var setDoc in allSets) {
                      String setId = setDoc.id;
                      int qCount = setDoc['questionCount'] ?? 0;
                      
                      // หาว่า User ทำชุดนี้หรือยัง
                      var userScoreDoc = userScores.where((doc) => doc.id == '${subjectId}_$setId');
                      if (userScoreDoc.isNotEmpty) {
                        completedSets++;
                        userTotalScore += (userScoreDoc.first['bestScore'] ?? 0) as int;
                      }
                      possibleTotalScore += qCount;
                    }
                  }

                  double progressPercent = possibleTotalScore > 0 ? (userTotalScore / possibleTotalScore) * 100 : 0;

                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'SF-Pro')),
                      const SizedBox(height: 8),
                      Text("Practice platform for $title.", style: const TextStyle(color: Colors.white70, fontFamily: 'SF-Pro')),
                      const SizedBox(height: 25),

                      // Progress Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Your Progress", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Text("Completed: $completedSets Sets", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 4),
                            Text("Accuracy: ${progressPercent.toStringAsFixed(0)}%", style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(value: progressPercent / 100, backgroundColor: Colors.grey[200], color: Colors.green),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Exam Sets
                      if (setsSnapshot.hasData)
                        ...setsSnapshot.data!.docs.map((doc) {
                          var setData = doc.data() as Map<String, dynamic>;
                          return _setItem(context, setData['name'], setData['questionCount'], setData['timeLimitMins'], doc.id);
                        }).toList(),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _setItem(BuildContext context, String title, int qCount, int time, String setId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text("$qCount questions • $time mins", style: const TextStyle(color: Colors.blue)),
            ]),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizPage(subjectId: subjectId, setId: setId))),
            child: const Text("Start", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}