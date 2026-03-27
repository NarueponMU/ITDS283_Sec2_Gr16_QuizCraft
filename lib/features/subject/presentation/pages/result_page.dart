import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'quiz_page.dart';

class ResultPage extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final String subjectId;
  final String setId;
  final int timeSpent; // 🌟 รับเวลาที่ใช้ทำข้อสอบมาจากหน้า Quiz

  const ResultPage({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.subjectId,
    required this.setId,
    required this.timeSpent, // 🌟 เพิ่มมารับค่า
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

  // แปลงวินาทีเป็น MM:SS สำหรับแสดงผล
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    String minsStr = minutes.toString().padLeft(2, '0');
    String secsStr = remainingSeconds.toString().padLeft(2, '0');
    return "$minsStr:$secsStr";
  }

  Future<void> _saveAndFetchBestScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 🌟 1. บันทึกประวัติการทำข้อสอบ (เพิ่มเวลาที่ใช้เข้าไปด้วย!)
      final historyRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('history') 
          .doc(); 

      await historyRef.set({
        'subjectId': widget.subjectId,
        'setId': widget.setId,
        'score': widget.score,
        'totalQuestions': widget.totalQuestions,
        'timeSpent': widget.timeSpent, // 🔴 บันทึกวินาทีที่ใช้ ลง Firebase
        'timestamp': FieldValue.serverTimestamp(), 
      });

      // 🌟 2. อัปเดต Best Score ของชุดข้อสอบนี้
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scores')
          .doc('${widget.subjectId}_${widget.setId}');

      final docSnap = await docRef.get();
      int currentBest = 0;

      if (docSnap.exists) {
        currentBest = docSnap.data()?['bestScore'] ?? 0;
      }

      if (widget.score > currentBest) {
        currentBest = widget.score;
        await docRef.set({
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
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text("Quiz Complete", style: TextStyle(color: Colors.white, fontFamily: 'SF-Pro')),
        ),
        body: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Icon(
                        isPassed ? Icons.star : Icons.sentiment_dissatisfied,
                        size: 80,
                        color: isPassed ? Colors.amberAccent : Colors.redAccent,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        isPassed ? "Congratulations!" : "Keep Trying!",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'SF-Pro'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isPassed 
                            ? "You have successfully completed the quiz."
                            : "Don't give up! Review the course and try again.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'SF-Pro'),
                      ),
                      const SizedBox(height: 24),

                      // SCORE CARD
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Score: ${widget.score} / ${widget.totalQuestions}",
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro'),
                            ),
                            const SizedBox(height: 12),
                            
                            _RowItem("Correct Answers", "${widget.score}"),
                            _RowItem("Incorrect Answers", "${widget.totalQuestions - widget.score}"),
                            
                            // 🌟 แสดงเวลาที่ใช้จริง
                            _RowItem("Time Used", _formatTime(widget.timeSpent)), 
                            
                            _RowItem("Best Score", "$bestScore/${widget.totalQuestions}"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A2A66),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => QuizPage(
                                subjectId: widget.subjectId,
                                setId: widget.setId,
                              )),
                            );
                          },
                          child: const Text("Retry Quiz", style: TextStyle(fontSize: 17, fontFamily: 'SF-Pro')),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A2A66),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("Back to Course", style: TextStyle(fontSize: 17, fontFamily: 'SF-Pro')),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String title;
  final String value;

  const _RowItem(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.black54, fontSize: 15, fontFamily: 'SF-Pro')),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'SF-Pro')),
        ],
      ),
    );
  }
}