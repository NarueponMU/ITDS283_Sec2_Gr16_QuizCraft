import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'quiz_page.dart';

class ResultPage extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final String subjectId;
  final String setId;
  final int timeSpent; 

  const ResultPage({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.subjectId,
    required this.setId,
    required this.timeSpent, 
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  int bestScore = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _saveAndFetchBestScore();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  Future<void> _saveAndFetchBestScore() async {
    final user = FirebaseAuth.instance.currentUser;
    
    // ถ้าไม่มี User ต้องปิด Loading ด้วย ไม่ครั้นจะค้าง
    if (user == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final userDoc = firestore.collection('users').doc(user.uid);

      // 1. บันทึก History (ใช้ Batch หรือ Write แยกก็ได้)
      await userDoc.collection('history').add({
        'subjectId': widget.subjectId,
        'setId': widget.setId,
        'score': widget.score,
        'totalQuestions': widget.totalQuestions,
        'timeSpent': widget.timeSpent,
        'timestamp': FieldValue.serverTimestamp(), 
      });

      // 2. จัดการ Best Score
      final scoreDocRef = userDoc.collection('scores').doc('${widget.subjectId}_${widget.setId}');
      final docSnap = await scoreDocRef.get();
      
      int currentBest = 0;
      if (docSnap.exists) {
        currentBest = docSnap.data()?['bestScore'] ?? 0;
      }

      // ถ้าได้คะแนนใหม่ดีกว่าเดิม ให้อัปเดต
      if (widget.score > currentBest) {
        currentBest = widget.score;
        await scoreDocRef.set({
          'bestScore': currentBest,
          'lastUpdated': FieldValue.serverTimestamp()
        }, SetOptions(merge: true));
      }

      if (mounted) {
        setState(() {
          bestScore = currentBest;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error saving result: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // คำนวณเปอร์เซ็นต์: (score / total) * 100
    double percentage = widget.totalQuestions == 0 ? 0 : (widget.score / widget.totalQuestions) * 100;
    bool isPassed = percentage >= 50;

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
          automaticallyImplyLeading: false, // ปิดปุ่ม Back อัตโนมัติ เพื่อบังคับให้ใช้ปุ่มเรา
          title: const Text("Quiz Complete", style: TextStyle(color: Colors.white, fontFamily: 'SF-Pro', fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView( // ป้องกันจอเล็กแล้วล้น (Overflow)
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // ไอคอนแสดงสถานะ
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPassed ? Icons.emoji_events : Icons.sentiment_very_dissatisfied,
                          size: 100,
                          color: isPassed ? Colors.amber : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      Text(
                        isPassed ? "Great Job!" : "Keep it up!",
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'SF-Pro'),
                      ),
                      const SizedBox(height: 30),

                      // SCORE CARD
                      Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
                        ),
                        child: Column(
                          children: [
                            Text(
                              "${(percentage).toInt()}%",
                              style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: isPassed ? Colors.green : Colors.redAccent, fontFamily: 'SF-Pro'),
                            ),
                            const Divider(height: 40),
                            _RowItem("Your Score", "${widget.score} / ${widget.totalQuestions}"),
                            _RowItem("Time Spent", _formatTime(widget.timeSpent)),
                            _RowItem("Best Score", "$bestScore / ${widget.totalQuestions}"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // ปุ่มกด
                      _buildButton(
                        label: "Retry Quiz",
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => QuizPage(subjectId: widget.subjectId, setId: widget.setId)),
                          );
                        },
                        color: const Color(0xFFFFB03A),
                        textColor: Colors.black,
                      ),
                      const SizedBox(height: 16),
                      _buildButton(
                        label: "Back to Home",
                        onPressed: () => Navigator.pop(context),
                        color: Colors.white.withOpacity(0.2),
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildButton({required String label, required VoidCallback onPressed, required Color color, required Color textColor}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')),
      ),
    );
  }

  Widget _RowItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.black54, fontSize: 16, fontFamily: 'SF-Pro', fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'SF-Pro', color: Colors.black)),
        ],
      ),
    );
  }
}